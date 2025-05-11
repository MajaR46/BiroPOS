import 'package:BiroPOS/utils/debouncer.dart';
import 'package:BiroPOS/providers/searchquery_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String searchQuery = "";
String joinedNumbers = "";
String numbers = "";
String numbers2String = '';
bool isSearching = false;
final Debouncer _debouncer = Debouncer(miliseconds: 350);

List<int> extractNumbers(String input) {
  // Use RegExp to find all numbers in the input string.
  final matches = RegExp(r'\d').allMatches(input);
  final searchInput =
      matches.map((match) => int.parse(match.group(0)!)).toList();
  return searchInput;
}

Map<int, List<String>> numberToLetters = {
  2: ['a', 'b', 'c'],
  3: ['d', 'e', 'f'],
  4: ['g', 'h', 'i'],
  5: ['j', 'k', 'l'],
  6: ['m', 'n', 'o'],
  7: ['p', 'q', 'r', 's'],
  8: ['t', 'u', 'v'],
  9: ['w', 'x', 'y', 'z'],
};

void generatePairs(TextEditingController searchController) {
  String input = searchController.text;

  List<int> numbers = extractNumbers(input)
      .where((numb) => numberToLetters.containsKey(numb))
      .toList();

  joinedNumbers = numbers.join();

  List<List<String>> letterGroups =
      numbers.map((numb) => numberToLetters[numb]!).toList();

  List<String> combinations = combineLetters(letterGroups);

  if (combinations.isNotEmpty) {
    searchQuery = combinations.join('|');
  } else {
    searchQuery = '';
  }
}

List<String> combineLetters(List<List<String>> letterGroups) {
  if (letterGroups.isEmpty) return [];

  List<String> result = letterGroups[0];

  for (int i = 1; i < letterGroups.length; i++) {
    List<String> newResult = [];
    for (String prefix in result) {
      for (String letter in letterGroups[i]) {
        newResult.add(prefix + letter);
      }
    }
    result = newResult;
  }
  return result;
}

void updateNumbersString(
    TextEditingController searchController, WidgetRef ref) {
  String generatedQuery = ''; // Define it here to ensure it's always available

  if (searchController.text.isNotEmpty) {
    RegExp regExp = RegExp(r'[\d.]+');
    Iterable<Match> matches = regExp.allMatches(searchController.text);
    List<String> numbers2 = matches.map((match) => match.group(0)!).toList();
    numbers2String = numbers2.join();

    // Ensure iskalniNiz and searchQuery are generated in the same way
    generatedQuery = numbers2String.isNotEmpty
        ? generateQueryFromNumbers(numbers2String)
        : '';

    ref.read(iskalniNiz.notifier).state = generatedQuery;
    ref.read(searchQueryProvider.notifier).state = numbers2String;
    ref.read(isSearchingProvider.notifier).state = true;
  } else {
    ref.read(iskalniNiz.notifier).state = '';
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(isSearchingProvider.notifier).state = false;
  }
}

// Generate a query based on number input
String generateQueryFromNumbers(String numbers) {
  List<int> numberList = numbers.split('').map((e) => int.parse(e)).toList();
  List<List<String>> letterGroups =
      numberList.map((n) => numberToLetters[n]!).toList();
  List<String> combinations = combineLetters(letterGroups);
  return combinations.join('|');
}
