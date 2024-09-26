import 'dart:convert';
import 'package:biro_pos/components/blagajna_banner.dart';
import 'package:biro_pos/components/item_card.dart';
import 'package:biro_pos/components/keyboard.dart';
import 'package:biro_pos/screens/mize/add_to_table_screen.dart';
import 'package:biro_pos/screens/mize/open_tables_screen.dart';
import 'package:biro_pos/screens/nacin_placila_screen.dart';
import 'package:biro_pos/screens/racun_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:biro_pos/components/drawer.dart';
import 'package:biro_pos/app_styles.dart';

class BlagajnaScreen extends StatefulWidget {
  const BlagajnaScreen({super.key});

  @override
  State<BlagajnaScreen> createState() => _BlagajnaScreenState();
}

class _BlagajnaScreenState extends State<BlagajnaScreen> {
  final DateTime currentDate = DateTime.now();
  late List<dynamic> cafeItems;
  bool isLoading = true;
  bool hasError = false;
  Map<String, List<dynamic>> categorizedItems = {};
  String selectedCategory = "Vse";
  final TextEditingController searchController = TextEditingController();
  dynamic selectedItem;
  double itemQuantity = 1;
  double sum = 0;
  double finalSum = 0;
  late List<dynamic> chosenItems = [];

  @override
  void initState() {
    super.initState();
    loadCafeItems();
    searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _ouputselectedItem(dynamic outputtedItem) {
    setState(() {
      itemQuantity = 1;

      bool itemExists = false;

      // Check if the item is already in the list
      for (var item in chosenItems) {
        if (item['name'] == outputtedItem['name']) {
          // Item already exists, update its quantity
          itemExists = true;
          item['quantity'] = itemQuantity;
          break;
        }
      }

      if (!itemExists) {
        // New item, add it to the list with default quantity 1
        chosenItems.add({
          'name': outputtedItem['name'],
          'price': outputtedItem['price'],
          'quantity': itemQuantity,
        });
      }

      selectedItem = outputtedItem;
      _updateFinalSum();
    });
  }

  void _updateFinalSum() {
    double newFinalSum = 0;

    for (var item in chosenItems) {
      double itemTotal = item['quantity'] * (item['price'] ?? 0);
      newFinalSum += itemTotal;
    }

    setState(() {
      finalSum = newFinalSum;
    });
  }

  void _handleMultiply(double result) {
    setState(() {
      itemQuantity = result;

      if (selectedItem != null) {
        for (var item in chosenItems) {
          if (item['name'] == selectedItem['name']) {
            item['quantity'] = itemQuantity;
            break;
          }
        }
        _updateFinalSum();
      }
    });
  }

  List<Color> backgroundColors = [
    AppStyles.lightBrown,
    AppStyles.lightOrange,
    AppStyles.lightGreen,
    AppStyles.lightBlue,
    AppStyles.lightPurple
  ];

  List<Color> textColors = [
    AppStyles.darkBrown,
    AppStyles.darkOrange,
    AppStyles.darkGreen,
    AppStyles.darkBlue,
    AppStyles.darkPurple
  ];

  Future<void> loadCafeItems() async {
    try {
      String jsonString = await rootBundle.loadString('assets/cafe_items.json');
      List<dynamic> items = jsonDecode(jsonString);
      setState(() {
        cafeItems = items;
        categorizedItems = _categorizeItems(items);
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Map<String, List<dynamic>> _categorizeItems(List<dynamic> items) {
    Map<String, List<dynamic>> categories = {};
    for (var item in items) {
      String category = item['category'];
      if (categories.containsKey(category)) {
        categories[category]!.add(item);
      } else {
        categories[category] = [item];
      }
    }
    return categories;
  }

//filtriraj izdelke glede na kategorijo
  List<dynamic> _getFilteredItems() {
    List<dynamic> filteredItems = [];

    // filtriraj po kategoriji
    if (selectedCategory == "Vse") {
      filteredItems = cafeItems;
    } else {
      filteredItems = categorizedItems[selectedCategory] ?? [];
    }

    //filtriraj po searchu
    String searchQuery = searchController.text.toUpperCase();

    searchQuery = searchQuery.replaceAll(RegExp(r'\d'), '');

    if (searchQuery.isNotEmpty) {
      filteredItems = filteredItems.where((item) {
        String itemName =
            item['name'].toUpperCase().replaceAll(RegExp(r'\d'), '');
        return itemName.startsWith(searchQuery);
      }).toList();
    }

    return filteredItems;
  }

//category list na vrhu zaslona
  Widget _categoryList() {
    List<String> categories = ["Vse"] + categorizedItems.keys.toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: ((context, index) {
            String category = categories[index];

            int categoryIndex =
                categorizedItems.keys.toList().indexOf(category);

            Color assignedBackgroundColor =
                backgroundColors[categoryIndex % backgroundColors.length];
            Color assignedTextColor =
                textColors[categoryIndex % textColors.length];

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = category;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: assignedBackgroundColor,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        category,
                        style: AppStyles.button2
                            .copyWith(color: assignedTextColor),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

//glavni seznam izdelkov
  Widget _buildItemList() {
    List<dynamic> filteredItems = _getFilteredItems();

    if (filteredItems.isEmpty) {
      return const Center(child: Text("No items available"));
    }

    // GLavni layout
    if (selectedCategory == "Vse") {
      Map<String, List<dynamic>> itemsByCategory =
          _categorizeItems(filteredItems);
      List<String> categories = itemsByCategory.keys.toList();

      return SizedBox(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: ((context, index) {
            String category = categories[index];
            List<dynamic> items = itemsByCategory[category] ?? [];

            return SizedBox(
              width: 180,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, itemIndex) {
                        final item = items[itemIndex];

                        int categoryIndex = categorizedItems.keys
                            .toList()
                            .indexOf(item['category']);

                        if (categoryIndex == -1) {
                          categoryIndex = 0; // Fallback to the default color
                        }
                        Color assignedBackgroundColor = backgroundColors[
                            categoryIndex % backgroundColors.length];
                        Color assignedTextColor =
                            textColors[categoryIndex % textColors.length];

                        return GestureDetector(
                          onTap: () => _ouputselectedItem(item),
                          child: ItemCard(
                            itemName: item['name'],
                            itemPrice: item['price'],
                            itemCategory: item['category'],
                            backgroundColor: assignedBackgroundColor,
                            textColor: assignedTextColor,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      );
    } else {
      // Layout za posamezno kategorijo
      return ListView.builder(
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          int categoryIndex =
              categorizedItems.keys.toList().indexOf(item['category']);
          Color assignedBackgroundColor =
              backgroundColors[categoryIndex % backgroundColors.length];
          Color assignedTextColor =
              textColors[categoryIndex % textColors.length];

          return GestureDetector(
            onTap: () => _ouputselectedItem(item),
            child: ItemCard(
              itemName: item['name'],
              itemPrice: item['price'],
              itemCategory: item['category'],
              backgroundColor: assignedBackgroundColor,
              textColor: assignedTextColor,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat("EEE, dd. MMM yyyy").format(currentDate);
    String formattedTime = DateFormat("HH:mm").format(currentDate);

    return Scaffold(
      backgroundColor: AppStyles.grey,
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 32.0,
        backgroundColor: AppStyles.white,
        iconTheme: const IconThemeData(color: AppStyles.blue),
        title: Text(
          formattedDate,
          style: AppStyles.paragraph3
              .copyWith(color: AppStyles.blue, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text(
              formattedTime,
              style: AppStyles.paragraph3
                  .copyWith(color: AppStyles.blue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(child: Text('Failed to load data'))
              : Column(
                  children: [
                    _categoryList(),
                    Expanded(
                      child: _buildItemList(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: BlagajnaBanner(
                          chosenItem: selectedItem != null
                              ? selectedItem['name'] ?? ''
                              : ' ',
                          quantity: itemQuantity,
                          sum: finalSum),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Keyboard(
                          navigateToRacun: _navigateToRacunScreen,
                          navigateToMizaScreen: _navigateToMizaScreen,
                          navigateToNacinPlacilaScreen:
                              _navigateToNacinPlacilaScreen,
                          selectedItem: selectedItem,
                          chosenItems: chosenItems,
                          finalSum: finalSum,
                          controller: searchController,
                          multiply: _handleMultiply,
                          quantity: itemQuantity),
                    ),
                  ],
                ),
    );
  }

  /////////////////////////////////////////////////////////////////// NAVIGATE FUNCTIONS ////////////////////////////////////////////////////
  void _navigateToRacunScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RacunScreen(
          selectedItem: selectedItem,
          itemQuantity: itemQuantity,
          finalSum: finalSum,
          chosenItems: chosenItems,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        List<double> updatedQuantities =
            List<double>.from(result['updatedQuantity']);
        finalSum = result['updatedFinalSum'];

        for (int i = 0; i < chosenItems.length; i++) {
          chosenItems[i]['quantity'] = updatedQuantities[i];
        }
      });
    }
  }

  void _navigateToMizaScreen() async {
    if (chosenItems.isNotEmpty) {
      double currentFinalSum = finalSum;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddToTableScreen(
            finalSum: currentFinalSum,
          ),
        ),
      ).then((_) {
        setState(() {
          chosenItems.clear();
          finalSum = 0.0;
          selectedItem = null;
        });
      });
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
    final result = Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => NacinPlacilaScreen(finalSum: finalSum)));
  }
}
