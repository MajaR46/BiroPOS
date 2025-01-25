import 'package:biro_pos/app_styles.dart';
import 'package:biro_pos/components/item_card.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/providers/selectedcategory_provider.dart';
import 'package:biro_pos/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';

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

class ItemListBuilder extends StatefulWidget {
  final Map<String, List<dynamic>> categorizedItems;
  final List<dynamic> Function() getFilteredItems;
  final String selectedCategory;
  final Function(dynamic) onSelectItem;
  final List<Color> backgroundColors;
  final List<Color> textColors;
  final int columnNum;
  final WidgetRef ref;

  const ItemListBuilder({
    Key? key,
    required this.categorizedItems,
    required this.getFilteredItems,
    required this.selectedCategory,
    required this.onSelectItem,
    required this.backgroundColors,
    required this.textColors,
    required this.columnNum,
    required this.ref,
  }) : super(key: key);

  @override
  _ItemListBuilderState createState() => _ItemListBuilderState();
}

class _ItemListBuilderState extends State<ItemListBuilder> {
  late String dropdownvalue = '';
  late bool nastaviCeno = false;
  late double selectedTextSize;
  final TextEditingController priceController = TextEditingController();

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
      openDialog(itemID, itemPrice, itemName);
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

    if (dropdownvalue == "Majhna") {
      selectedTextSize = 8;
    } else if (dropdownvalue == "Srednja") {
      selectedTextSize = 12;
    } else if (dropdownvalue == "Velika") {
      selectedTextSize = 20;
    } else {
      selectedTextSize = 12;
    }

    if (widget.selectedCategory == "") {
      return const Center(child: Text("Ni izbrane kategorije"));
    }

    if (filteredItems.isEmpty) {
      return const Center(child: Text("Ni izdelkov"));
    }

    if (widget.selectedCategory == "Vse") {
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

                        Color assignedTextColor = widget.textColors[
                            categoryIndex % widget.textColors.length];
                        final String itemColor = item['itemColor'];

                        return GestureDetector(
                          onTap: enojniKlik
                              ? () => _handleItemSelectItem(item, hhCene)
                              : null,
                          onDoubleTap: !enojniKlik
                              ? () => _handleItemSelectItem(item, hhCene)
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
                            cardBackground: AppStyles.white,
                            itemNameColor: defaultColors == true
                                ? Colors.black
                                : itemColorMapping[itemColor] ?? Colors.black,
                            itemCategoryBackgroundColor: defaultColors == true
                                ? assignedBackgroundColor
                                : AppStyles.lightBlue,
                            itemCategoryTextColor: defaultColors == true
                                ? assignedTextColor
                                : AppStyles.black,
                            textSize: selectedTextSize,
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
      return LayoutBuilder(
        builder: (context, constraints) {
          int gridColumnCount = widget.columnNum;

          // Dinamična širina kartice glede na število stolpcev
          double cardWidth =
              (constraints.maxWidth - (gridColumnCount - 1) * 2) /
                  gridColumnCount;

          // Prilagoditev razmerja glede na širino in privzeto višino
          double cardHeight = selectedTextSize * 4 + 20; // Približna višina
          double calculatedAspectRatio = cardWidth / cardHeight;
          final sortedItems = filteredItems
            ..sort((item1, item2) => item1['name'].compareTo(item2['name']));

          return SingleChildScrollView(
            child: Wrap(
              spacing: 2.0, // Razmik med karticami horizontalno
              runSpacing: 2.0, // Razmik med vrsticami
              children: sortedItems.map((item) {
                int categoryIndex = widget.categorizedItems.keys
                    .toList()
                    .indexOf(item['category']);
                Color assignedBackgroundColor = widget.backgroundColors[
                    categoryIndex % widget.backgroundColors.length];
                Color assignedTextColor =
                    widget.textColors[categoryIndex % widget.textColors.length];
                final String itemColor = item['itemColor'];

                return GestureDetector(
                  onTap: enojniKlik
                      ? () => _handleItemSelectItem(item, hhCene)
                      : null,
                  onDoubleTap: !enojniKlik
                      ? () => _handleItemSelectItem(item, hhCene)
                      : null,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: (MediaQuery.of(context).size.width - 32) /
                          widget.columnNum, // Prilagodi širino stolpca
                      maxWidth: (MediaQuery.of(context).size.width - 32) /
                          widget.columnNum,
                    ),
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
                      cardBackground: assignedBackgroundColor,
                      itemNameColor: defaultColors == true
                          ? Colors.black
                          : itemColorMapping[itemColor] ?? Colors.black,
                      itemCategoryBackgroundColor: defaultColors == true
                          ? assignedBackgroundColor
                          : AppStyles.lightBlue,
                      itemCategoryTextColor: defaultColors == true
                          ? assignedTextColor
                          : AppStyles.black,
                      textSize: selectedTextSize,
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
    'A': AppStyles.blue,
    'B': AppStyles.darkBrown,
    'C': AppStyles.darkOrange,
    'D': AppStyles.red,
    'E': AppStyles.pink,
    'F': AppStyles.yellow,
    'G': AppStyles.silver,
    'H': AppStyles.darkBlue,
    'I': AppStyles.darkBlue,
    'J': AppStyles.darkPurple,
    'K': AppStyles.green,

    // Add more mappings as needed
  };
}
