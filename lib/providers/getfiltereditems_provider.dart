import 'package:BiroPOS/providers/searchquery_provider.dart';
import 'package:BiroPOS/providers/selectedcategory_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final filteredItemsProvider2 = Provider<List<dynamic>>((ref) {
  final searchText2 = ref.watch(searchQueryProvider);
  final stateSelectedCategory = ref.watch(selectedCategoryProvider);
  final categorizedItems = ref.watch(
      categorizedItemsProvider); // Predpostavljam, da imaš provider za categorizedItems
  final searchControllerText = ref.watch(
      searchControllerTextProvider); // Provider za text iz searchControllerja
  final searchQuery = ref.watch(searchQueryProvider);
  final joinedNumbers = ref.watch(joinedNumbersProvider);

  List<dynamic> _filterItems() {
    List<dynamic> filteredItems = [];

    if (stateSelectedCategory == "Vse" || stateSelectedCategory == "Iskanje") {
      for (var categoryItems in categorizedItems.values) {
        filteredItems.addAll(categoryItems);
      }
    } else {
      filteredItems = categorizedItems[stateSelectedCategory] ?? [];
    }

    String searchText = searchControllerText;
    RegExp regExp = RegExp(r'\d+');
    Iterable<Match> matches = regExp.allMatches(searchText);
    List<String> numbers2 = matches.map((match) => match.group(0)!).toList();
    String numbers2String = numbers2.join();

    // Preverimo dolžino iskalnega besedila pred filtrom po imenu
    if (searchText.length >= 3) {
      if (joinedNumbers.length == 3 && searchQuery.isNotEmpty) {
        final searchQueries = searchQuery
            .toLowerCase()
            .split('|'); // Razdeli niz iskalnih poizvedb
        filteredItems = filteredItems.where((item) {
          String itemName =
              item['name'].toLowerCase().replaceAll(RegExp(r'\d'), '');
          final words = itemName.split(' ');

          // Preveri, ali katerakoli od iskalnih poizvedb ustreza kateri koli besedi
          return searchQueries
              .any((query) => words.any((word) => word.startsWith(query)));
        }).toList();
      } else if (joinedNumbers.length == 6 && searchQuery.isNotEmpty) {
        final searchQueries = searchQuery
            .toLowerCase()
            .split('|'); // Split the search query into multiple queries
        List<String> finalSearchQueries = [];

        // Split each search query into two halves
        for (var query in searchQueries) {
          int middle = (query.length / 2).ceil();
          finalSearchQueries.add(query.substring(0, middle));
          finalSearchQueries.add(query.substring(middle));
        }

        filteredItems = filteredItems.where((item) {
          String itemName =
              item['name'].toLowerCase().replaceAll(RegExp(r'\d'), '');
          List<String> words = itemName.split(' ');

          // Remove empty strings from the list of words
          words = words.where((word) => word.isNotEmpty).toList();

          print("Words: $words");

          // Ensure there are at least two words in `itemName`
          if (words.length < 2) {
            return false; // If there are less than two words, return false
          }

          // Now check if both the first and second words match the search queries
          bool firstWordMatches =
              finalSearchQueries.any((query) => words[0].startsWith(query));
          bool secondWordMatches = words.skip(1).any((word) {
            return finalSearchQueries.any((query) => word.startsWith(query));
          });

          // Both words must match the search queries
          return firstWordMatches && secondWordMatches;
        }).toList();

        print("search queries: $searchQueries");
        print("final search queries: $finalSearchQueries");
      }
    } else if (numbers2String.length <= 5 && searchQuery.isNotEmpty) {
      filteredItems = filteredItems.where((item) {
        return int.tryParse(item['itemId']) == int.tryParse(numbers2String);
      }).toList();
    }

    return filteredItems;
  }

  return _filterItems();
});

//Potrebuješ provider za categorized items, ker jih rabiš v tem providerju.  To je lahko StateProvider, če se ne spreminjajo:
final categorizedItemsProvider =
    StateProvider<Map<String, List<dynamic>>>((ref) => {});

//Potrebuješ provider za searchController.text
final searchControllerTextProvider = StateProvider<String>((ref) => '');

final joinedNumbersProvider = StateProvider<String>((ref) => '');
