import 'package:BiroPOS/components/ok_button.dart';
import 'package:BiroPOS/components/quantity_increase.dart';
import 'package:BiroPOS/controllers/klic.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/controllers/test_connection.dart';
import 'package:BiroPOS/models/item.dart';
import 'package:BiroPOS/models/narociloitem.dart';
import 'package:BiroPOS/models/tableItem.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/selecteditem_provider.dart';
import 'package:BiroPOS/providers/tableitem_provider.dart';
import 'package:BiroPOS/screens/blagajna_screen.dart';
import 'package:BiroPOS/screens/mize/prenos_mize_screen.dart';
import 'package:BiroPOS/screens/mize/split_racun_screen.dart';
import 'package:BiroPOS/screens/racun_screen.dart';
import 'package:flutter/material.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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
  bool _isOnline = true;
  String userId = SessionManager().getLoggedInUserSifra() ?? '';

  @override
  void initState() {
    super.initState();
    imeMize = widget.imeMize;
    _fetchSingleTable();
    checkConnection();
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
      ref.read(tableNotifierProvider.notifier).clearTable(); // nova vrstica

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

  Future<void> _dodajNaRacun(List<TableItem> items) async {
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

      final narociloBox = Hive.box('narociloBox');
      print("Shranjujem ${narociloItem.product.name}");
      await narociloBox.add(narociloItem);
      print("Vsebina Hive:");
      for (var item in narociloBox.values) {
        print(" - ${item.product.name}, ${item.quantity}");
      }
    }
  }

  void _ok() async {
    final itemsToProcess =
        (izbraniIzdelki.isNotEmpty ? izbraniIzdelki : izdelki)
            .where((item) => item.disabled != true)
            .toList();
    await _dodajNaRacun(itemsToProcess);

    clearSelectedItem(ref);

    var orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.portrait) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RacunScreen(),
        ),
      );
    } else if (orientation == Orientation.landscape) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BlagajnaScreen(),
        ),
      );
    }
  }

  void _prenosMize() {
    final itemsToProcess =
        (izbraniIzdelki.isNotEmpty ? izbraniIzdelki : izdelki)
            .where((item) => item.disabled != true)
            .toList();
    _dodajNaRacun(itemsToProcess);

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

  void _disableItems([int? index]) {
    setState(() {
      if (index != null) {
        final item = izdelki[index];
        izdelki[index] = item.copyWith(disabled: !(item.disabled ?? false));
      } else {
        final allDisabled = izdelki.every((item) => item.disabled == true);
        izdelki = izdelki
            .map((item) => item.copyWith(disabled: !allDisabled))
            .toList();
      }
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
          onTap: checkConnection,
          child: AppBar(
            backgroundColor: AppStyles.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppStyles.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text("Miza: $imeMize",
                style: AppStyles.heading3.copyWith(color: AppStyles.black)),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  _isOnline ? "Online" : "Offline",
                  style: AppStyles.paragraph3.copyWith(
                    color: _isOnline ? AppStyles.green : AppStyles.brightRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppStyles.green, AppStyles.grey],
                      stops: [0.5, 0.5],
                      begin: Alignment.bottomRight,
                      end: Alignment.topLeft,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 24,
                    onPressed: () {
                      HapticFeedback.vibrate();
                      _disableItems();
                    },
                    icon: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 24, // Spremeni barvo ikone po potrebi
                    ),
                  ),
                ),
              ),
            ],
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
                          return Container(
                            color: (item.disabled ?? false)
                                ? AppStyles.grey.withOpacity(0.5)
                                : AppStyles.white,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
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
                                              backgroundColor: item.disabled
                                                  ? AppStyles.grey
                                                  : AppStyles.green),
                                          onPressed: () {
                                            _disableItems(index);
                                            HapticFeedback.vibrate();
                                          },
                                          icon: Icon(
                                            Icons.check_rounded,
                                          )),
                                      const Spacer(),
                                      QuantityIncrease(
                                        quantity: item.quantity,
                                        onQuantityChanged: (newQuantity) {
                                          onQuantityChanged(newQuantity, index);
                                          HapticFeedback.vibrate();
                                        },
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
                child: Flex(
                  direction: Axis.horizontal,
                  children: [
                    // Button 1
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          _prenosMize();
                          HapticFeedback.vibrate();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppStyles.silver.withAlpha((0.1 * 255).round()),
                          elevation: 0,
                        ),
                        child: Text(
                          "NA DRUGO MIZO",
                          style: AppStyles.button1
                              .copyWith(color: AppStyles.black),
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Button 3
                    Align(
                      alignment: Alignment.bottomRight,
                      child: OKButton(onPressed: _ok, text: 'NA RAČUN'),
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
