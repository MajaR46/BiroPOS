import 'package:BiroPOS/components/narocilo.dart';
import 'package:BiroPOS/controllers/klic.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/selecteditem_provider.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:BiroPOS/providers/tableitem_provider.dart';
import 'package:BiroPOS/screens/blagajna_screen.dart';
import 'package:BiroPOS/screens/mize/new_table_screen.dart';
import 'package:flutter/material.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddToTableScreen extends ConsumerStatefulWidget {
  const AddToTableScreen({
    super.key,
  });

  static Map<String, double> tableSums = {};

  @override
  ConsumerState<AddToTableScreen> createState() => _AddToTableScreenState();
}

class _AddToTableScreenState extends ConsumerState<AddToTableScreen> {
  List<Map<String, String>> tables = [];
  Map<String, List<String>> tableItems = {};

  late List<dynamic> chosenItems;

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTables();
  }

  Future<void> _fetchTables() async {
    setState(() {
      _isLoading = false;
    });

    try {
      String? userId = SessionManager().getLoggedInUserSifra();

      String txtData = 'VrniSeznamMiz';
      List<String> apiResponseList = await sendRequest(userId!, txtData);
      print(apiResponseList);
      List<Map<String, String>> parsedTables = [];

      for (String line in apiResponseList) {
        List<String> splitLine = line.split('|');

        if (splitLine.length >= 4) {
          String prostor = splitLine[0];
          String miza = splitLine[1];
          String cena =
              splitLine[2].replaceAll(',', '.'); // Handle comma decimal

          parsedTables.add({
            'miza': miza,
            'prostor': prostor,
            'cena': cena.isNotEmpty ? cena : '',
          });
        }
      }

      setState(() {
        tables = parsedTables;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching tables: $e';
        _isLoading = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ni vzpostavljene povezave")),
      );
    }
  }

  void addToExistingTable(String tableNumber) async {
    final tableNotifier = ref.read(tableNotifierProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final tiskajNarocilo = settings['isCheckedTiskajNarocilo'] ?? false;

    List<String> serverResponse =
        await tableNotifier.addToExistingTable(context, tableNumber);

    if (tiskajNarocilo == true) {
      await Narocilo.createNarocilo(ref, true, context, tableNumber);
    }

    ref.read(narociloNotifierProvider.notifier).clearChosenItems();
    ref.read(tableNotifierProvider.notifier).state = [];
    clearSelectedItem(ref);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.white,
      appBar: AppBar(
        backgroundColor: AppStyles.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppStyles.black),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const BlagajnaScreen())),
        ),
        title: Text(
          "Dodaj na mizo",
          style: AppStyles.heading3.copyWith(color: AppStyles.black),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: tables.length,
                        itemBuilder: (context, index) {
                          final tableData = tables[index];
                          String tableNumber = tableData['miza'] ?? '';
                          String prostor = tableData['prostor'] ?? '';

                          double tableFinalSum = tableData['cena'] != null
                              ? double.tryParse(tableData['cena'].toString()) ??
                                  0.0
                              : 0.0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 2),
                            child: GestureDetector(
                              onTap: () {
                                addToExistingTable(tableNumber);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const BlagajnaScreen()),
                                );
                                HapticFeedback.vibrate();

                                ;
                              },
                              child: Card(
                                color: AppStyles.silver.withOpacity(0.1),
                                elevation: 0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Miza $tableNumber',
                                            style: AppStyles.heading3,
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${tableFinalSum.toStringAsFixed(2)} €',
                                            style: AppStyles.heading3.copyWith(
                                                fontWeight: FontWeight.normal),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          if (prostor != "Miza")
                                            Expanded(
                                                child: Align(
                                              alignment: Alignment.center,
                                              child: Text(
                                                prostor,
                                                style: AppStyles.paragraph3,
                                              ),
                                            ))
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 24, top: 8),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    height: 50,
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () async {
                        String? newTableNumber = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const NewTableScreen(), // Pass items here
                          ),
                        );

                        if (newTableNumber != null &&
                            newTableNumber.isNotEmpty) {
                          addToExistingTable(newTableNumber);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.blue,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                      ),
                      child: Text(
                        "NOVA MIZA",
                        style:
                            AppStyles.button1.copyWith(color: AppStyles.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
