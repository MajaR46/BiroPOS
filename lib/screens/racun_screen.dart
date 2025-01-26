import 'package:biro_pos/components/keyboard.dart';
import 'package:biro_pos/components/quantity_increase.dart';
import 'package:biro_pos/models/item.dart';
import 'package:biro_pos/models/nacinPlacila.dart';
import 'package:biro_pos/models/narociloitem.dart';
import 'package:biro_pos/providers/categoriseditems_provider.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/providers/direct_payment_provider.dart';
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
  late double finalSum = 0.0;
  double _totalDiscount = 0.0;
  late List<NarociloItem> chosenItems = [];
  final TextEditingController discountController = TextEditingController();
  List<NacinPlacila> naciniPlacila = [];
  String itemOpis = '';
  late OrderService orderService;
  final TextEditingController searchController = TextEditingController();
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final orderService = ref.read(orderProvider);
      orderService.initializePaymentMethods();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateFinalSum();
  }

  void _updateFinalSum() {
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
      finalSum = ref.watch(narociloNotifierProvider.notifier).totalSum();
      _totalDiscount = totalDiscount;
    });
  }

  void _handleQuantityChange(double newQuantity, String productId) {
    //Change from int index to item ID
    ref
        .read(narociloNotifierProvider.notifier)
        .updateQuantity(productId, newQuantity);
    _updateFinalSum();
  }

  void _removeItem(String productId) {
    //Change from int index to item ID
    final currentItems = ref.read(narociloNotifierProvider);

    final itemToRemove =
        currentItems.firstWhere((element) => element.product.id == productId);

    if (itemToRemove != null) {
      ref.read(narociloNotifierProvider.notifier).removeFromRacun(itemToRemove);
      _updateFinalSum();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ne morem izbrisati izdelka")),
      );
    }
  }

  void _clearText() {
    discountController.clear();
  }

  void _submit(String? productId, bool isFinalDiscount, [double? discount]) {
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
              .updateDiscount(item.product.id, discountedPrice, discount ?? 0);
        }
        _updateFinalSum();
      });
      return;
    }

    // Handle item-specific discount
    if (productId != null) {
      double itemDiscount = (discount ?? 0) / 100;

      var item = chosenItems.firstWhere((item) => item.product.id == productId);
      double itemPrice =
          double.tryParse(item.product.price.toString().replaceAll(',', '.')) ??
              0;

      double discountedPirce = itemPrice * (1 - itemDiscount);

      ref
          .read(narociloNotifierProvider.notifier)
          .updateDiscount(item.product.id, discountedPirce, discount ?? 0);
      _updateFinalSum();
    }
  }

  Future openDialog(String? productId, bool isFinalDiscount,
      [double? discount]) {
    final chosenItems = ref.read(narociloNotifierProvider);
    discountController.clear(); // Always start with a clear text field

    // If editing a discount for a specific item
    if (productId != null && !isFinalDiscount) {
      var item =
          chosenItems.firstWhere((element) => element.product.id == productId);

      // Ensure a valid discounted price before calculating the discount percentage
      double originalPrice =
          double.tryParse(item.product.price.toString().replaceAll(',', '.')) ??
              0;
      double discountedPrice = item.product.discountedPrice;

      if (discountedPrice > 0 && originalPrice > 0) {
        double discountPercentage =
            100 - ((discountedPrice / originalPrice) * 100);
        discountController.text = discountPercentage.toStringAsFixed(0);
      } else {
        // If discountedPrice is 0.0, treat it as no discount applied
        discountController.text = ""; // No preset discount
      }
    } else if (isFinalDiscount && discount != null) {
      // Only apply preset for specific final discount button selections
      discountController.text = discount.toString();
    } else {
      discountController.text = ""; // Ensure empty by default
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.white,
        title: const Text(
          textAlign: TextAlign.center,
          "Popust",
          style: AppStyles.heading2,
        ),
        content: TextField(
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
              _submit(productId, isFinalDiscount,
                  double.tryParse(discountController.text));
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.blue,
            ),
            child: Text("OK",
                style: AppStyles.button1.copyWith(color: AppStyles.white)),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  void _searchByEan() {
    String searchText = searchController.text.trim();

    RegExp regExp = RegExp(r'\d+');
    Iterable<Match> matches = regExp.allMatches(searchText);
    List<String> numbers = matches.map((match) => match.group(0)!).toList();
    String numbersToString = numbers.join();
    if (numbersToString.length >= 6 && searchText.isNotEmpty) {
      final items = ref.watch(itemsProvider);

      final matchingItems = items.where((item) {
        return item.eanCode == numbersToString;
      }).toList();

      if (matchingItems.isNotEmpty) {
        Item matchingItem = matchingItems.first;
        NarociloItem newNarociloItem = NarociloItem(product: matchingItem);

        ref
            .read(narociloNotifierProvider.notifier)
            .addToRacun(newNarociloItem, fromTable: false);

        _updateFinalSum();
        _isSearchMode = false;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ne najdem izdelka s to EAN kodo")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("EAN koda je neveljavna")),
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

    return Scaffold(
      backgroundColor: AppStyles.white,
      appBar: AppBar(
        backgroundColor: AppStyles.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppStyles.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Račun",
            style: AppStyles.heading3.copyWith(color: AppStyles.black)),
        centerTitle: true,
      ),
      body: Column(
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
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => EditItemScreen(
                                            itemName: item.product.name,
                                            itemCategory:
                                                item.product.categoryID,
                                          )));
                            },
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                                backgroundColor: AppStyles.darkGreen),
                            onPressed: () {
                              openDialog(item.product.id, false);
                            },
                            icon: const Icon(Icons.percent),
                          ),
                          IconButton.filled(
                              style: IconButton.styleFrom(
                                  backgroundColor: AppStyles.red),
                              onPressed: () => _removeItem(item.product.id),
                              icon: const Icon(Icons.delete)),
                          const Spacer(),
                          QuantityIncrease(
                            quantity: item.quantity,
                            onQuantityChanged: (newQuantity) {
                              _handleQuantityChange(
                                  newQuantity, item.product.id);
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
                /*  Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                  child: Row(
                    children: [
                      Text(
                        "POPUST:",
                        style: AppStyles.heading3
                            .copyWith(fontWeight: FontWeight.normal),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          _submit(null, true, 5);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.white,
                          elevation: 1,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 40),
                        ),
                        child: Text("5%",
                            style: AppStyles.button1
                                .copyWith(color: AppStyles.black)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _submit(null, true, 10);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.white,
                          elevation: 1,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 40),
                        ),
                        child: Text("10%",
                            style: AppStyles.button1
                                .copyWith(color: AppStyles.black)),
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _submit(null, true, 15);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.white,
                          elevation: 1,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 40),
                        ),
                        child: Text("15%",
                            style: AppStyles.button1
                                .copyWith(color: AppStyles.black)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          openDialog(null, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.white,
                          elevation: 1,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 40),
                        ),
                        child: Text("?%",
                            style: AppStyles.button1
                                .copyWith(color: AppStyles.black)),
                      ),
                      IconButton.filled(
                        iconSize: 24,
                        style: IconButton.styleFrom(
                            backgroundColor: AppStyles.red),
                        onPressed: () {
                          _submit(null, true, 0);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ), */
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
                        '${finalSum.toStringAsFixed(2)} €',
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
                      opisDiscountButton: "%",
                      controller: searchController,
                      navigateToMizaScreen: _navigateToMizaScreen,
                      navigateToNacinPlacilaScreen: () {
                        _checkAndSetSearchMode(); // Update mode based on search text

                        if (_isSearchMode) {
                          // If in search mode, perform the EAN search
                          _searchByEan();
                          searchController.clear();
                        } else {
                          // If in navigation mode, perform the navigation
                          _navigateToNacinPlacilaScreen();
                        }
                      },
                      navigateToOpisDiscountScreen: () =>
                          openDialog(null, true),
                      navigateToRacun: _navigateToBlagajnaScreen),
                )
                /* Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          if (paymentMethods.isNotEmpty) {
                            await orderService.createOrder(
                              context,
                              "GOT",
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("No payment methods available!")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.darkOrange,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(100, 50),
                        ),
                        child: Text(
                          "GOTOVINA",
                          style: AppStyles.button2
                              .copyWith(color: AppStyles.white),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (paymentMethods.isNotEmpty) {
                            // Trigger rebuild-safe operation using ref.watch() and async handling
                            final orderService = ref.watch(orderProvider);
                            try {
                              final response = await orderService.createOrder(
                                context,
                                "KAR",
                              );
                              _showResponseDialog(response);
                            } catch (e) {
                              print("Error in createOrder: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text("Failed to create order!")),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("No payment methods available!")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.red,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(100, 50),
                        ),
                        child: Text("KARTICA",
                            style: AppStyles.button2
                                .copyWith(color: AppStyles.white)),
                      ),
                      ElevatedButton(
                        onPressed: _navigateToNacinPlacilaScreen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.blue,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(100, 50),
                        ),
                        child: Text("OSTALO",
                            style: AppStyles.button2
                                .copyWith(color: AppStyles.white)),
                      ),
                    ],
                  ),
                ), */
              ],
            ),
          ),
        ],
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
