import 'package:biro_pos/app_styles.dart';
import 'package:biro_pos/components/item_card.dart';
import 'package:biro_pos/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

Widget buildItemList(
    {required Map<String, List<dynamic>> categorizedItems,
    required List<dynamic> Function() getFilteredItems,
    required String selectedCategory,
    required Function(dynamic) onSelectItem,
    required List<Color> backgroundColors,
    required List<Color> textColors,
    required int columnNum,
    required WidgetRef ref}) {
  List<dynamic> filteredItems = getFilteredItems();

  final settings = ref.watch(settingsProvider);
  final enojniKlik = settings['isCheckedEnojniKlik'] ?? false;
  final hhCene = settings['isCheckedHHCene'] ?? false;

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

                      int categoryIndex = categorizedItems.keys
                          .toList()
                          .indexOf(item['category']);
                      Color assignedBackgroundColor = backgroundColors[
                          categoryIndex % backgroundColors.length];

                      Color assignedTextColor =
                          textColors[categoryIndex % textColors.length];

                      return GestureDetector(
                        onTap: enojniKlik
                            ? () {
                                onSelectItem({
                                  'name': item['name'],
                                  'price': item['price'],
                                  'category': item['category'],
                                  'itemId': item['itemId'],
                                  'categoryID': item['categoryID'],
                                });
                              }
                            : null,
                        onDoubleTap: !enojniKlik
                            ? () {
                                onSelectItem({
                                  'name': item['name'],
                                  'price': item['price'],
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
    //layout za posamezno kategorijo
  } else {
    return LayoutBuilder(
      builder: (context, constraints) {
        int gridColumnCount = columnNum;

        double maxItemHeight = 70;
        double cardWidth = (constraints.maxWidth - (gridColumnCount - 1) * 2) /
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
              ..sort((item1, item2) => item1['name'].compareTo(item2['name']));
            final item = sortedItems[index];

            int categoryIndex =
                categorizedItems.keys.toList().indexOf(item['category']);
            Color assignedBackgroundColor =
                backgroundColors[categoryIndex % backgroundColors.length];
            Color assignedTextColor =
                textColors[categoryIndex % textColors.length];

            return GestureDetector(
              onTap: enojniKlik ? () => onSelectItem(item) : null,
              onDoubleTap: !enojniKlik ? () => onSelectItem(item) : null,
              child: SizedBox(
                height: maxItemHeight,
                child: ItemCard(
                  isAllLayout: false,
                  stStolpcev: columnNum,
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
