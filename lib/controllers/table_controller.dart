import 'package:BiroPOS/components/narocilo.dart';
import 'package:BiroPOS/controllers/klic.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/searchquery_provider.dart';
import 'package:BiroPOS/providers/selecteditem_provider.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:BiroPOS/providers/tableitem_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TableService {
  static Future<List<Map<String, String>>> fetchTables() async {
    try {
      String? userId = SessionManager().getLoggedInUserSifra();

      String txtData = 'VrniSeznamMiz';
      List<String> apiResponseList = await sendRequest(userId!, txtData);
      List<Map<String, String>> parsedTables = [];

      for (String line in apiResponseList) {
        List<String> splitLine = line.split('|');

        if (splitLine.length >= 4) {
          String prostor = splitLine[0];
          String miza = splitLine[1];
          String cena = splitLine[2].replaceAll(',', '.');

          parsedTables.add({
            'miza': miza,
            'prostor': prostor,
            'cena': cena.isNotEmpty ? cena : '',
          });
        }
      }

      return parsedTables;
    } catch (e) {
      print('Napaka pri pridobivanju miz: $e');
      return [];
    }
  }

  static Future<void> addToExistingTable(
      String tableNumber, WidgetRef ref, BuildContext context) async {
    final tableNotifier = ref.read(tableNotifierProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final tiskajNarocilo = settings['isCheckedTiskajNarocilo'] ?? false;

    List<String> serverResponse =
        await tableNotifier.addToExistingTable(context, tableNumber);

    if (tiskajNarocilo == true) {
      await Narocilo.createNarocilo(ref, true, context, tableNumber);
    }
    ref.read(narociloNotifierProvider.notifier).clearChosenItems();
    var narociloBox = Hive.box('narociloBox');
    await narociloBox.clear();

    ref.read(tableNotifierProvider.notifier).state = [];
    ref.read(iskalniNiz.notifier).state = '';
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(isSearchingProvider.notifier).state = false;
    clearSelectedItem(ref);
  }
}
