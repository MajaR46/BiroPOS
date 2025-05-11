import 'package:BiroPOS/utils/id_ean_search.dart';
import 'package:BiroPOS/components/keyboard.dart';
import 'package:BiroPOS/components/quantity_increase.dart';
import 'package:BiroPOS/components/racun_list_banner.dart';
import 'package:BiroPOS/components/seznam_racun.dart';
import 'package:BiroPOS/controllers/table_controller.dart';
import 'package:BiroPOS/models/item.dart';
import 'package:BiroPOS/models/nacinPlacila.dart';
import 'package:BiroPOS/models/narociloitem.dart';
import 'package:BiroPOS/providers/categoriseditems_provider.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/direct_payment_provider.dart';
import 'package:BiroPOS/providers/searchquery_provider.dart';
import 'package:BiroPOS/providers/totdal_sum_provider.dart';
import 'package:BiroPOS/screens/blagajna_screen.dart';
import 'package:BiroPOS/screens/edit_item_screen.dart';
import 'package:BiroPOS/screens/mize/add_to_table_screen.dart';
import 'package:BiroPOS/screens/mize/open_tables_screen.dart';
import 'package:BiroPOS/screens/mize/prostori_screen.dart';
import 'package:BiroPOS/screens/nacin_placila_screen.dart';
import 'package:flutter/material.dart';
import 'package:BiroPOS/app_styles.dart';
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
  List<Map<String, String>> _tables = [];

  String itemOpis = '';
  double itemPrice = 0.0;
  late OrderService orderService;
  final TextEditingController searchController = TextEditingController();
  bool _isSearchMode = false;
  bool _isKeyboardListenerEnabled = false;
  bool _tablesFetched = false;

  // NEW: Barcode scanner implementation
  final FocusNode _barcodeFocusNode = FocusNode();
  final FocusNode _discountFocusNode = FocusNode();
  String _scannedBarcode = '';
  bool _isDiscountDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _fetchTables();
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

  void _handleQuantityChange(
      String uniqueId,
      String productId,
      String description,
      double newQuantity,
      double itemPrice,
      double oldQuantity) {
    //Change from int index to item ID
    ref.read(narociloNotifierProvider.notifier).updateQuantity(
        uniqueId, productId, description, newQuantity, itemPrice, oldQuantity);

    _updateTotalDiscount();
  }

  Future<void> _fetchTables() async {
    if (_tablesFetched) return;

    _tablesFetched = true;

    try {
      List<Map<String, String>> tables = await TableService.fetchTables();
      setState(() {
        _tables = tables;
      });
    } catch (e) {
      print("Napaka pri pridobivanju tabel: $e");
      // Lahko dodaš logiko za napako, če želiš
    }
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

          ref
              .read(narociloNotifierProvider.notifier)
              .updateDiscount(item.uniqueId, discountedPrice, discount ?? 0);
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

        ref
            .read(narociloNotifierProvider.notifier)
            .updateDiscount(item.uniqueId, discountedPrice, discount ?? 0);
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
    searchByEan(input, ref, context, _updateTotalDiscount);
  }

  void _checkAndSetSearchMode() {
    String searchText = searchController.text.trim();
    _isSearchMode = checkAndSetSearchMode(
        searchText); // Use the function from search_ean.dart
  }

  @override
  Widget build(BuildContext context) {
    final chosenItems = ref.watch(narociloNotifierProvider);
    final totalSum = ref.watch(narociloNotifierProvider.notifier).totalSum();

    final numbers2String = ref.watch(searchQueryProvider);

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
          children: [
            Expanded(
              child: SeznamRacun(
                  chosenItems: chosenItems,
                  totalSum: totalSum,
                  totalDiscount: _totalDiscount,
                  openDialog: openDialog,
                  removeItem: _removeItem,
                  handleQuantityChange: _handleQuantityChange),
            ),
            RacunListBanner(
              totalDiscount: _totalDiscount,
              totalSum: totalSum,
              controller: searchController,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Keyboard(
                  search: () {},
                  icon: Icons.arrow_back,
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
    );
  }

  void _navigateToMizaScreen() async {
    List<NarociloItem> currentChosenItems = ref.read(narociloNotifierProvider);
    final table = _tables.firstWhere(
      (table) => table['prostor'] != '',
      orElse: () => {},
    );
    if (currentChosenItems.isNotEmpty) {
      if (table['prostor'] == null ||
          table['prostor']!.isEmpty && table['prostor'] != 'Miza') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AddToTableScreen()),
        );
      } else {
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
