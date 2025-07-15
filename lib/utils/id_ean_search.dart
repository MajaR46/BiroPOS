import 'package:BiroPOS/models/item.dart';
import 'package:BiroPOS/models/narociloitem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Assuming you have these providers defined somewhere:
import 'package:BiroPOS/providers/categoriseditems_provider.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

void searchByEan(String input, WidgetRef ref, BuildContext context,
    Function updateTotalDiscount,
    {double quantity = 1.0}) async {
  RegExp regExp = RegExp(r'\d+');
  Iterable<Match> matches = regExp.allMatches(input);
  List<String> numbers = matches.map((match) => match.group(0)!).toList();
  String numbersToString = numbers.join();
  final items = ref.watch(itemsProvider);
  List<Item> matchingItems = [];

  var narociloBox = Hive.box('narociloBox');

  if (numbersToString.length >= 6 && input.isNotEmpty) {
    matchingItems = items.where((item) {
      return item.eanCode == numbersToString;
    }).toList();

    if (matchingItems.isNotEmpty) {
      Item matchingItem = matchingItems.first;
      NarociloItem newNarociloItem =
          NarociloItem(product: matchingItem, quantity: quantity);

      ref
          .read(narociloNotifierProvider.notifier)
          .addToRacun(newNarociloItem, fromTable: false);
      await narociloBox.add(newNarociloItem);
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
      NarociloItem newNarociloItem =
          NarociloItem(product: matchingItem, quantity: quantity);

      ref
          .read(narociloNotifierProvider.notifier)
          .addToRacun(newNarociloItem, fromTable: false);

      await narociloBox.add(newNarociloItem);

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
