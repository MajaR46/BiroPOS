import 'package:biro_pos/models/item.dart';
import 'package:biro_pos/models/narociloitem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Assuming you have these providers defined somewhere:
import 'package:biro_pos/providers/categoriseditems_provider.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';

void searchByEan(String input, WidgetRef ref, BuildContext context,
    Function updateTotalDiscount) {
  RegExp regExp = RegExp(r'\d+');
  Iterable<Match> matches = regExp.allMatches(input);
  List<String> numbers = matches.map((match) => match.group(0)!).toList();
  String numbersToString = numbers.join();
  final items = ref.watch(itemsProvider);
  List<Item> matchingItems = [];

  if (numbersToString.length >= 6 && input.isNotEmpty) {
    matchingItems = items.where((item) {
      return item.eanCode == numbersToString;
    }).toList();

    if (matchingItems.isNotEmpty) {
      Item matchingItem = matchingItems.first;
      NarociloItem newNarociloItem = NarociloItem(product: matchingItem);

      ref
          .read(narociloNotifierProvider.notifier)
          .addToRacun(newNarociloItem, fromTable: false);
      updateTotalDiscount();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ne najdem izdelka s to EAN kodo")),
      );
    }
  } else if (numbersToString.length <= 5 && input.isNotEmpty) {
    matchingItems = items.where((item) {
      return int.tryParse(item.id) == int.tryParse(numbersToString);
    }).toList();

    if (matchingItems.isNotEmpty) {
      Item matchingItem = matchingItems.first;
      NarociloItem newNarociloItem = NarociloItem(product: matchingItem);

      ref
          .read(narociloNotifierProvider.notifier)
          .addToRacun(newNarociloItem, fromTable: false);
      updateTotalDiscount();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ne najdem izdelka s tem IDjem")),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ne najdem izdelka")),
    );
  }
}

bool checkAndSetSearchMode(String searchText) {
  return searchText.isNotEmpty;
}
