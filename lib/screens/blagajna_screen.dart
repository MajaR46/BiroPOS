import 'package:BiroPOS/components/blagajna_banner.dart';
import 'package:BiroPOS/components/category_list.dart';
import 'package:BiroPOS/utils/debouncer.dart';
import 'package:BiroPOS/utils/id_ean_search.dart';
import 'package:BiroPOS/components/item_card.dart';
import 'package:BiroPOS/components/item_list_builder.dart';
import 'package:BiroPOS/components/keyboard.dart';
import 'package:BiroPOS/components/landscape_layout.dart';
import 'package:BiroPOS/utils/search_items.dart';
import 'package:BiroPOS/components/usb_printer.dart';
import 'package:BiroPOS/controllers/table_controller.dart';
import 'package:BiroPOS/models/item.dart';
import 'package:BiroPOS/models/narociloitem.dart';
import 'package:BiroPOS/providers/categoriseditems_provider.dart';
import 'package:BiroPOS/providers/direct_payment_provider.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/searchquery_provider.dart';
import 'package:BiroPOS/providers/selectedcategory_provider.dart';
import 'package:BiroPOS/providers/selecteditem_provider.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:BiroPOS/screens/edit_item_screen.dart';
import 'package:BiroPOS/screens/mize/add_to_table_screen.dart';
import 'package:BiroPOS/screens/mize/open_tables_screen.dart';
import 'package:BiroPOS/screens/mize/prostori_screen.dart';
import 'package:BiroPOS/screens/nacin_placila_screen.dart';
import 'package:BiroPOS/screens/racun_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:BiroPOS/components/drawer.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
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
  bool isLoading = false;
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
  double _totalDiscount = 0.0;
  bool _isSearchMode = false;
  bool isManualSearch = false;
  List<Map<String, String>> _tables = [];
  bool _tablesFetched = false;
  bool _isKeyboardVisible = true;

// V _BlagajnaScreenState class
  final Debouncer _searchDebouncer =
      Debouncer(miliseconds: 350); // Prilagodite čas po potrebi (npr. 500ms)
  @override
  void initState() {
    super.initState();

    if (izdelki.isEmpty) {
      // Preverimo, če so podatki že v pomnilniku
      _handleData();
    }
    _fetchTables();
    searchController.addListener(() {
      _searchDebouncer.debouce(_onSearchChanged);
    });

    Future.microtask(() {
      final orderService = ref.watch(orderProvider);
      orderService.initializePaymentMethods();
    });
  }

  void _onSearchChanged() {
    var orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.portrait) {
      _searchListener();
      _searchListener2();
    }
  }

  void _searchListener() {
    ref.read(isSearchingProvider.notifier).state =
        searchController.text.isNotEmpty;
    updateNumbersString(searchController, ref);
  }

  void _searchListener2() {
    final numbers2String1 = ref.watch(searchQueryProvider);
    String filtriranSearch = numbers2String1.replaceAll(RegExp(r'[^0-9]'), '');
    final iskalniNizString = ref.watch(iskalniNiz);

    if (filtriranSearch.length == 3 ||
        filtriranSearch.length == 6 && iskalniNizString.isNotEmpty) {
      final selectedCategory = ref.read(selectedCategoryProvider.notifier);

      if (selectedCategory.state != 'Iskanje') {
        selectedCategory.state = 'Iskanje';
      }
    } else if (filtriranSearch.length < 6) {
      final selectedCategory = ref.read(selectedCategoryProvider.notifier);

      if (selectedCategory.state == 'Iskanje') {
        selectedCategory.state = 'Vse';
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateFinalSum();
  }

  @override
  void dispose() {
    searchController.removeListener(_searchListener);
    searchController.removeListener(_searchListener2);
    searchController.removeListener(_onSearchChanged);

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
      final settings = ref.watch(settingsProvider);
      final nastaviCeno = settings['isCheckedMoney'];

      Item originalItem = Item.fromMap(outputtedItem);
      Item newItem = originalItem.copyWith();

      // Pripravimo artikel za naročilo (default količina 1)
      NarociloItem newNarociloItem =
          NarociloItem(product: newItem.copyWith(), quantity: 1);

      // Preverimo obstoječe artikle
      final currentItems = ref.read(narociloNotifierProvider); // NE watch

      final existingItemIndex = currentItems.indexWhere((item) =>
          item.product.id == newNarociloItem.product.id &&
          item.description == newNarociloItem.description);

      // Dodaj artikel (ali posodobi količino)

      if (nastaviCeno == false) {
        ref
            .read(narociloNotifierProvider.notifier)
            .addToRacun(newNarociloItem, fromTable: false, nastaviCeno: false);
      } else {
        ref
            .read(narociloNotifierProvider.notifier)
            .addToRacun(newNarociloItem, fromTable: false, nastaviCeno: true);
      }

      // Po posodobitvi ponovno preberi posodobljeno stanje
      final updatedItems = ref.read(narociloNotifierProvider);
      NarociloItem updatedItem;
      print("nastavi ceno $nastaviCeno");

      updatedItem = updatedItems.firstWhere(
        (item) =>
            item.product.id == newNarociloItem.product.id &&
            item.description == newNarociloItem.description &&
            item.quantity % 1 == 0,
        orElse: () => newNarociloItem,
      );
      ref.read(selectedItemProvider.notifier).state = updatedItem;

      // Pridobi posodobljen artikel iz stanja

      // Nastavi izbran artikel

      // Posodobi končni znesek
      _updateFinalSum();
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

  void _searchByName() {
    updateNumbersString(searchController, ref);

    final iskalniNizString = ref.watch(iskalniNiz);
    final numbers2String1 = ref.watch(searchQueryProvider);
    final filtriranSearch = numbers2String1.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() {
      isManualSearch = true;

      if (iskalniNizString.isNotEmpty) {
        if (ref.read(selectedCategoryProvider.notifier).state != 'Iskanje') {
          ref.read(selectedCategoryProvider.notifier).state = 'Iskanje';
        }
      } else if (iskalniNizString.isEmpty) {
        ref.read(selectedCategoryProvider.notifier).state = 'Vse';
      }
    });
    _getFilteredItems();
  }

  List<dynamic> _getFilteredItems() {
    String searchText = searchController.text;

    final iskalniNizString = ref.watch(iskalniNiz);

    final stateSelectedCategory = ref.read(selectedCategoryProvider);
    String filtriranSearch =
        searchController.text.replaceAll(RegExp(r'[^0-9]'), '');
    var orientation = MediaQuery.of(context).orientation;

    final numbers2String1 = ref.watch(searchQueryProvider);
    final numbers2String = numbers2String1.replaceAll(RegExp(r'[^0-9]'), '');
    generatePairs(searchController);

    List<dynamic> filteredItems = [];
    if (stateSelectedCategory == "Vse" || stateSelectedCategory == "Iskanje") {
      for (var categoryItems in categorizedItems.values) {
        filteredItems.addAll(categoryItems);
      }
    } else {
      filteredItems = categorizedItems[stateSelectedCategory] ?? [];
    }

    RegExp regExp = RegExp(r'\d+');
    Iterable<Match> matches = regExp.allMatches(searchText);
    List<String> numbers2 = matches.map((match) => match.group(0)!).toList();

    if (numbers2String.length >= 3) {
      if (numbers2String.length == 3 && iskalniNizString.isNotEmpty) {
        final searchQueries = iskalniNizString.toLowerCase().split('|');
        filteredItems = filteredItems.where((item) {
          String itemName =
              item['name'].toLowerCase().replaceAll(RegExp(r'\d'), '');
          final words = itemName.split(' ');

          return searchQueries
              .any((query) => words.any((word) => word.startsWith(query)));
        }).toList();
      } else if (numbers2String.length == 6 && iskalniNizString.isNotEmpty) {
        final searchQueries = iskalniNizString.toLowerCase().split('|');
        List<String> finalSearchQueries = [];

        for (var query in searchQueries) {
          int middle = (query.length / 2).ceil();
          finalSearchQueries.add(query.substring(0, middle));
          finalSearchQueries.add(query.substring(middle));
        }

        filteredItems = filteredItems.where((item) {
          String itemName =
              item['name'].toLowerCase().replaceAll(RegExp(r'\d'), '');
          List<String> words = itemName.split(' ');

          words = words.where((word) => word.isNotEmpty).toList();

          if (words.length < 2) {
            return false;
          }

          bool firstWordMatches =
              finalSearchQueries.any((query) => words[0].startsWith(query));
          bool secondWordMatches = words.skip(1).any((word) {
            return finalSearchQueries.any((query) => word.startsWith(query));
          });

          return firstWordMatches && secondWordMatches;
        }).toList();
      }
    } else if (numbers2String.length <= 5 && iskalniNizString.isNotEmpty) {
      filteredItems = filteredItems.where((item) {
        return int.tryParse(item['itemId']) == int.tryParse(numbers2String);
      }).toList();
    }
    Future(() {
      ref.read(filteredItemsProvider.notifier).state = filteredItems;
    });
    return filteredItems;
  }

  void _increaseQuantity() {
    final selectedItem = ref.read(selectedItemProvider.notifier).state;
    if (selectedItem != null) {
      //Use provider to update
      ref.read(narociloNotifierProvider.notifier).updateQuantity(
          selectedItem.uniqueId,
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
          selectedItem.uniqueId,
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

  void _searchByEan(String input) {
    searchByEan(input, ref, context, _updateTotalDiscount);
  }

  void _checkAndSetSearchMode() {
    String searchText = searchController.text.trim();
    _isSearchMode = checkAndSetSearchMode(
        searchText); // Use the function from search_ean.dart
  }

  void _hideKeyboard() {
    setState(() {
      _isKeyboardVisible = !_isKeyboardVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat("EEE, dd. MMM yyyy").format(currentDate);
    String formattedTime = DateFormat("HH:mm").format(currentDate);

    final String? user = SessionManager().getLoggedInUserName();

    final stateSelectedCategory = ref.watch(selectedCategoryProvider);
    final settings = ref.watch(settingsProvider);
    final defaultBarve = settings['isCheckedBarve'] ?? false;
    final isCheckedUsbPrinting = settings['isCheckedUsbPrintanje'] ?? false;

    var orientation = MediaQuery.of(context).orientation;
    if (isCheckedUsbPrinting) {
      UsbPrint.connectUsbPrinter();
    }
    final numbers2String =
        ref.watch(searchQueryProvider); // Get value from provider

    final isSearching = ref.watch(isSearchingProvider);

    orderService = ref.read(orderProvider);

    //Get the ordered items from the provider
    final currentChosenItems = ref.watch(narociloNotifierProvider);

    return Scaffold(
        backgroundColor: AppStyles.lightGrey,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(32.0),
          child: GestureDetector(
            onDoubleTap: _hideKeyboard,
            child: AppBar(
              centerTitle: true,
              toolbarHeight: 32.0,
              backgroundColor: AppStyles.white,
              iconTheme: const IconThemeData(color: AppStyles.blue),
              title: Text(
                user ?? '',
                style: AppStyles.paragraph3.copyWith(
                    color: AppStyles.blue, fontWeight: FontWeight.bold),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(
                    formattedTime,
                    style: AppStyles.paragraph3.copyWith(
                        color: AppStyles.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        drawer: const CustomDrawer(),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError
                ? const Center(child: Text('Failed to load data'))
                : orientation == Orientation.portrait
                    ? Column(
                        children: [
                          CategoryList(
                              categorizedItems: categorizedItems,
                              backgroundColors: backgroundColors,
                              ref: ref),
                          Expanded(
                              child: ItemListBuilder(
                                  columnNum: stStolpcev,
                                  categorizedItems: categorizedItems,
                                  getFilteredItems: _getFilteredItems,
                                  selectedCategory:
                                      stateSelectedCategory ?? "Vse",
                                  onSelectItem: _ouputselectedItem,
                                  backgroundColors: backgroundColors,
                                  ref: ref)),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: GestureDetector(
                                onHorizontalDragEnd:
                                    currentChosenItems.isNotEmpty
                                        ? (details) {
                                            if (details.velocity.pixelsPerSecond
                                                    .dx >
                                                0) {
                                              _decreaseQuantity();
                                            } else if (details.velocity
                                                    .pixelsPerSecond.dx <
                                                0) {
                                              _increaseQuantity();
                                            }
                                          }
                                        : null,
                                child: BlagajnaBanner(
                                  controller: searchController,
                                )),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Visibility(
                              visible: _isKeyboardVisible,
                              child: Keyboard(
                                search: () {},
                                opisDiscountButton: "OPIS",
                                racunArtikliButton: "RAČUN",
                                navigateToRacun: () {
                                  Navigator.pushReplacement(
                                    context,
                                    PageRouteBuilder(
                                        pageBuilder: (context, animation,
                                                secondaryAnimation) =>
                                            const RacunScreen(),
                                        transitionsBuilder: (context, animation,
                                            secondaryAnimation, child) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        }),
                                  ).then((_) {
                                    _updateFinalSum();
                                    _searchByName();
                                  });
                                },
                                navigateToMizaScreen: _navigateToMizaScreen,
                                navigateToNacinPlacilaScreen:
                                    _navigateToNacinPlacilaScreen,
                                controller: searchController,
                                navigateToOpisDiscountScreen:
                                    _navigateToOpisScreen,
                                icon: Icons.arrow_back,
                              ),
                            ),
                          ),
                        ],
                      )
                    : LandscapeLayout(
                        columnNum: stStolpcev,
                        keyboardController: searchController,
                        categorizedItems: categorizedItems,
                        getFilteredItems: _getFilteredItems,
                        selectedCategory: stateSelectedCategory ?? "Vse",
                        onSelectItem: _ouputselectedItem,
                        backgroundColors: backgroundColors,
                        searchByName: _searchByName,
                        ref: ref,
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
                        navigateToOpis: _navigateToOpisScreen,
                      ));
  }

  /////////////////////////////////////////////////////////////////// NAVIGATE FUNCTIONS ////////////////////////////////////////////////////

  void _navigateToMizaScreen() async {
    List<NarociloItem> currentChosenItems = ref.read(narociloNotifierProvider);
    final table = _tables.firstWhere(
      (table) => table['prostor'] != '',
      orElse: () => {},
    );
    if (currentChosenItems.isNotEmpty) {
      // Predpostavljam, da želiš preveriti prvi element v tabelah, lahko pa pregleduješ tudi specifičen index.

      if (table['prostor'] == null ||
          table['prostor']!.isEmpty && table['prostor'] != 'Miza') {
        // Če je 'prostor' prazen, preusmeri na AddToTableScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AddToTableScreen()),
        );
      } else {
        // Če 'prostor' ni prazen, preusmeri na ProstoriScreen
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
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => const NacinPlacilaScreen()));
  }

  void _navigateToOpisScreen() async {
    final selectedItem = ref.read(selectedItemProvider.notifier).state;

    if (selectedItem != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditItemScreen(
            narociloItemUniqueId: selectedItem.uniqueId,
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
