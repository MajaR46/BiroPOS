import 'package:biro_pos/models/narociloitem.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NarociloNotifier extends Notifier<List<NarociloItem>> {
  @override
  List<NarociloItem> build() {
    return [];
  }

  void addToRacun(NarociloItem narociloItem, {bool fromTable = false}) {
    final String? davcnaSt = ref.read(taxNumberProvider);

    final existingItemIndex =
        state.indexWhere((item) => item.product.id == narociloItem.product.id);

    if (existingItemIndex != -1) {
      // Update existing item with new quantity and potentially new davcnaSt
      state[existingItemIndex] = state[existingItemIndex].copyWith(
          quantity: state[existingItemIndex].quantity + narociloItem.quantity,
          discount: state[existingItemIndex].discount,
          davcnaSt: davcnaSt ?? state[existingItemIndex].davcnaSt,
          isFromTable: fromTable);
    } else {
      // Add new item with specified davcnaSt
      state = [
        ...state,
        narociloItem.copyWith(
            discount: narociloItem.discount,
            davcnaSt: davcnaSt,
            isFromTable: fromTable),
      ];
    }
  }

  void removeFromRacun(NarociloItem narociloItem) {
    state = state
        .where((item) => item.product.id != narociloItem.product.id)
        .toList();
  }

  double totalSum() {
    return state.fold(0.0, (sum, item) {
      double discountMultiplier = (100 - (item.discount)) / 100;
      double discountedPrice = item.product.price * discountMultiplier;
      double totalForItem = item.quantity * discountedPrice;
      return sum + totalForItem;
    });
  }

  void updateQuantity(String productId, double newQuantity) {
    final updatedItems = state.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    state = updatedItems;
  }

  void updateDiscount(
      String productId, double discountedPrice, double discountPercentage) {
    final updatedItems = state.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(
          product: item.product.copyWith(discountedPrice: discountedPrice),
          discount: discountPercentage,
        );
      }
      return item;
    }).toList();

    state = updatedItems;
  }

  void updateOpis(String productId, String newOpis) {
    final updatedItems = state.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(description: newOpis);
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
