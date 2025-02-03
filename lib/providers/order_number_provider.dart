import 'package:biro_pos/controllers/save_data_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final orderNumberProvider =
    StateNotifierProvider<OrderNumberNotifier, int>((ref) {
  return OrderNumberNotifier();
});

class OrderNumberNotifier extends StateNotifier<int> {
  OrderNumberNotifier() : super(1) {
    _loadOrderNumber();
  }

  // Load the order number from SharedPreferences
  Future<void> _loadOrderNumber() async {
    final storedOrderNumber = await loadOrderNumber();
    state = storedOrderNumber;
  }

  // Save the order number to SharedPreferences and update the state
  Future<void> setOrderNumber(int orderNumber) async {
    await saveOrderNumber(orderNumber);
    state = orderNumber;
  }
}
