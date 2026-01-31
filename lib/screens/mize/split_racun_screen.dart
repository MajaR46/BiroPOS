import 'package:BiroPOS/components/ok_button.dart';
import 'package:BiroPOS/components/quantity_increase.dart';
import 'package:BiroPOS/controllers/klic.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/controllers/test_connection.dart';
import 'package:BiroPOS/models/item.dart';
import 'package:BiroPOS/models/narociloitem.dart';
import 'package:BiroPOS/models/tableItem.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/tableitem_provider.dart';
import 'package:BiroPOS/screens/blagajna_screen.dart';
import 'package:BiroPOS/screens/racun_screen.dart';
import 'package:flutter/material.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplitRacunScreen extends ConsumerStatefulWidget {
  final String imeMize;
  const SplitRacunScreen({super.key, required this.imeMize});

  @override
  ConsumerState<SplitRacunScreen> createState() => _SplitRacunScreenState();
}

class _SplitRacunScreenState extends ConsumerState<SplitRacunScreen> {
  bool _isLoading = true;
  late String imeMize;
  List<TableItem> izdelki = [];
  List<TableItem> izbraniIzdelki = [];
  bool _isOnline = true;
  String userId = SessionManager().getLoggedInUserSifra() ?? '';

  @override
  void initState() {
    super.initState();
    imeMize = widget.imeMize;
    _fetchSingleTable();
    /*
    Future.delayed(const Duration(seconds: 4), () {
      checkConnection();
    });
    */
  }

  Future<void> _fetchSingleTable() async {
    try {
      String? userId = SessionManager().getLoggedInUserSifra() ?? '';
      String txtdata = 'VrniMizo\t$imeMize';
      List<String> apiResponseList = await sendRequest(userId, txtdata);

      List<TableItem> fetchedItems = [];

      for (String line in apiResponseList) {
        List<String> segments = line.split('|');
        if (segments.length >= 5) {
          fetchedItems.add(
            TableItem(
              productCode: segments[0],
              productName: segments[1],
              quantity: 0,
              price: double.tryParse(segments[3].replaceAll(',', '.')) ?? 0,
              categoryCode: segments[4],
            ),
          );
        }
      }
      setState(() {
        izdelki = fetchedItems;
        _isLoading = false;
      });

      for (var item in fetchedItems) {
        ref.read(tableNotifierProvider.notifier).addToTable(item);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _deleteFromRacun(int index) {
    final itemToRemove = NarociloItem(
      product: Item(
        id: izdelki[index].productCode,
        name: izdelki[index].productName,
        price: izdelki[index].price,
        categoryID: izdelki[index].categoryCode,
      ),
      tableNumber: imeMize,
      quantity: izdelki[index].quantity,
      description: '',
      isFromTable: true,
    );

    ref.read(narociloNotifierProvider.notifier).removeFromRacun(itemToRemove);

    setState(() {
      izdelki.removeAt(index);
    });
  }

  void _dodajNaRacun(List<TableItem> items) async {
    final narociloItems =
        items.where((tableItem) => tableItem.quantity > 0).map((tableItem) {
      final item = Item(
        id: tableItem.productCode,
        name: tableItem.productName,
        price: tableItem.price,
        categoryID: tableItem.categoryCode,
      );

      return NarociloItem(
        product: item,
        tableNumber: imeMize,
        quantity: tableItem.quantity,
        description: '',
        isFromTable: true,
      );
    }).toList();

    var narociloBox = Hive.box('narociloBox');

    for (var narociloItem in narociloItems) {
      ref
          .read(narociloNotifierProvider.notifier)
          .addToRacun(narociloItem, fromTable: true);
      await narociloBox.add(narociloItem);
    }
  }

  void _ok() {
    final itemsToProcess = izbraniIzdelki.isNotEmpty ? izbraniIzdelki : izdelki;
    _dodajNaRacun(itemsToProcess);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RacunScreen(),
      ),
    );
  }

  void onQuantityChanged(double newQuantity, int index) {
    setState(() {
      izdelki[index] = izdelki[index].copyWith(quantity: newQuantity);
    });
  }

  void checkConnection() async {
    bool isOnline = await testConnection(userId);
    setState(() {
      _isOnline = isOnline;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: GestureDetector(
          //onTap: checkConnection,
          child: AppBar(
            backgroundColor: AppStyles.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppStyles.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text("Razdeli račun za: $imeMize",
                style: AppStyles.heading3.copyWith(color: AppStyles.black)),
            centerTitle: true,
            /*
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: Text(
                  _isOnline ? "Online" : "Offline",
                  style: AppStyles.paragraph3.copyWith(
                    color: _isOnline ? AppStyles.green : AppStyles.brightRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
            */
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        separatorBuilder: (context, index) {
                          return Divider(
                            indent: 7,
                            endIndent: 7,
                            color: AppStyles.silver.withOpacity(0.6),
                            thickness: 1,
                          );
                        },
                        itemCount: izdelki.length,
                        itemBuilder: (context, index) {
                          final item = izdelki[index];
                          bool isSelected = izbraniIzdelki.contains(item);
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  izbraniIzdelki.add(item);
                                  HapticFeedback.vibrate();
                                });
                              },
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (item.productName),
                                              style: AppStyles.boldanparagraph1,
                                            )
                                          ],
                                        ),
                                      ),
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: Text(
                                            '${item.price.toString()}€',
                                            style: AppStyles.heading3,
                                          )),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      IconButton.filled(
                                          style: IconButton.styleFrom(
                                              backgroundColor:
                                                  AppStyles.brightRed),
                                          onPressed: () {
                                            _deleteFromRacun(index);
                                            HapticFeedback.vibrate();
                                          },
                                          icon: const Icon(Icons.delete)),
                                      const Spacer(),
                                      QuantityIncrease(
                                        quantity: item.quantity,
                                        onQuantityChanged: (newQuantity) =>
                                            onQuantityChanged(
                                                newQuantity, index),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 16, bottom: 24, top: 8, right: 16),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: OKButton(
                    onPressed: _ok,
                    text: 'OK',
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
