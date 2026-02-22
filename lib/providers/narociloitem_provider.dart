import 'package:BiroPOS/models/narociloitem.dart';
import 'package:BiroPOS/providers/davcna_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class NarociloNotifier extends Notifier<List<NarociloItem>> {
  @override
  List<NarociloItem> build() {
    return [];
  }

  void setNarocila(List<NarociloItem> items) {
    state = items;
  }

  void addToRacun(NarociloItem narociloItem,
      {bool fromTable = false, bool nastaviCeno = false}) async {
    final String? davcnaSt = ref.read(taxNumberProvider);
    int existingItemIndex = -1;
    final narociloBox = Hive.box('narociloBox');

    if (nastaviCeno) {
      final newItem = narociloItem.copyWith(
        davcnaSt: davcnaSt,
        isFromTable: fromTable,
      );
      state = [...state, newItem];
      await narociloBox.add(newItem); // Dodaj v Hive
      return;
    }

    if (narociloItem.quantity % 1 != 0) {
      existingItemIndex =
          state.indexWhere((item) => item.uniqueId == narociloItem.uniqueId);
    } else {
      existingItemIndex = state.indexWhere((item) {
        bool isExistingItemIntegerQuantity = (item.quantity % 1 == 0);

        return isExistingItemIntegerQuantity &&
            item.product.id == narociloItem.product.id &&
            item.product.price == narociloItem.product.price &&
            item.description == narociloItem.description &&
            item.discount == narociloItem.discount;
      });
    }

    if (existingItemIndex != -1) {
      // Če obstaja popolno ujemanje (vključno z opisom), posodobi količino
      final existingItem = state[existingItemIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + narociloItem.quantity,
        // Ohranimo popust in ostale lastnosti obstoječega, razen če jih eksplicitno spreminjamo
        davcnaSt: davcnaSt ?? existingItem.davcnaSt,
        isFromTable: fromTable, // Posodobi glede na novo dodajanje
      );
      // Zamenjaj element v listi
      final newState = List<NarociloItem>.from(state);
      newState[existingItemIndex] = updatedItem;
      state = newState;

      final hiveIndex = narociloBox.values
          .toList()
          .indexWhere((item) => item.uniqueId == updatedItem.uniqueId);
      if (hiveIndex != -1) {
        await narociloBox.putAt(hiveIndex, updatedItem);
      }
    } else {
      // Če ni popolnega ujemanja (ali je opis drugačen), dodaj kot novo postavko
      // NarociloItem konstruktor bo sam generiral nov uniqueId

      final newItem = narociloItem.copyWith(
        davcnaSt: davcnaSt,
        isFromTable: fromTable,
      );
      state = [...state, newItem];
      await narociloBox.add(newItem);
    }
  }

  void removeFromRacun(NarociloItem narociloItem) async {
    final narociloBox = Hive.box('narociloBox');

    int indexToRemove = state.indexWhere((item) =>
        item.product.id == narociloItem.product.id &&
        item.description == narociloItem.description &&
        item.product.price == narociloItem.product.price &&
        item.quantity == narociloItem.quantity);

    if (indexToRemove != -1) {
      List<NarociloItem> updatedState = List.from(state);

      // Najprej odstranimo iz Hive (če obstaja enak element v njem)
      final hiveIndex = narociloBox.values.toList().indexWhere((item) =>
          item.product.id == narociloItem.product.id &&
          item.description == narociloItem.description &&
          item.product.price == narociloItem.product.price &&
          item.quantity == narociloItem.quantity);

      if (hiveIndex != -1) {
        await narociloBox.deleteAt(hiveIndex);
      }

      // Nato še iz Riverpod state
      updatedState.removeAt(indexToRemove);
      state = updatedState;
      totalSum();
    }
  }

  double totalSum() {
    return state.fold(0.0, (sum, item) {
      double discountMultiplier = (100 - (item.discount)) / 100;
      double discountedPrice = item.product.price * discountMultiplier;
      double totalForItem = item.quantity * discountedPrice;
      return sum + totalForItem;
    });
  }

  void updateQuantity(String uniqueId, String productId, String description,
      double newQuantity, double itemPrice, double oldQuantity) async {
    final narociloBox = Hive.box('narociloBox');

    final updatedItems = state.map((item) {
      if (item.uniqueId == uniqueId) {
        final updatedItem = item.copyWith(quantity: newQuantity);

        // Posodobi v Hive
        final hiveIndex = narociloBox.values
            .toList()
            .indexWhere((hiveItem) => hiveItem.uniqueId == uniqueId);
        if (hiveIndex != -1) {
          narociloBox.putAt(hiveIndex, updatedItem);
        }

        return updatedItem;
      }
      return item;
    }).toList();

    state = updatedItems;
  }

  void updateDiscount(String uniqueItemId, double discountedPrice,
      double discountPercentage) async {
    final narociloBox = Hive.box('narociloBox');

    final updatedItems = state.map((item) {
      if (item.uniqueId == uniqueItemId) {
        final updatedItem = item.copyWith(
          product: item.product.copyWith(discountedPrice: discountedPrice),
          discount: discountPercentage,
        );

        // Posodobi v Hive
        final hiveIndex = narociloBox.values
            .toList()
            .indexWhere((hiveItem) => hiveItem.uniqueId == uniqueItemId);
        if (hiveIndex != -1) {
          narociloBox.putAt(hiveIndex, updatedItem);
        }

        return updatedItem;
      }
      return item;
    }).toList();

    state = updatedItems;
  }

  void updateOpis(String uniqueItemId, String newOpis) async {
    final narociloBox = Hive.box('narociloBox');

    final updatedItems = state.map((item) {
      if (item.uniqueId == uniqueItemId) {
        final updatedItem = item.copyWith(description: newOpis);

        // Posodobi v Hive
        final hiveIndex = narociloBox.values
            .toList()
            .indexWhere((hiveItem) => hiveItem.uniqueId == uniqueItemId);
        if (hiveIndex != -1) {
          narociloBox.putAt(hiveIndex, updatedItem);
        }

        return updatedItem;
      }
      return item;
    }).toList();

    state = updatedItems;
  }

  void updatePrice(String productId, double newPrice) async {
    final narociloBox = Hive.box('narociloBox');

    final updatedItems = state.map((item) {
      if (item.product.id == productId && item.product.price == 0.0) {
        final updatedItem = item.copyWith(
          product: item.product.copyWith(price: newPrice),
        );

        // Posodobi v Hive
        final hiveIndex = narociloBox.values
            .toList()
            .indexWhere((hiveItem) => hiveItem.uniqueId == item.uniqueId);
        if (hiveIndex != -1) {
          narociloBox.putAt(hiveIndex, updatedItem);
        }

        return updatedItem;
      }
      return item;
    }).toList();

    state = updatedItems;
  }

  void clearRacun() async {
    final narociloBox = Hive.box('narociloBox');
    await narociloBox.clear();
    state = []; // To bo nastavilo stanje na prazen seznam
  }

  // Clears all items in the list
  Future<void> clearChosenItems() async {
    final narociloBox = Hive.box('narociloBox');
    await narociloBox.clear();
    state = [];
  }
}

// Provider for narociloNotifier
final narociloNotifierProvider =
    NotifierProvider<NarociloNotifier, List<NarociloItem>>(
        NarociloNotifier.new);
