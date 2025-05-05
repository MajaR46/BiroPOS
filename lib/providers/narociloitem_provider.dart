import 'package:BiroPOS/models/narociloitem.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NarociloNotifier extends Notifier<List<NarociloItem>> {
  @override
  List<NarociloItem> build() {
    return [];
  }

  void addToRacun(NarociloItem narociloItem, {bool fromTable = false}) {
    final String? davcnaSt = ref.read(taxNumberProvider);

    // Poiščemo obstoječi izdelek z enakim ID-jem izdelka, ceno IN opisom
    final existingItemIndex = state.indexWhere((item) =>
            item.product.id == narociloItem.product.id &&
            item.product.price == narociloItem.product.price &&
            item.description ==
                narociloItem.description // <-- Primerjaj tudi opis
        );

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
    } else {
      // Če ni popolnega ujemanja (ali je opis drugačen), dodaj kot novo postavko
      // NarociloItem konstruktor bo sam generiral nov uniqueId
      state = [
        ...state,
        narociloItem.copyWith(
          // Uporabi copyWith za nastavitev davcnaSt itd.
          davcnaSt: davcnaSt,
          isFromTable: fromTable,
          // Opis in ostalo pride iz `narociloItem` parametra
        ),
      ];
    }
  }

  void removeFromRacun(NarociloItem narociloItem) {
    int indexToRemove = state.indexWhere((item) =>
        item.product.id == narociloItem.product.id &&
        item.description == narociloItem.description &&
        item.product.price == narociloItem.product.price &&
        item.quantity == narociloItem.quantity);

    if (indexToRemove != -1) {
      List<NarociloItem> updatedState = List.from(state);
      updatedState.removeAt(indexToRemove);
      state = updatedState;
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
      double newQuantity, double itemPrice, double oldQuantity) {
    final updatedItems = state.map((item) {
      if (item.uniqueId == uniqueId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();
    state = updatedItems;
  }

  void updateDiscount(
      String uniqueItemId, double discountedPrice, double discountPercentage) {
    final updatedItems = state.map((item) {
      if (item.uniqueId == uniqueItemId) {
        return item.copyWith(
          product: item.product.copyWith(discountedPrice: discountedPrice),
          discount: discountPercentage,
        );
      }
      return item;
    }).toList();

    state = updatedItems;
  }

  void updateOpis(String uniqueItemId, String newOpis) {
    state = state.map((item) {
      if (item.uniqueId == uniqueItemId) {
        // Odstranjen pogoj item.description.isEmpty
        return item.copyWith(description: newOpis);
      }
      return item;
    }).toList();
  }

  void updatePrice(String productId, double newPrice) {
    final updatedItems = state.map((item) {
      if (item.product.id == productId && item.product.price == 0.0) {
        return item.copyWith(
          product: item.product.copyWith(price: newPrice),
        );
      }
      return item;
    }).toList();

    state = updatedItems;
  }

  // Clears all items in the list
  void clearChosenItems() {
    state = [];
  }
}

// Provider for managing davcna (tax number)
final taxNumberProvider = StateProvider<String?>((ref) => null);

// Function to set the tax number
void setTaxNumber(WidgetRef ref, String taxNumber) {
  ref.read(taxNumberProvider.notifier).state = taxNumber;
}

// Clear davcna using the taxNumberProvider
void clearDavcna(WidgetRef ref) {
  ref.read(taxNumberProvider.notifier).state = '';
}

// Provider for narociloNotifier
final narociloNotifierProvider =
    NotifierProvider<NarociloNotifier, List<NarociloItem>>(
        NarociloNotifier.new);
