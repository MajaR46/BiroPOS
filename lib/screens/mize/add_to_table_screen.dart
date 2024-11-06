import 'package:biro_pos/components/blagajna_banner.dart';
import 'package:biro_pos/components/ok_button.dart';
import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:biro_pos/models/narociloitem.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/screens/blagajna_screen.dart';
import 'package:biro_pos/screens/mize/new_table_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      _isLoading = true;
    });

    try {
      List<String> apiResponseList = await sendRequest("1", "VrniSeznamMiz");

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
        _isLoading = false;
      });
    }
  }

  void _addToExistingTable(String tableNumber) async {
    String? userId = SessionManager().getLoggedInUserSifra();
    List<NarociloItem> chosenItems = ref.read(narociloNotifierProvider);

    List<String> narociloItems = chosenItems.map((item) {
      String artikelSifra = item.product.id?.toString() ?? '';
      double kolicina = (item.quantity ?? 1.0).toDouble();

      double originalPrice = double.tryParse(
              item.product.price?.toString().replaceAll(',', '.') ?? '0.0') ??
          0.0;
      double itemDiscountedPrice = item.product.discountedPrice > 0
          ? item.product.discountedPrice
          : originalPrice;

      num popust = (originalPrice != 0)
          ? ((1 - (itemDiscountedPrice / originalPrice)) * 100)
          : 0;

      String opis = item.description;
      String artikelSkupina = item.product.categoryID?.toString() ?? '';

      String narociloItem =
          '$userId\t$tableNumber\t$artikelSifra\t$kolicina\t$originalPrice\t$popust\t$opis\t$artikelSkupina';
      print("Narocilo item $narociloItem");
      return narociloItem;
    }).toList();

    List<String> posljiNaStreznik =
        await sendRequest("1", narociloItems.join('\r\n'));

    ref.read(narociloNotifierProvider.notifier).state = [];

    Navigator.push(
        context, MaterialPageRoute(builder: (context) => BlagajnaScreen()));
    print("Poslji na streznik $posljiNaStreznik");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppStyles.black),
          onPressed: () => Navigator.of(context).pop(),
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
                          double tableFinalSum = tableData['cena'] != null
                              ? double.tryParse(tableData['cena'].toString()) ??
                                  0.0
                              : 0.0;
                          List<String> itemsForTable =
                              tableItems[tableNumber] ?? [];

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: GestureDetector(
                              onTap: () {
                                _addToExistingTable(tableNumber);
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
                                NewTableScreen(), // Pass items here
                          ),
                        );

                        if (newTableNumber != null &&
                            newTableNumber.isNotEmpty) {
                          _addToExistingTable(newTableNumber);
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
