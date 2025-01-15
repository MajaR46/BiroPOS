import 'package:biro_pos/components/ok_button.dart';
import 'package:biro_pos/components/quantity_increase.dart';
import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:biro_pos/models/item.dart';
import 'package:biro_pos/models/narociloitem.dart';
import 'package:biro_pos/models/tableItem.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/providers/tableitem_provider.dart';
import 'package:biro_pos/screens/blagajna_screen.dart';
import 'package:biro_pos/screens/mize/prenos_mize_screen.dart';
import 'package:biro_pos/screens/mize/split_racun_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MizaDetailsScreen extends ConsumerStatefulWidget {
  final String imeMize;
  const MizaDetailsScreen({super.key, required this.imeMize});

  @override
  ConsumerState<MizaDetailsScreen> createState() => _MizaDetailsScreenState();
}

class _MizaDetailsScreenState extends ConsumerState<MizaDetailsScreen> {
  bool _isLoading = true;
  late String imeMize;
  List<TableItem> izdelki = [];
  List<TableItem> izbraniIzdelki = [];

  @override
  void initState() {
    super.initState();
    imeMize = widget.imeMize;
    _fetchSingleTable();
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
              quantity: double.tryParse(segments[2].replaceAll(',', '.')) ?? 0,
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

  void _dodajNaRacun(List<TableItem> items) {
    final narociloItems = items.map((tableItem) {
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

    for (var narociloItem in narociloItems) {
      ref
          .read(narociloNotifierProvider.notifier)
          .addToRacun(narociloItem, fromTable: true);
    }
  }

  void _ok() {
    final itemsToProcess = izbraniIzdelki.isNotEmpty ? izbraniIzdelki : izdelki;
    _dodajNaRacun(itemsToProcess);

    // Navigate to BlagajnaScreen after adding items to the bill
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BlagajnaScreen(),
      ),
    );
  }

  void _prenosMize() {
    final itemsToProcess = izbraniIzdelki.isNotEmpty ? izbraniIzdelki : izdelki;
    _dodajNaRacun(itemsToProcess);

    // Navigate to PrenosMizeScreen, passing the current table number
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrenosMizeScreen(tableNumber: imeMize),
      ),
    );
  }

  void onQuantityChanged(double newQuantity, int index) {
    setState(() {
      izdelki[index] = izdelki[index].copyWith(quantity: newQuantity);
    });
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Miza: $imeMize",
            style: AppStyles.heading3.copyWith(color: AppStyles.black)),
        centerTitle: true,
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
                                            Text(item.productName,
                                                style:
                                                    AppStyles.boldanparagraph1),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: Text('${item.price.toString()}€',
                                            style: AppStyles.heading3),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      IconButton.filled(
                                          style: IconButton.styleFrom(
                                              backgroundColor: AppStyles.red),
                                          onPressed: () =>
                                              _deleteFromRacun(index),
                                          icon: const Icon(Icons.delete)),
                                      const Spacer(),
                                      QuantityIncrease(
                                        quantity: item.quantity,
                                        onQuantityChanged: (newQuantity) {
                                          onQuantityChanged(newQuantity, index);
                                        },
                                      ),
                                    ],
                                  )
                                ],
                              ),

                              /* Card(
                                color: isSelected
                                    ? Colors.blue.withOpacity(0.1)
                                    : AppStyles.silver.withOpacity(0.1),
                                elevation: 0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          item.productName,
                                          style: AppStyles.paragraph2.copyWith(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton.filled(
                                          style: IconButton.styleFrom(
                                              backgroundColor: AppStyles.red),
                                          onPressed: () => _deleteFromRacun(
                                              index), // Pass the index here
                                          icon: const Icon(Icons.delete)),
                                      QuantityIncrease(
                                        quantity: item.quantity,
                                        onQuantityChanged: (newQuantity) =>
                                            onQuantityChanged(
                                                newQuantity, index),
                                      ),
                                    ],
                                  ),
                                ),
                              ), */
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 16, bottom: 24, top: 8, right: 16),
                child: Flex(
                  direction: Axis.horizontal,
                  children: [
                    // Button 1
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _prenosMize,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.silver.withOpacity(0.1),
                          elevation: 0,
                        ),
                        child: Text(
                          "Prenos",
                          style: AppStyles.button1
                              .copyWith(color: AppStyles.black),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Button 2
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SplitRacunScreen(imeMize: imeMize),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.silver.withOpacity(0.1),
                          elevation: 0,
                        ),
                        child: Text(
                          "Razdeli",
                          style: AppStyles.button1
                              .copyWith(color: AppStyles.black),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Button 3
                    Align(
                      alignment: Alignment.bottomRight,
                      child: OKButton(onPressed: _ok),
                    ),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
