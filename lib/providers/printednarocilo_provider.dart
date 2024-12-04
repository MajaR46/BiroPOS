import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrintedNarocilaNotifier extends Notifier<List<List<String>>> {
  @override
  List<List<String>> build() {
    return [];
  }

  void sprintanaNarocila(String narocilo) {
    if (!state.any((existing) => existing.contains(narocilo))) {
      state = [
        ...state,
        [narocilo]
      ];
    }
  }

  bool isPrinted(String narocilo) {
    return state.any((existing) => existing.contains(narocilo));
  }
}

// Define the provider outside the class.
final printedNarocilaProvider =
    NotifierProvider<PrintedNarocilaNotifier, List<List<String>>>(
  PrintedNarocilaNotifier.new,
);
