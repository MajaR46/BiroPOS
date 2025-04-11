import 'package:BiroPOS/providers/selectedcategory_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

final searchLogicProvider = Provider((ref) {
  return SearchLogic(ref: ref);
});

class SearchLogic {
  final Ref ref;

  SearchLogic({required this.ref});

  void updateCategoryBasedOnSearch(String searchText, String controllerText) {
    if (searchText.length == 2 && controllerText.isNotEmpty) {
      if (ref.read(selectedCategoryProvider.notifier).state != 'Iskanje') {
        ref.read(selectedCategoryProvider.notifier).state = 'Iskanje';
        print("nastavljeno na iskanje");
      }
    } else if (searchText.length < 6) {
      if (ref.read(selectedCategoryProvider.notifier).state == 'Iskanje') {
        ref.read(selectedCategoryProvider.notifier).state = 'Vse';
      }
    }
  }
}
