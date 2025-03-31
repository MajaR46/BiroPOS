import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Define a Provider
final searchQueryProvider =
    StateProvider<String>((ref) => ''); // Initial value is an empty string

final isSearchingProvider = StateProvider<bool>((ref) => false);

final filteredItemsProvider = StateProvider<List<dynamic>>((ref) => []);

void clearSearchQuery(WidgetRef ref) {
  ref.read(searchQueryProvider.notifier).state = '';
}

final searchTextProvider = StateProvider<String>((ref) => '');
