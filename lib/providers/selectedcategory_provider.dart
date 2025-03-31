import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedCategoryProvider =
    StateNotifierProvider<SelectedCategoryNotifier, String>((ref) {
  return SelectedCategoryNotifier();
});

class SelectedCategoryNotifier extends StateNotifier<String> {
  SelectedCategoryNotifier() : super('Vse'); // Default state

  void updateCategoryBasedOnSearch(String searchText) {
    String filtriranSearch = searchText.replaceAll(RegExp(r'[^0-9]'), '');

    if (filtriranSearch.length == 2 && searchText.isNotEmpty) {
      if (state != 'Iskanje') {
        state = 'Iskanje';
        print("nastavjeno na iskanje");
      }
    } else if (filtriranSearch.length < 6) {
      if (state == 'Iskanje') {
        state = 'Vse';
      }
    }
  }
}
