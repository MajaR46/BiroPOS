import 'package:biro_pos/components/blagajna_banner.dart';
import 'package:biro_pos/components/item_card.dart';
import 'package:biro_pos/components/keyboard.dart';
import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:biro_pos/screens/mize/add_to_table_screen.dart';
import 'package:biro_pos/screens/mize/open_tables_screen.dart';
import 'package:biro_pos/screens/nacin_placila_screen.dart';
import 'package:biro_pos/screens/racun_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:biro_pos/components/drawer.dart';
import 'package:biro_pos/app_styles.dart';

enum ResponseCategory { izdelki, dodatki }

abstract class ResponseItem {
  final String ime;
  final ResponseCategory kategorija;

  ResponseItem(this.ime, this.kategorija);

  @override
  String toString() {
    return ime;
  }
}

class Izdelek extends ResponseItem {
  final String izdelekID;
  final String cena;
  final String kategorijaID;

  Izdelek(String ime, this.cena, this.izdelekID, this.kategorijaID)
      : super(ime, ResponseCategory.izdelki);
}

class BlagajnaScreen extends StatefulWidget {
  const BlagajnaScreen({super.key});

  @override
  State<BlagajnaScreen> createState() => _BlagajnaScreenState();
}

class _BlagajnaScreenState extends State<BlagajnaScreen> {
  final DateTime currentDate = DateTime.now();
  //late List<dynamic> cafeItems;
  bool isLoading = true;
  bool hasError = false;
  Map<String, List<dynamic>> categorizedItems = {};
  String selectedCategory = "Vse";
  final TextEditingController searchController = TextEditingController();
  dynamic selectedItem;
  double itemQuantity = 1;
  double sum = 0;
  double finalSum = 0;
  double discount = 0;
  late List<dynamic> chosenItems = [];
  List<Izdelek> izdelki = [];

  @override
  void initState() {
    super.initState();
    _handleData();
    searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _handleData() async {
    List<String> apiResponseList = await sendRequest("1", "BiroPOS.txt");

    Map<String, String> itemToCategoryMap = {};

    for (String line in apiResponseList) {
      if (line.startsWith('T')) {
        List<String> parts = line.split('|');
        if (parts.length >= 3) {
          String categoryName = parts[1];
          String itemId = parts[2];
          itemToCategoryMap[itemId] = categoryName;
        }
      }
    }

    _categorizeResponseItems(apiResponseList, itemToCategoryMap);
  }

  void _categorizeResponseItems(
      List<String> items, Map<String, String> itemToCategoryMap) {
    List<Izdelek> izdelki2 = [];
    Map<String, List<dynamic>> categorized = {};

    for (String item in items) {
      if (item.startsWith('1')) {
        // Parse the item details
        String izdelekId = item.split('|')[1];
        String imeIzdelka = item.split('|')[2];
        String cena = item.split('|')[3];
        String kategorijaID =
            item.split('|')[5]; // Ensure categoryID is assigned

        Izdelek newIzdelek = Izdelek(imeIzdelka, cena, izdelekId, kategorijaID);

        String? categoryName = itemToCategoryMap[izdelekId] ?? 'Ostalo';
        izdelki2.add(newIzdelek);

        if (categorized.containsKey(categoryName)) {
          categorized[categoryName]!.add({
            'name': imeIzdelka,
            'price': cena,
            'category': categoryName,
            'itemId': izdelekId,
            'categoryID': kategorijaID // Ensure categoryID is included
          });
        } else {
          categorized[categoryName] = [
            {
              'name': imeIzdelka,
              'price': cena,
              'category': categoryName,
              'itemId': izdelekId,
              'categoryID': kategorijaID // Ensure categoryID is included
            }
          ];
        }
      }
    }

    setState(() {
      izdelki = izdelki2;
      categorizedItems = categorized;
      isLoading = false;
    });
  }

  void _ouputselectedItem(dynamic outputtedItem) {
    if (outputtedItem['categoryID'] == null) {
      print("Error: categoryID is missing for the selected item.");
    } else {
      print("kategorija; ${outputtedItem['categoryID']}");
    }
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
        chosenItems.add({
          'name': outputtedItem['name'],
          'price': outputtedItem['price'],
          'quantity': itemQuantity,
          'itemId': outputtedItem['itemId'],
          'category': outputtedItem['category'],
          'categoryID':
              outputtedItem['categoryID'] // Ensure categoryID is added here
        });
      }

      selectedItem = outputtedItem;
      _updateFinalSum();
    });
    print("kategorija; ${outputtedItem['categoryID']}");
  }

  void _updateFinalSum() {
    double newFinalSum = 0;

    for (var item in chosenItems) {
      double price =
          double.tryParse(item['price'].toString().replaceAll(',', '.')) ?? 0;
      double quantity = item['quantity'] is num
          ? item['quantity']
          : double.tryParse(item['quantity'].toString()) ?? 0;

      double itemTotal = quantity * price;
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

  /*  Future<void> loadCafeItems() async {
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
  } */

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

    // Filter by category
    if (selectedCategory == "Vse") {
      // Combine all items if "Vse" (All) is selected
      for (var categoryItems in categorizedItems.values) {
        filteredItems.addAll(categoryItems);
      }
    } else {
      // Get items for the selected category
      filteredItems = categorizedItems[selectedCategory] ?? [];
    }

    // Filter by search query
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
                          onTap: () => _ouputselectedItem({
                            'name': item['name'],
                            'price': item['price'],
                            'category': item['category'],
                            'itemId': item['itemId'],
                            'categoryID': item['categoryID']
                          }),
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
    print("chosen items: $chosenItems");

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
            selectedItem: selectedItem,
            itemQuantity: itemQuantity,
            chosenItems: chosenItems,
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
