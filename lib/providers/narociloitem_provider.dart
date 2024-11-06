import 'package:biro_pos/models/narociloitem.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NarociloNotifier extends Notifier<List<NarociloItem>> {
  double _discountPercentage = 0.0;

  @override
  List<NarociloItem> build() {
    return [];
  }

  void addToRacun(NarociloItem narociloItem) {
    final existingItemIndex =
        state.indexWhere((item) => item.product.id == narociloItem.product.id);

    if (existingItemIndex != -1) {
      state[existingItemIndex] = state[existingItemIndex].copyWith(
        quantity: state[existingItemIndex].quantity + narociloItem.quantity,
        discount: state[existingItemIndex].discount ??
            0.0, // Ensure discount is set to zero if not present
      );
    } else {
      // Add item with discount defaulting to zero if not set
      state = [
        ...state,
        narociloItem.copyWith(discount: narociloItem.discount ?? 0.0),
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
      double discountMultiplier = (100 - (item.discount ?? 0.0)) / 100;
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
}

// Provider definition
final narociloNotifierProvider =
    NotifierProvider<NarociloNotifier, List<NarociloItem>>(() {
  return NarociloNotifier();
});
