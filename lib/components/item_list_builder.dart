import 'package:BiroPOS/app_styles.dart';
import 'package:BiroPOS/utils/debouncer.dart';
import 'package:BiroPOS/components/item_card.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/searchquery_provider.dart';
import 'package:BiroPOS/providers/selectedcategory_provider.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';

class ItemListBuilder extends ConsumerStatefulWidget {
  final Map<String, List<dynamic>> categorizedItems;
  final List<dynamic> Function() getFilteredItems;
  final String selectedCategory;
  final Function(dynamic) onSelectItem;
  final List<Color> backgroundColors;
  final int columnNum;
  final WidgetRef ref;

  const ItemListBuilder({
    Key? key,
    required this.categorizedItems,
    required this.getFilteredItems,
    required this.selectedCategory,
    required this.onSelectItem,
    required this.backgroundColors,
    required this.columnNum,
    required this.ref,
  }) : super(key: key);

  @override
  _ItemListBuilderState createState() => _ItemListBuilderState();
}

class _ItemListBuilderState extends ConsumerState<ItemListBuilder> {
  late String dropdownvalue = '';
  late bool nastaviCeno = false;
  late double selectedTextSize;
  late double minCardHeight = 50.0;
  final TextEditingController priceController = TextEditingController();
  final Debouncer _debouncer = Debouncer(miliseconds: 2000);
  bool showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _loadDropdownValue();
  }

  Future<void> _loadDropdownValue() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      dropdownvalue = prefs.getString('touchKey') ?? 'Default Value';
      nastaviCeno = prefs.getBool('isCheckedMoney') ?? false;
    });
  }

  void _clearText() {
    priceController.clear();
  }

  Future openDialog(String itemId, String itemPrice, String itemName) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.white,
        title: const Text(
          textAlign: TextAlign.center,
          "Nastavi ceno",
          style: AppStyles.heading3,
        ),
        content: TextField(
          controller: priceController,
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
              onPressed: _clearText, // Clears the text input
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              itemPrice = priceController.text;
              final double newPrice = double.tryParse(itemPrice) ?? 0.0;

              final narociloNotifier =
                  widget.ref.read(narociloNotifierProvider.notifier);
              narociloNotifier.updatePrice(itemId, newPrice);

              Navigator.of(context).pop();
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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

  void _handleItemSelectItem(dynamic item, bool hhCene) {
    String itemPrice = item['price'] ?? '0.00';
    String itemName = item['name'];
    String itemID = item['itemId'] ?? '';

    if (itemPrice == '0,00' && nastaviCeno) {
      openDialog(itemID, itemPrice, itemName).then((_) {
        double enteredPrice = double.tryParse(priceController.text) ?? 0.0;
        if (enteredPrice > 0) {
          widget.onSelectItem({
            'name': item['name'],
            'price': enteredPrice, // Shrani unikatno ceno za ta izdelek
            'category': item['category'],
            'itemId': item['itemId'], // ID ostane isti
            'categoryID': item['categoryID'],
            'itemColor': item['itemColor']
          });
        }
      });
    } else {
      widget.onSelectItem({
        'name': item['name'],
        'price': hhCene == true
            ? (item['hhPrice']?.isEmpty ?? true)
                ? item['price']
                : item['hhPrice']
            : item['price'],
        'category': item['category'],
        'itemId': item['itemId'],
        'categoryID': item['categoryID'],
        'itemColor': item['itemColor']
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredItems = widget.getFilteredItems();

    final settings = widget.ref.watch(settingsProvider);
    final enojniKlik = settings['isCheckedEnojniKlik'] ?? false;
    final hhCene = settings['isCheckedHHCene'] ?? false;
    final defaultColors = settings['isCheckedBarve'] ?? false;
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final textSize = double.tryParse(dropdownvalue) ?? 12.0;

    minCardHeight = textSize * 4;

    if (selectedCategory == "") {
      return const Center(child: Text("Ni izbrane kategorije"));
    }

    if (filteredItems.isEmpty) {
      return const Center(child: Text("Ni izdelkov"));
    }

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
                        final sortedMainItems = items
                          ..sort((item1, item2) =>
                              item1['name'].compareTo(item2['name']));
                        final item = sortedMainItems[itemIndex];

                        int categoryIndex = widget.categorizedItems.keys
                            .toList()
                            .indexOf(item['category']);
                        Color assignedBackgroundColor = widget.backgroundColors[
                            categoryIndex % widget.backgroundColors.length];

                        Color assignedTextColor = AppStyles.black;
                        final String itemColor = item['itemColor'];

                        return GestureDetector(
                          onTap: enojniKlik
                              ? () {
                                  _handleItemSelectItem(item, hhCene);
                                  HapticFeedback.vibrate();
                                }
                              : null,
                          onDoubleTap: !enojniKlik
                              ? () {
                                  _handleItemSelectItem(item, hhCene);
                                  HapticFeedback.vibrate();
                                }
                              : null,
                          child: ItemCard(
                            isAllLayout: true,
                            stStolpcev: 1,
                            itemName: item['name'],
                            itemPrice: hhCene == true
                                ? (item['hhPrice']?.isEmpty ?? true)
                                    ? item['price']
                                    : item['hhPrice']
                                : item['price'],
                            itemCategory: item['category'],
                            cardBackground: defaultColors == true
                                ? assignedBackgroundColor
                                : itemColorMapping[itemColor] ??
                                    AppStyles.white,
                            itemNameColor: AppStyles.black,
                            itemCategoryTextColor: AppStyles.black,
                            textSize: textSize,
                            minCardHeight: minCardHeight,
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
    } else if (selectedCategory == "Iskanje") {
      return LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          child: Wrap(
            spacing: 4.0,
            runSpacing: 4.0,
            children: filteredItems.map((item) {
              int categoryIndex = widget.categorizedItems.keys
                  .toList()
                  .indexOf(item['category']);
              Color assignedBackgroundColor = widget.backgroundColors[
                  categoryIndex % widget.backgroundColors.length];
              Color assignedTextColor = AppStyles.black;
              final String itemColor = item['itemColor'];
              int gridColumnCount = widget.columnNum;

              double cardWidth =
                  (constraints.maxWidth - 4 * (gridColumnCount - 1)) /
                      gridColumnCount;

              return GestureDetector(
                onTap: enojniKlik
                    ? () {
                        HapticFeedback.vibrate();
                        _handleItemSelectItem(item, hhCene);
                      }
                    : null,
                onDoubleTap: !enojniKlik
                    ? () {
                        _handleItemSelectItem(item, hhCene);
                        HapticFeedback.vibrate();
                      }
                    : null,
                child: Container(
                  width: cardWidth,
                  child: ItemCard(
                    isAllLayout: false,
                    stStolpcev: gridColumnCount,
                    itemName: item['name'],
                    itemPrice: hhCene == true
                        ? (item['hhPrice']?.isEmpty ?? true)
                            ? item['price']
                            : item['hhPrice']
                        : item['price'],
                    itemCategory: item['category'],
                    cardBackground: defaultColors == true
                        ? assignedBackgroundColor
                        : itemColorMapping[itemColor] ?? AppStyles.white,
                    itemNameColor: AppStyles.black,
                    itemCategoryTextColor: defaultColors == true
                        ? assignedTextColor
                        : AppStyles.black,
                    textSize: textSize,
                    minCardHeight: minCardHeight,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      });
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          int gridColumnCount = widget.columnNum;

          double cardWidth =
              (constraints.maxWidth - 4 * (gridColumnCount - 1)) /
                  gridColumnCount;

          final sortedItems = filteredItems
            ..sort((item1, item2) => item1['name'].compareTo(item2['name']));
          return SingleChildScrollView(
            child: Wrap(
              spacing: 4.0, // Razmik med karticami horizontalno
              runSpacing: 4.0, // Razmik med vrsticami
              children: sortedItems.map((item) {
                int categoryIndex = widget.categorizedItems.keys
                    .toList()
                    .indexOf(item['category']);
                Color assignedBackgroundColor = widget.backgroundColors[
                    categoryIndex % widget.backgroundColors.length];
                Color assignedTextColor = AppStyles.black;
                final String itemColor = item['itemColor'];

                return GestureDetector(
                  onTap: enojniKlik
                      ? () {
                          HapticFeedback.vibrate();
                          _handleItemSelectItem(item, hhCene);
                        }
                      : null,
                  onDoubleTap: !enojniKlik
                      ? () {
                          _handleItemSelectItem(item, hhCene);
                          HapticFeedback.vibrate();
                        }
                      : null,
                  child: Container(
                    width: cardWidth,
                    child: ItemCard(
                      isAllLayout: false,
                      stStolpcev: widget.columnNum,
                      itemName: item['name'],
                      itemPrice: hhCene == true
                          ? (item['hhPrice']?.isEmpty ?? true)
                              ? item['price']
                              : item['hhPrice']
                          : item['price'],
                      itemCategory: item['category'],
                      cardBackground: defaultColors == true
                          ? assignedBackgroundColor
                          : itemColorMapping[itemColor] ?? AppStyles.white,
                      itemNameColor: AppStyles.black,
                      itemCategoryTextColor: defaultColors == true
                          ? assignedTextColor
                          : AppStyles.black,
                      textSize: textSize,
                      minCardHeight: minCardHeight,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      );
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

  Map<String, Color> itemColorMapping = {
    'A': AppStyles.darkBlue,
    'B': AppStyles.oker,
    'C': AppStyles.brightOrange,
    'D': AppStyles.red,
    'E': AppStyles.pink,
    'F': AppStyles.yellow,
    'G': AppStyles.grey,
    'H': AppStyles.lightBlue,
    'I': AppStyles.lightGreen,
    'J': AppStyles.purple,
    'K': AppStyles.green,
    'L': AppStyles.gold

    // Add more mappings as needed
  };
}
