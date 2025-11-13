import 'package:BiroPOS/controllers/table_controller.dart';
import 'package:BiroPOS/models/narociloitem.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/searchquery_provider.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:BiroPOS/screens/mize/add_to_table_screen.dart';
import 'package:BiroPOS/screens/mize/open_tables_screen.dart';
import 'package:BiroPOS/screens/mize/prostori_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> navigateToMizaScreen(
    BuildContext context,
    WidgetRef ref,
    TextEditingController searchController,
    List<Map<String, dynamic>> tables) async {
  List<NarociloItem> currentChosenItems = ref.read(narociloNotifierProvider);
  String searchQuery = searchController.text;
  String stMize = searchQuery.replaceAll(RegExp(r'[^0-9.]'), '');
  final settings = ref.watch(settingsProvider);
  final isCheckedDirektneMize = settings['isCheckedDirektneMize'] ?? false;

  if (stMize.isNotEmpty && isCheckedDirektneMize) {
    await TableService.addToExistingTable(stMize, ref, context);
    searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
  } else {
    final table = tables.firstWhere(
      (table) => table['prostor'] != '',
      orElse: () => <String, String>{},
    );

    if (currentChosenItems.isNotEmpty) {
      // Predpostavljam, da želiš preveriti prvi element v tabelah, lahko pa pregleduješ tudi specifičen index.

      if (table['prostor'] == null ||
          table['prostor']!.isEmpty && table['prostor'] != 'Miza') {
        // Če je 'prostor' prazen, preusmeri na AddToTableScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AddToTableScreen()),
        );
      } else {
        // Če 'prostor' ni prazen, preusmeri na ProstoriScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const ProstoriScreen(
                    whereTo: "DodajNaMizo",
                  )),
        );
      }
    } else {
      if (table['prostor'] == null ||
          table['prostor']!.isEmpty && table['prostor'] != "Miza") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const OpenTablesScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const ProstoriScreen(
                    whereTo: "VrniPrazneMize",
                  )),
        );
      }
    }
  }
}
