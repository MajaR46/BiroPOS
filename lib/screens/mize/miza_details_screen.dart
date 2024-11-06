import 'package:biro_pos/components/blagajna_banner.dart';
import 'package:biro_pos/components/ok_button.dart';
import 'package:biro_pos/components/quantity_increase.dart';
import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/models/item.dart';
import 'package:biro_pos/models/narociloitem.dart';
import 'package:biro_pos/models/tableItem.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/screens/blagajna_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  void initState() {
    super.initState();
    imeMize = widget.imeMize;
    _fetchSingleTable();
  }

  Future<void> _fetchSingleTable() async {
    try {
      String txtdata = 'VrniMizo\t$imeMize';
      List<String> apiResponseList = await sendRequest("1", txtdata);

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
    } catch (e) {
      print("Error: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _ok() {
    final narociloItems = izdelki.map((tableItem) {
      final item = Item(
        id: tableItem.productCode,
        name: tableItem.productName,
        price: tableItem.price,
        categoryID: tableItem.categoryCode,
      );

      return NarociloItem(
        product: item,
        quantity: tableItem.quantity,
        description: '',
      );
    }).toList();

    // Add each NarociloItem to the bill individually
    for (var narociloItem in narociloItems) {
      ref.read(narociloNotifierProvider.notifier).addToRacun(narociloItem);
    }

    // Navigate to BlagajnaScreen after adding items to the bill
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlagajnaScreen(),
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
      appBar: AppBar(
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.blue.withOpacity(0.1),
                            elevation: 0),
                        child: Text(
                          "Odznači",
                          style: AppStyles.button1
                              .copyWith(color: AppStyles.black),
                        )),
                    ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.blue.withOpacity(0.1),
                            elevation: 0),
                        child: Text(
                          "Prenos",
                          style: AppStyles.button1
                              .copyWith(color: AppStyles.black),
                        )),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                child: Row(
                  children: [
                    Text("Izdelek",
                        style:
                            AppStyles.heading3.copyWith(color: AppStyles.blue)),
                    Spacer(),
                    Text("Količina",
                        style:
                            AppStyles.heading3.copyWith(color: AppStyles.blue)),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: izdelki.length,
                        itemBuilder: (context, index) {
                          final item = izdelki[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Card(
                              color: AppStyles.silver.withOpacity(0.1),
                              elevation: 0,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                child: Row(
                                  children: [
                                    Text(
                                      item.productName,
                                      style: AppStyles.heading4.copyWith(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Spacer(),
                                    QuantityIncrease(
                                      quantity: item.quantity,
                                      onQuantityChanged: (newQuantity) =>
                                          onQuantityChanged(newQuantity, index),
                                    ),
                                  ],
                                ),
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
                  child: OKButton(onPressed: _ok),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
