import 'package:BiroPOS/app_styles.dart';
import 'package:BiroPOS/components/category_list.dart';
import 'package:BiroPOS/components/item_list_builder.dart';
import 'package:BiroPOS/components/keyboard.dart';
import 'package:BiroPOS/components/racun_list_banner.dart';
import 'package:BiroPOS/components/seznam_racun.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/utils/error_dialog.dart';
import 'package:BiroPOS/utils/search_items.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LandscapeLayout extends ConsumerStatefulWidget {
  final Map<String, List<dynamic>> categorizedItems;
  final List<dynamic> Function() getFilteredItems;
  final String selectedCategory;
  final Function(dynamic) onSelectItem;
  final List<Color> backgroundColors;
  final WidgetRef ref;
  final void Function() navigateToMizaScreen;
  final void Function() navigateToOpis;
  final void Function() navigateToNacinPlacilaScreen;
  final void Function() searchByName;
  final int columnNum;
  final TextEditingController keyboardController;
  const LandscapeLayout(
      {super.key,
      required this.categorizedItems,
      required this.getFilteredItems,
      required this.selectedCategory,
      required this.onSelectItem,
      required this.backgroundColors,
      required this.columnNum,
      required this.ref,
      required this.navigateToMizaScreen,
      required this.navigateToOpis,
      required this.navigateToNacinPlacilaScreen,
      required this.searchByName,
      required this.keyboardController});

  @override
  ConsumerState<LandscapeLayout> createState() => _LandscapeLayoutState();
}

class _LandscapeLayoutState extends ConsumerState<LandscapeLayout> {
  // final TextEditingController _keyboardController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  bool _isDiscountDialogOpen = false;

  double _totalDiscount = 0.0;
  void _clearText() {
    discountController.clear();
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

  void _submit(String uniquId, String? productId, String itemDescription,
      double itemPrice, bool isFinalDiscount,
      [double? discount]) {
    final chosenItems = ref.read(narociloNotifierProvider);

    if (discount == null || discount <= 0 || discount >= 100) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Popust mora biti med 0 in 100")));
      return; // prekini, če ni veljavno
    }

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

      var itemsToUpdate =
          chosenItems.where((item) => item.uniqueId == uniquId).toList();

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

  Future openDialog(String? uniqueId, String? productId, String itemDescription,
      double itemPrice, bool isFinalDiscount,
      [double? discount]) {
    final chosenItems = ref.read(narociloNotifierProvider);
    discountController.clear();

    //_barcodeFocusNode.unfocus();

    FocusScope.of(context).unfocus();

    if (productId != null && !isFinalDiscount) {
      var item = chosenItems.firstWhere(
        (element) => element.uniqueId == uniqueId,
      );
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
            //focusNode: _discountFocusNode,
            controller: discountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppStyles.silver.withAlpha((0.1 * 255).round()),
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

                _submit(uniqueId ?? '', productId, itemDescription, itemPrice,
                    isFinalDiscount, double.tryParse(discountController.text));
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
      /*Future.delayed(Duration(milliseconds: 200), () {
        FocusScope.of(context).requestFocus(_barcodeFocusNode);
      });*/
    });
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
      ErrorDialogs.showBasicDialog("Ne morem izbrisati izdelka", context);
    }
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

  @override
  Widget build(BuildContext context) {
    final chosenItems = ref.watch(narociloNotifierProvider);
    final totalSum = ref.watch(narociloNotifierProvider.notifier).totalSum();

    return Scaffold(
      body: Row(
        children: <Widget>[
          Expanded(
              flex: 2,
              child: Container(
                color: AppStyles.white,
                child: Column(
                  children: [
                    CategoryList(
                        categorizedItems: widget.categorizedItems,
                        backgroundColors: widget.backgroundColors,
                        ref: widget.ref),
                    Expanded(
                        child: ItemListBuilder(
                            categorizedItems: widget.categorizedItems,
                            getFilteredItems: widget.getFilteredItems,
                            selectedCategory: widget.selectedCategory,
                            onSelectItem: widget.onSelectItem,
                            backgroundColors: widget.backgroundColors,
                            columnNum: widget.columnNum,
                            ref: widget.ref)),
                  ],
                ),
              )),
          Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(color: AppStyles.white, boxShadow: [
                  BoxShadow(
                    color: AppStyles.black.withAlpha((0.1 * 255).round()),
                    offset: const Offset(-4, 0), // Senčka na levi strani
                    blurRadius: 6,
                  ),
                ]),
                child: Column(children: [
                  Expanded(
                      child: SeznamRacun(
                          chosenItems: chosenItems,
                          totalSum: totalSum,
                          totalDiscount: _totalDiscount,
                          openDialog: openDialog,
                          removeItem: _removeItem,
                          handleQuantityChange: _handleQuantityChange)),
                  RacunListBanner(
                    totalDiscount: _totalDiscount,
                    totalSum: totalSum,
                    controller: widget.keyboardController,
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Keyboard(
                      search: () {
                        widget.searchByName(); // <== kličemo kot prej
                      },
                      controller: widget.keyboardController,
                      navigateToMizaScreen: widget.navigateToMizaScreen,
                      navigateToNacinPlacilaScreen:
                          widget.navigateToNacinPlacilaScreen,
                      navigateToOpisDiscountScreen: widget.navigateToOpis,
                      navigateToRacun: () =>
                          openDialog("", null, "", 0, true, 0),
                      opisDiscountButton: "OPIS",
                      racunArtikliButton: "%",
                      icon: Icons.search,
                    ),
                  ),
                ]),
              ))
        ],
      ),
    );
  }
}
