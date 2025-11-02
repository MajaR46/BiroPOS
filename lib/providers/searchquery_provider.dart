import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Define a Provider
final searchQueryProvider =
    StateProvider<String>((ref) => ''); // Initial value is an empty string

final iskalniNiz = StateProvider<String>((ref) => '');

final isSearchingProvider = StateProvider<bool>((ref) => false);

final filteredItemsProvider = StateProvider<List<dynamic>>((ref) => []);

void clearSearchQuery(WidgetRef ref) {
  ref.read(searchQueryProvider.notifier).state = '';
}

final lastSearchQueryProvider = StateProvider<String>((ref) => '');
