import 'package:biro_pos/app_styles.dart';
import 'package:biro_pos/components/item_card.dart';
import 'package:biro_pos/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late double selectedTextSize;

  @override
  void initState() {
    super.initState();
    _loadDropdownValue();
  }

  Future<void> _loadDropdownValue() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      dropdownvalue = prefs.getString('touchKey') ?? 'Default Value';
    });
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredItems = widget.getFilteredItems();
    final settings = widget.ref.watch(settingsProvider);
    final enojniKlik = settings['isCheckedEnojniKlik'] ?? false;
    final hhCene = settings['isCheckedHHCene'] ?? false;

    if (dropdownvalue == "Mala") {
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

                        return GestureDetector(
                          onTap: enojniKlik
                              ? () {
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
                                  });
                                }
                              : null,
                          onDoubleTap: !enojniKlik
                              ? () {
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
                                  });
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
                            cardBackground: AppStyles.white,
                            backgroundColor: assignedBackgroundColor,
                            textColor: assignedTextColor,
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

          double maxItemHeight = 70;
          double cardWidth =
              (constraints.maxWidth - (gridColumnCount - 1) * 2) /
                  gridColumnCount;
          double calculatedAspectRatio = cardWidth / maxItemHeight;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridColumnCount,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: calculatedAspectRatio,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final sortedItems = filteredItems
                ..sort(
                    (item1, item2) => item1['name'].compareTo(item2['name']));
              final item = sortedItems[index];

              int categoryIndex = widget.categorizedItems.keys
                  .toList()
                  .indexOf(item['category']);
              Color assignedBackgroundColor = widget.backgroundColors[
                  categoryIndex % widget.backgroundColors.length];
              Color assignedTextColor =
                  widget.textColors[categoryIndex % widget.textColors.length];

              return GestureDetector(
                onTap: enojniKlik ? () => widget.onSelectItem(item) : null,
                onDoubleTap:
                    !enojniKlik ? () => widget.onSelectItem(item) : null,
                child: SizedBox(
                  height: maxItemHeight,
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
                    backgroundColor: assignedBackgroundColor,
                    textColor: assignedTextColor,
                    textSize: selectedTextSize,
                  ),
                ),
              );
            },
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
}
