import 'package:biro_pos/components/keyboard.dart';
import 'package:biro_pos/components/quantity_increase.dart';
import 'package:biro_pos/models/item.dart';
import 'package:biro_pos/models/nacinPlacila.dart';
import 'package:biro_pos/models/narociloitem.dart';
import 'package:biro_pos/providers/categoriseditems_provider.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/providers/direct_payment_provider.dart';
import 'package:biro_pos/providers/searchquery_provider.dart';
import 'package:biro_pos/providers/totdal_sum_provider.dart';
import 'package:biro_pos/screens/blagajna_screen.dart';
import 'package:biro_pos/screens/edit_item_screen.dart';
import 'package:biro_pos/screens/mize/add_to_table_screen.dart';
import 'package:biro_pos/screens/mize/open_tables_screen.dart';
import 'package:biro_pos/screens/nacin_placila_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RacunScreen extends ConsumerStatefulWidget {
  const RacunScreen({
    super.key,
  });

  @override
  ConsumerState<RacunScreen> createState() => _RacunScreenState();
}

class _RacunScreenState extends ConsumerState<RacunScreen> {
  double _totalDiscount = 0.0;
  final TextEditingController discountController = TextEditingController();
  List<NacinPlacila> naciniPlacila = [];
  String itemOpis = '';
  double itemPrice = 0.0;
  late OrderService orderService;
  final TextEditingController searchController = TextEditingController();
  bool _isSearchMode = false;
  bool _isKeyboardListenerEnabled = false;

  // NEW: Barcode scanner implementation
  final FocusNode _barcodeFocusNode = FocusNode();
  final FocusNode _discountFocusNode = FocusNode();
  String _scannedBarcode = '';
  bool _isDiscountDialogOpen = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final orderService = ref.read(orderProvider);
      orderService.initializePaymentMethods();
    });
    searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).state = searchController.text;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTotalDiscount();

    if (!_isDiscountDialogOpen && ModalRoute.of(context)?.isCurrent == true) {
      FocusScope.of(context).requestFocus(_barcodeFocusNode);
    }
  }

  @override
  void dispose() {
    _barcodeFocusNode.dispose();
    _discountFocusNode.dispose();
    super.dispose();
  }

  void _updateTotalDiscount() {
    final chosenItems = ref.watch(narociloNotifierProvider);

    double totalDiscount = 0;

    for (var item in chosenItems) {
      double itemQuantity = item.quantity;
      double itemPrice = item.product.price;
      double itemDiscountedPrice = item.product.discountedPrice;

      double itemDiscountValue =
          (itemPrice - itemDiscountedPrice) * itemQuantity;
      if (itemDiscountedPrice > 0 && itemPrice > 0) {
        totalDiscount += itemDiscountValue;
      }
    }
    setState(() {
      _totalDiscount = totalDiscount;
    });
  }

  void _handleQuantityChange(double newQuantity, String productId,
      String description, double itemPrice, double oldQuantity) {
    //Change from int index to item ID
    ref.read(narociloNotifierProvider.notifier).updateQuantity(
        productId, description, newQuantity, itemPrice, oldQuantity);
    _updateTotalDiscount();
    print("TUKI PROBLEM 1");
  }

  void _removeItem(
      String productId, double price, String description, double quantity) {
    //Change from int index to item ID
    final currentItems = ref.read(narociloNotifierProvider);

    final itemToRemove = currentItems.firstWhere((element) =>
        element.product.id == productId &&
        element.product.price == price &&
        element.description == description &&
        element.quantity == quantity);

    if (itemToRemove != null) {
      ref.read(narociloNotifierProvider.notifier).removeFromRacun(itemToRemove);
      _updateTotalDiscount();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ne morem izbrisati izdelka")),
      );
    }
  }

  void _clearText() {
    discountController.clear();
  }

  void _submit(String? productId, String itemDescription, double itemPrice,
      bool isFinalDiscount,
      [double? discount]) {
    final chosenItems = ref.read(narociloNotifierProvider);

    if (isFinalDiscount) {
      double finalDiscountPercentage = (discount ?? 0) / 100;

      setState(() {
        for (var item in chosenItems) {
          double itemPrice = double.tryParse(
                  item.product.price.toString().replaceAll(',', '.')) ??
              0;
          double discountedPrice = itemPrice * (1 - finalDiscountPercentage);

          ref.read(narociloNotifierProvider.notifier).updateDiscount(
              item.product.id,
              item.description,
              item.product.price,
              discountedPrice,
              discount ?? 0);
        }
        _updateTotalDiscount();
      });
      return;
    }

    // Popravljen del: iteracija čez vse izdelke, ne le prvi
    if (productId != null) {
      double itemDiscount = (discount ?? 0) / 100;

      var itemsToUpdate = chosenItems
          .where((item) =>
              item.product.id == productId &&
              item.description == itemDescription &&
              item.product.price == itemPrice)
          .toList();

      for (var item in itemsToUpdate) {
        double itemPrice = double.tryParse(
                item.product.price.toString().replaceAll(',', '.')) ??
            0;
        double discountedPrice = itemPrice * (1 - itemDiscount);

        ref.read(narociloNotifierProvider.notifier).updateDiscount(
            item.product.id,
            item.description,
            item.product.price,
            discountedPrice,
            discount ?? 0);
      }

      _updateTotalDiscount();
    }
  }

  Future openDialog(String? productId, String itemDescription, double itemPrice,
      bool isFinalDiscount,
      [double? discount]) {
    final chosenItems = ref.read(narociloNotifierProvider);
    discountController.clear();

    _barcodeFocusNode.unfocus();

    FocusScope.of(context).unfocus();

    if (productId != null && !isFinalDiscount) {
      var item = chosenItems.firstWhere((element) =>
          element.product.id == productId &&
          element.description == itemDescription &&
          element.product.price == itemPrice);
      double originalPrice =
          double.tryParse(item.product.price.toString().replaceAll(',', '.')) ??
              0;
      double discountedPrice = item.product.discountedPrice;

      if (discountedPrice > 0 && originalPrice > 0) {
        double discountPercentage =
            100 - ((discountedPrice / originalPrice) * 100);
        discountController.text = discountPercentage.toStringAsFixed(0);
      }
    } else if (isFinalDiscount && discount != null) {
      discountController.text = discount.toString();
    }

    setState(() {
      _isDiscountDialogOpen = true;
    });

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppStyles.white,
          title: const Text(
            "Popust",
            textAlign: TextAlign.center,
            style: AppStyles.heading2,
          ),
          content: TextField(
            focusNode: _discountFocusNode,
            controller: discountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppStyles.silver.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearText,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.vibrate();

                _submit(productId, itemDescription, itemPrice, isFinalDiscount,
                    double.tryParse(discountController.text));
                SystemChrome.setEnabledSystemUIMode(
                    SystemUiMode.immersiveSticky);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppStyles.blue),
              child: Text("OK",
                  style: AppStyles.button1.copyWith(color: AppStyles.white)),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    ).then((_) {
      setState(() {
        _isDiscountDialogOpen = false;
      });
      Future.delayed(Duration(milliseconds: 200), () {
        FocusScope.of(context).requestFocus(_barcodeFocusNode);
      });
    });
  }

  List<Item> matchingItems = [];

  void _searchByEan(String input) {
    // Take eanCode as an argument
    //String searchText = searchController.text.trim();  // No longer needed

    RegExp regExp = RegExp(r'\d+');
    Iterable<Match> matches = regExp.allMatches(input); // Use the argument
    List<String> numbers = matches.map((match) => match.group(0)!).toList();
    String numbersToString = numbers.join();
    final items = ref.watch(itemsProvider);

    if (numbersToString.length >= 6 && input.isNotEmpty) {
      // Use the argument
      matchingItems = items.where((item) {
        return item.eanCode == numbersToString;
      }).toList();

      if (matchingItems.isNotEmpty) {
        Item matchingItem = matchingItems.first;
        NarociloItem newNarociloItem = NarociloItem(product: matchingItem);

        ref
            .read(narociloNotifierProvider.notifier)
            .addToRacun(newNarociloItem, fromTable: false);

        _updateTotalDiscount();
        _isSearchMode = false;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ne najdem izdelka s to EAN kodo")),
        );
      }
    } else if (numbersToString.length <= 5 && input.isNotEmpty) {
      matchingItems = items.where((item) {
        return int.tryParse(item.id) == int.tryParse(numbersToString);
      }).toList();

      if (matchingItems.isNotEmpty) {
        Item matchingItem = matchingItems.first;
        NarociloItem newNarociloItem = NarociloItem(product: matchingItem);

        ref
            .read(narociloNotifierProvider.notifier)
            .addToRacun(newNarociloItem, fromTable: false);
        _updateTotalDiscount();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ne najdem izdelka s tem IDjem")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ne najdem izdelka")),
      );
    }
  }

  void _checkAndSetSearchMode() {
    String searchText = searchController.text.trim();
    _isSearchMode =
        searchText.isNotEmpty; // Set to true if there is text in search
  }

  @override
  Widget build(BuildContext context) {
    final chosenItems = ref.watch(narociloNotifierProvider);
    final totalSum = ref.watch(narociloNotifierProvider.notifier).totalSum();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppStyles.white,
      appBar: AppBar(
        backgroundColor: AppStyles.white,
        automaticallyImplyLeading: false,
        title: Text("Račun",
            style: AppStyles.heading3.copyWith(color: AppStyles.black)),
        centerTitle: true,
      ),
      body: KeyboardListener(
        // Replaced RawKeyboardListener with KeyboardListener
        focusNode: _barcodeFocusNode,
        onKeyEvent: (event) {
          // Changed onKey to onKeyEvent
          if (event.runtimeType == KeyDownEvent) {
            // Changed RawKeyDownEvent to KeyDownEvent
            if (event.physicalKey == PhysicalKeyboardKey.enter) {
              print('ENTER');
              // Process the scanned barcode here
              if (_scannedBarcode.isNotEmpty) {
                _searchByEan(
                    _scannedBarcode); //Search using the scanned barcode
                _scannedBarcode = ''; // Reset the scanned barcode
              }
            } else {
              print(
                  '_handleKeyEvent Event data keyLabel ${event.logicalKey.keyLabel}'); // Changed event.data.keyLabel to event.logicalKey.keyLabel
              _scannedBarcode += event.logicalKey.keyLabel ??
                  ""; //Add a null check as logicalKey.keyLabel can be null
            }

            print('scannedBarcode: $_scannedBarcode');
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: chosenItems.length,
                itemBuilder: (context, index) {
                  final item = chosenItems[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name,
                                      style: AppStyles.boldanparagraph1),
                                  Text(
                                    item.description != null
                                        ? item.description
                                        : '',
                                    style: AppStyles.paragraph4
                                        .copyWith(fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text('${item.product.price.toString()}€',
                                  style: AppStyles.heading3),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                  backgroundColor: AppStyles.blue),
                              onPressed: () {
                                HapticFeedback.vibrate();

                                FocusScope.of(context)
                                    .unfocus(); // Unfocus everything before navigation
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => EditItemScreen(
                                              itemName: item.product.name,
                                              itemCategory:
                                                  item.product.categoryID,
                                              itemPrice: item.product.price,
                                            )));
                              },
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                  backgroundColor: AppStyles.green),
                              onPressed: () {
                                HapticFeedback.vibrate();

                                openDialog(item.product.id, item.description,
                                    item.product.price, false);
                              },
                              icon: const Icon(Icons.percent),
                            ),
                            IconButton.filled(
                                style: IconButton.styleFrom(
                                    backgroundColor: AppStyles.brightRed),
                                onPressed: () {
                                  HapticFeedback.vibrate();
                                  _removeItem(
                                      item.product.id,
                                      item.product.price,
                                      item.description,
                                      item.quantity);
                                },
                                icon: const Icon(Icons.delete)),
                            const Spacer(),
                            QuantityIncrease(
                              quantity: item.quantity,
                              onQuantityChanged: (newQuantity) {
                                _handleQuantityChange(
                                    newQuantity,
                                    item.product.id,
                                    item.description,
                                    item.product.price,
                                    item.quantity);
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              color: AppStyles.silver.withOpacity(0.1),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          "Vrednost popusta: ",
                        ),
                        const Spacer(),
                        Text('${_totalDiscount.toStringAsFixed(2)} €')
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                    child: Row(
                      children: [
                        const Text("SKUPAJ:", style: AppStyles.heading4),
                        const Spacer(),
                        Text(
                          '${totalSum.toStringAsFixed(2)} €',
                          style: AppStyles.cardItemName.copyWith(
                              color: AppStyles.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Keyboard(
                        racunArtikliButton: "ARTIKLI",
                        opisDiscountButton: "%",
                        controller: searchController,
                        navigateToMizaScreen: _navigateToMizaScreen,
                        navigateToNacinPlacilaScreen: () {
                          _checkAndSetSearchMode(); // Update mode based on search text

                          if (_isSearchMode) {
                            // If in search mode, perform the EAN search using the text in the search box
                            _searchByEan(searchController.text);
                            searchController.clear();
                          } else {
                            // If in navigation mode, perform the navigation
                            _navigateToNacinPlacilaScreen();
                          }
                        },
                        navigateToOpisDiscountScreen: () =>
                            openDialog(null, itemOpis, itemPrice, true),
                        navigateToRacun: _navigateToBlagajnaScreen),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToMizaScreen() async {
    List<NarociloItem> currentChosenItems = ref.read(narociloNotifierProvider);

    if (currentChosenItems.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddToTableScreen(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OpenTablesScreen(),
        ),
      );
    }
  }

  void _navigateToNacinPlacilaScreen() async {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const NacinPlacilaScreen()));
  }

  void _navigateToBlagajnaScreen() async {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const BlagajnaScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}
