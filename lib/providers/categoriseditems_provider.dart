import 'package:biro_pos/models/item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define the Item state provider
final itemsProvider = StateNotifierProvider<ItemsNotifier, List<Item>>((ref) {
  return ItemsNotifier();
});

class ItemsNotifier extends StateNotifier<List<Item>> {
  ItemsNotifier() : super([]);

  // Method to add an item to the list
  void addItem(Item item) {
    state = [...state, item];
  }

  // Method to update the list with multiple items
  void setItems(List<Item> items) {
    state = items;
  }
}
