import 'package:biro_pos/components/blagajna_banner.dart';
import 'package:biro_pos/components/item_card.dart';
import 'package:biro_pos/components/keyboard.dart';
import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/models/item.dart';
import 'package:biro_pos/models/narociloitem.dart';
import 'package:biro_pos/providers/direct_payment_provider.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/screens/edit_item_screen.dart';
import 'package:biro_pos/screens/mize/add_to_table_screen.dart';
import 'package:biro_pos/screens/mize/open_tables_screen.dart';
import 'package:biro_pos/screens/nacin_placila_screen.dart';
import 'package:biro_pos/screens/racun_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:biro_pos/components/drawer.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlagajnaScreen extends ConsumerStatefulWidget {
  const BlagajnaScreen({super.key});

  @override
  ConsumerState<BlagajnaScreen> createState() => _BlagajnaScreenState();
}

class _BlagajnaScreenState extends ConsumerState<BlagajnaScreen> {
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
  late List<NarociloItem> chosenItems = [];
  List<Item> izdelki = [];
  late OrderService orderService;

  @override
  void initState() {
    super.initState();

    _handleData();
    searchController.addListener(() {
      setState(() {});
    });

    Future.microtask(() {
      final orderService = ref.read(orderProvider);
      orderService.initializePaymentMethods();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update the final sum and total discount when the dependencies change
    _updateFinalSum();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _showResponseDialog(List<String> response) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Server Response"),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(response.join('\n')), // Display the response line by line
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(narociloNotifierProvider.notifier).clearChosenItems();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Check if 'biropos_data' is present
      List<String> apiResponseList = prefs.getStringList('biropos_data') ?? [];

      if (apiResponseList == null) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        print("No data found in SharedPreferences for 'biropos_data'");
        return;
      }

      print(
          "Data retrieved from SharedPreferences: ${apiResponseList.length} items");

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
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      print("Error loading data: $e");
    }
  }

  void _categorizeResponseItems(
      List<String> items, Map<String, String> itemToCategoryMap) {
    List<Item> izdelki2 = [];
    Map<String, List<dynamic>> categorized = {};

    for (String item in items) {
      if (item.startsWith('1')) {
        List<String> parts = item.split('|');

        // Ensure the item has all expected fields to avoid out-of-range issues
        if (parts.length < 7) continue;

        // Parse the item details safely
        String izdelekId = parts[1];
        String imeIzdelka = parts[2];
        String? cenaString = parts[3];
        String? hhCenaString = parts[4];
        String kategorijaID = parts[5];
        String eancode = parts[6];

        // Safely parse prices, defaulting to 0.0 if parsing fails
        double? cena = double.tryParse(cenaString) ?? 0.0;
        double? hhCena = double.tryParse(hhCenaString) ?? 0.0;

        Item newIzdelek = Item(
          id: izdelekId,
          name: imeIzdelka,
          price: cena,
          discountedPrice: 0.0,
          HHprice: hhCena,
          categoryID: kategorijaID,
          eanCode: eancode,
        );

        String? categoryName = itemToCategoryMap[izdelekId] ?? 'Ostalo';
        izdelki2.add(newIzdelek);

        // Check if category already exists in the map
        if (categorized.containsKey(categoryName)) {
          categorized[categoryName]!.add({
            'name': imeIzdelka,
            'price': cenaString,
            'category': categoryName,
            'itemId': izdelekId,
            'categoryID': kategorijaID,
          });
        } else {
          categorized[categoryName] = [
            {
              'name': imeIzdelka,
              'price': cenaString,
              'category': categoryName,
              'itemId': izdelekId,
              'categoryID': kategorijaID,
            }
          ];
        }
      }
    }

    // Update state
    setState(() {
      izdelki = izdelki2;
      categorizedItems = categorized;
      isLoading = false;
    });
  }

  void _ouputselectedItem(dynamic outputtedItem) {
    setState(() {
      itemQuantity = 1;

      bool itemExists = false;

      Item newItem = Item.fromMap(outputtedItem);
      NarociloItem newNarociloItem = NarociloItem(product: newItem);

      if (!itemExists) {
        ref
            .read(narociloNotifierProvider.notifier)
            .addToRacun(newNarociloItem, fromTable: false);
        print("Added item to the bill: ${newNarociloItem.product.name}");
        print("Added item to the bill: ${newNarociloItem.product.price}");
      }

      selectedItem = outputtedItem;
      print("Selected item: $selectedItem");
      print("Selected item name: ${selectedItem['name']}");

      _updateFinalSum();
    });
  }

  void _updateFinalSum() {
    final newSum = ref.read(narociloNotifierProvider.notifier).totalSum();
    setState(() {
      finalSum = newSum;
    });
  }

  void _handleMultiply(double factor) {
    print("Multiplication factor received: $factor");

    if (selectedItem != null) {
      final newQuantity = itemQuantity * factor;
      setState(() {
        itemQuantity = newQuantity;
      });

      // Update the quantity in the provider
      ref
          .read(narociloNotifierProvider.notifier)
          .updateQuantity(selectedItem['itemId'], newQuantity);

      // Update the final sum based on the new quantity
      _updateFinalSum();
    }
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
    final paymentMethods = ref.watch(paymentMethodProvider);
    orderService = ref.read(orderProvider);

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
                        navigateToRacun: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RacunScreen()),
                          ).then((_) {
                            _updateFinalSum(); // Update final sum on return
                          });
                        },
                        navigateToMizaScreen: _navigateToMizaScreen,
                        navigateToNacinPlacilaScreen:
                            _navigateToNacinPlacilaScreen,
                        selectedItem: selectedItem,
                        chosenItems: chosenItems,
                        finalSum: finalSum,
                        controller: searchController,
                        multiply: _handleMultiply,
                        quantity: itemQuantity,
                        navigateToOpisScreen: _navigateToOpisScreen,
                        paymentGotovina: () async {
                          if (paymentMethods.isNotEmpty) {
                            final response = await orderService.createOrder(
                              context,
                              "GOT",
                            );
                            _showResponseDialog(response);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("No payment methods available!")),
                            );
                          }
                        },
                        paymentKartica: () async {
                          if (paymentMethods.isNotEmpty) {
                            final response = await orderService.createOrder(
                              context,
                              "KAR",
                            );
                            _showResponseDialog(response);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("No payment methods available!")),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  /////////////////////////////////////////////////////////////////// NAVIGATE FUNCTIONS ////////////////////////////////////////////////////

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
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => NacinPlacilaScreen()));
  }

  void _navigateToOpisScreen() async {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                EditItemScreen(itemName: selectedItem['name'])));
  }
}
