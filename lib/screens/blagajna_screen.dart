import 'package:biro_pos/components/blagajna_banner.dart';
import 'package:biro_pos/components/debouncer.dart';
import 'package:biro_pos/components/item_card.dart';
import 'package:biro_pos/components/item_list_builder.dart';
import 'package:biro_pos/components/keyboard.dart';
import 'package:biro_pos/components/search_items.dart';
import 'package:biro_pos/models/item.dart';
import 'package:biro_pos/models/narociloitem.dart';
import 'package:biro_pos/providers/categoriseditems_provider.dart';
import 'package:biro_pos/providers/direct_payment_provider.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/providers/searchquery_provider.dart';
import 'package:biro_pos/providers/selectedcategory_provider.dart';
import 'package:biro_pos/providers/selecteditem_provider.dart';
import 'package:biro_pos/providers/settings_provider.dart';
import 'package:biro_pos/screens/edit_item_screen.dart';
import 'package:biro_pos/screens/mize/add_to_table_screen.dart';
import 'package:biro_pos/screens/mize/open_tables_screen.dart';
import 'package:biro_pos/screens/nacin_placila_screen.dart';
import 'package:biro_pos/screens/racun_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:biro_pos/components/drawer.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:hive/hive.dart';

import 'package:flutter/material.dart';

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
  String selectedCategory = "";
  final TextEditingController searchController = TextEditingController();
  dynamic selectedItem;
  double itemQuantity = 1;
  double sum = 0;
  double finalSum = 0;
  double discount = 0;
  //Remove the chosenItems as the provider handles the order list
  //late List<NarociloItem> chosenItems = [];
  List<Item> izdelki = [];
  late OrderService orderService;
  late int stStolpcev = 1;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();

    _handleData();

    searchController.addListener(() {
      ref.read(isSearchingProvider.notifier).state =
          searchController.text.isNotEmpty;
      updateNumbersString(searchController, ref);
    });

    Future.microtask(() {
      final orderService = ref.watch(orderProvider);
      orderService.initializePaymentMethods();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateFinalSum();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _handleData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String columNums = prefs.getString('stStolpcev') ?? '';

      final box = Hive.box('biroposData');
      List<String> apiResponseList =
          List<String>.from(box.get('biroPosData', defaultValue: []));

      //List<String> apiResponseList = prefs.getStringList('biropos_data') ?? [];

      if (apiResponseList == null) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        return;
      } else {
        setState(() {
          stStolpcev = columNums.isNotEmpty ? int.tryParse(columNums) ?? 1 : 1;
        });
      }

      Map<String, Map<String, String>> itemToCategoryMap = {};

      for (String line in apiResponseList) {
        if (line.startsWith('T')) {
          List<String> parts = line.split('|');
          if (parts.length >= 4) {
            // Ensure there are at least 4 parts
            String categoryName = parts[1];
            String itemId = parts[2];
            String itemColor = parts[3].trim(); // Get the "G" part as itemColor
            itemToCategoryMap[itemId] = {
              'categoryName': categoryName,
              'itemColor': itemColor
            };
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
      List<String> items, Map<String, Map<String, String>> itemToCategoryMap) {
    List<Item> izdelki2 = [];
    Map<String, List<dynamic>> categorized = {};

    for (String item in items) {
      if (item.startsWith('1')) {
        List<String> parts = item.split('|');

        if (parts.length < 7) continue; // Skip malformed items

        String izdelekId = parts[1];
        String imeIzdelka = parts[2];
        String cenaString = parts[3];
        String hhCenaString = parts[4];
        String kategorijaID = parts[5];
        String eancode = parts[6];

        double? cena = parsePrice(cenaString);
        double? hhCena = parsePrice(hhCenaString);

        cena ??= 0.0;
        hhCena ??= 0.0;

        Item newIzdelek = Item(
          id: izdelekId,
          name: imeIzdelka,
          price: cena,
          discountedPrice: 0.0,
          hhPrice: hhCena,
          categoryID: kategorijaID,
          eanCode: eancode,
        );

        izdelki2.add(newIzdelek);

        String categoryName =
            itemToCategoryMap[izdelekId]?['categoryName'] ?? 'Ostalo';
        String itemColor = itemToCategoryMap[izdelekId]?['itemColor'] ?? 'G';
        if (categorized.containsKey(categoryName)) {
          categorized[categoryName]!.add({
            'name': imeIzdelka,
            'price': cenaString,
            'hhPrice': hhCenaString,
            'category': categoryName,
            'itemId': izdelekId,
            'categoryID': kategorijaID,
            'eanCode': eancode,
            'itemColor': itemColor
          });
        } else {
          categorized[categoryName] = [
            {
              'name': imeIzdelka,
              'price': cenaString,
              'hhPrice': hhCenaString,
              'category': categoryName,
              'itemId': izdelekId,
              'categoryID': kategorijaID,
              'eanCode': eancode,
              'itemColor': itemColor
            }
          ];
        }
      }
    }

    ref.read(itemsProvider.notifier).setItems(izdelki2);

    setState(() {
      izdelki = izdelki2;
      categorizedItems = categorized;
      isLoading = false;
    });
  }

  double? parsePrice(String priceString) {
    try {
      return double.tryParse(priceString.replaceAll(',', '.'));
    } catch (e) {
      return 0.0;
    }
  }

  void _ouputselectedItem(dynamic outputtedItem) {
    setState(() {
      Item originalItem = Item.fromMap(outputtedItem); // Create from the map
      Item newItem = originalItem.copyWith(); // <----  Create a copy here

      NarociloItem newNarociloItem =
          NarociloItem(product: newItem, quantity: 1); // Always create the item
      final currentItems = ref.watch(narociloNotifierProvider);

      final existingItemIndex = currentItems.indexWhere((item) =>
          item.product.id == newNarociloItem.product.id &&
          item.description == newNarociloItem.description);

      if (existingItemIndex != -1) {
        // Item already exists
        // Update quantity

        if (itemQuantity % 1 != 0) {
          print("PROBLEM");
        }
        ref
            .read(narociloNotifierProvider.notifier)
            .addToRacun(newNarociloItem, fromTable: false);

        final existingItem = currentItems[existingItemIndex];
        ref.read(selectedItemProvider.notifier).state = existingItem;
      } else {
        // Item doesn't exist yet
        //Add item to cart
        print("PROBLEM EEPR PROE PREO ");
        ref
            .read(narociloNotifierProvider.notifier)
            .addToRacun(newNarociloItem, fromTable: false);

        ref.read(selectedItemProvider.notifier).state = newNarociloItem;
      }

      _updateFinalSum();
      searchController.clear();
      numbers2String = '';
      isSearching = false;
    });
  }

  void _updateFinalSum() {
    final newSum = ref.read(narociloNotifierProvider.notifier).totalSum();
    setState(() {
      finalSum = newSum;
    });
  }

  List<Color> backgroundColors = [
    AppStyles.lightBlue,
    AppStyles.lightGreen,
    AppStyles.yellow,
    AppStyles.orange,
    AppStyles.red
  ];

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

  List<dynamic> _getFilteredItems() {
    final stateSelectedCategory = ref.watch(selectedCategoryProvider);
    String filtriranSearch =
        searchController.text.replaceAll(RegExp(r'[^0-9]'), '');
    print("filtriran search $filtriranSearch");

    searchController.addListener(() {
      // Sprememba: Preveri dolžino preden spremeniš kategorijo
      if (filtriranSearch.length == 2 && searchController.text.isNotEmpty) {
        if (ref.read(selectedCategoryProvider.notifier).state != 'Iskanje') {
          ref.read(selectedCategoryProvider.notifier).state = 'Iskanje';
          print("nastavjeno na iskanje");
        }
      } else {
        if (ref.read(selectedCategoryProvider.notifier).state == 'Iskanje') {
          ref.read(selectedCategoryProvider.notifier).state = 'Vse';
        }
      }
    });

    generatePairs(searchController);

    List<dynamic> filteredItems = [];

    if (stateSelectedCategory == "Vse" || stateSelectedCategory == "Iskanje") {
      for (var categoryItems in categorizedItems.values) {
        filteredItems.addAll(categoryItems);
      }
    } else {
      // Preverimo, da je izbrana kategorija veljavna, preden filtriramo izdelke
      filteredItems = categorizedItems[stateSelectedCategory] ?? [];
    }

    String searchText = searchController.text;
    RegExp regExp = RegExp(r'\d+');
    Iterable<Match> matches = regExp.allMatches(searchText);
    List<String> numbers2 = matches.map((match) => match.group(0)!).toList();
    String numbers2String = numbers2.join();

    // Preverimo dolžino iskalnega besedila pred filtrom po imenu
    if (searchController.text.length >= 3) {
      if (joinedNumbers.length == 3 && searchQuery.isNotEmpty) {
        final searchQueries = searchQuery
            .toLowerCase()
            .split('|'); // Razdeli niz iskalnih poizvedb
        filteredItems = filteredItems.where((item) {
          String itemName =
              item['name'].toLowerCase().replaceAll(RegExp(r'\d'), '');
          final words = itemName.split(' ');

          // Preveri, ali katerakoli od iskalnih poizvedb ustreza kateri koli besedi
          return searchQueries
              .any((query) => words.any((word) => word.startsWith(query)));
        }).toList();
      }
    } else if (numbers2String.length <= 5 && searchQuery.isNotEmpty) {
      filteredItems = filteredItems.where((item) {
        return int.tryParse(item['itemId']) == int.tryParse(numbers2String);
      }).toList();
    }

    return filteredItems;
  }

//category list na vrhu zaslona
  Widget _categoryList() {
    List<String> categories = ["Vse"] + categorizedItems.keys.toList();
    final settings = ref.watch(settingsProvider);
    final defaultColors = settings['isCheckedBarve'] ?? false;
    final selectedCategoryState = ref.watch(selectedCategoryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: ((context, index) {
            String category = categories[index];

            int categoryIndex =
                categorizedItems.keys.toList().indexOf(category);

            Color assignedBackgroundColor =
                backgroundColors[categoryIndex % backgroundColors.length];
            Color assignedTextColor = AppStyles.black;

            Color textColor;
            Color backgroundColor;

            backgroundColor = assignedBackgroundColor;
            textColor = assignedTextColor;

            return GestureDetector(
              onTap: () {
                ref.read(selectedCategoryProvider.notifier).state = category;
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: backgroundColor),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                    child: Center(
                      child: Text(
                        category,
                        style: AppStyles.paragraph3.copyWith(
                            color: AppStyles.black,
                            fontWeight: FontWeight.bold),
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

  void _increaseQuantity() {
    final selectedItem = ref.read(selectedItemProvider.notifier).state;
    if (selectedItem != null) {
      //Use provider to update
      ref.read(narociloNotifierProvider.notifier).updateQuantity(
          selectedItem.product.id,
          selectedItem.description,
          selectedItem.quantity + 1,
          selectedItem.product.price,
          selectedItem.quantity);

      _updateFinalSum();
    }
  }

  void _decreaseQuantity() {
    final selectedItem = ref.read(selectedItemProvider.notifier).state;
    if (selectedItem != null && selectedItem.quantity > 1) {
      final double newQuantity =
          selectedItem.quantity - 1.0; // Keep double precision

      //Use provider to update
      ref.read(narociloNotifierProvider.notifier).updateQuantity(
          selectedItem.product.id,
          selectedItem.description,
          selectedItem.quantity - 1,
          selectedItem.product.price,
          selectedItem.quantity);
      ref.read(selectedItemProvider.notifier).state =
          selectedItem.copyWith(quantity: newQuantity);

      _updateFinalSum();

      // Update the final sum after changing quantity
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat("EEE, dd. MMM yyyy").format(currentDate);
    String formattedTime = DateFormat("HH:mm").format(currentDate);

    final String? user = SessionManager().getLoggedInUserName();
    final stateSelectedCategory = ref.watch(selectedCategoryProvider);
    final settings = ref.watch(settingsProvider);
    final defaultBarve = settings['isCheckedBarve'] ?? false;

    final numbers2String =
        ref.watch(searchQueryProvider); // Get value from provider
    final isSearching = ref.watch(isSearchingProvider);

    orderService = ref.read(orderProvider);

    //Get the ordered items from the provider
    final currentChosenItems = ref.watch(narociloNotifierProvider);

    return Scaffold(
      backgroundColor: AppStyles.lightGrey,
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 32.0,
        backgroundColor: AppStyles.white,
        iconTheme: const IconThemeData(color: AppStyles.blue),
        title: Text(
          user ?? '',
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
                        child: ItemListBuilder(
                            columnNum: stStolpcev,
                            categorizedItems: categorizedItems,
                            getFilteredItems: _getFilteredItems,
                            selectedCategory: stateSelectedCategory ?? "Vse",
                            onSelectItem: _ouputselectedItem,
                            backgroundColors: backgroundColors,
                            ref: ref)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: GestureDetector(
                          onHorizontalDragEnd: currentChosenItems.isNotEmpty
                              ? (details) {
                                  if (details.velocity.pixelsPerSecond.dx > 0) {
                                    _decreaseQuantity();
                                  } else if (details
                                          .velocity.pixelsPerSecond.dx <
                                      0) {
                                    _increaseQuantity();
                                  }
                                }
                              : null,
                          child: BlagajnaBanner()),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Keyboard(
                        opisDiscountButton: "OPIS",
                        racunArtikliButton: "RAČUN",
                        navigateToRacun: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const RacunScreen(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
                            ),
                          ).then((_) {
                            _updateFinalSum(); // Update final sum on return
                          });
                        },
                        navigateToMizaScreen: _navigateToMizaScreen,
                        navigateToNacinPlacilaScreen:
                            _navigateToNacinPlacilaScreen,
                        controller: searchController,
                        navigateToOpisDiscountScreen: _navigateToOpisScreen,
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
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const NacinPlacilaScreen()));
  }

  void _navigateToOpisScreen() async {
    final selectedItem = ref.read(selectedItemProvider.notifier).state;

    if (selectedItem != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditItemScreen(
            itemName: selectedItem.product.name,
            itemCategory: selectedItem.product.categoryID,
            itemPrice: selectedItem.product.price,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ni izbranega izdelka za urejanje')));
    }
  }
}
