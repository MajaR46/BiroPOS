import 'dart:convert';
import 'package:biro_pos/components/item_card.dart';
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

  @override
  void initState() {
    super.initState();
    loadCafeItems();
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
        print("Error loading cafe items: $error");
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
    if (selectedCategory == "Vse") {
      return cafeItems;
    } else {
      return categorizedItems[selectedCategory] ?? [];
    }
  }

//category list na vrhu zaslona
  Widget _categoryList() {
    List<String> categories = ["Vse"] + categorizedItems.keys.toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 50,
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

    if (selectedCategory == "Vse") {
      Map<String, List<dynamic>> itemsByCategory =
          _categorizeItems(filteredItems);

      List<String> categories = categorizedItems.keys.toList();

      return SizedBox(
        height: 400,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: ((context, index) {
              String category = categories[index];
              List<dynamic> items = categorizedItems[category] ?? [];

              return SizedBox(
                width: 200,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        category,
                        style: AppStyles.heading4,
                      ),
                    ),
                    Expanded(
                        child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, itemIndex) {
                        final item = items[itemIndex];

                        String category = item['category'];

                        int categoryIndex =
                            categorizedItems.keys.toList().indexOf(category);

                        Color assignedBackgroundColor = backgroundColors[
                            categoryIndex % backgroundColors.length];
                        Color assignedTextColor =
                            textColors[categoryIndex % textColors.length];

                        return ItemCard(
                            itemName: item['name'],
                            itemPrice: item['price'],
                            itemCategory: item['category'],
                            backgroundColor: assignedBackgroundColor,
                            textColor: assignedTextColor);
                      },
                    ))
                  ],
                ),
              );
            })),
      );
    } else {
      //layout za posamezno kategorijo
      return ListView.builder(
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          String category = item['category'];

          int categoryIndex = categorizedItems.keys.toList().indexOf(category);

          Color assignedBackgroundColor =
              backgroundColors[categoryIndex % backgroundColors.length];
          Color assignedTextColor =
              textColors[categoryIndex % textColors.length];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
          backgroundColor: AppStyles.white,
          iconTheme: const IconThemeData(color: AppStyles.blue),
          title: Text(
            formattedDate,
            style: AppStyles.boldanparagraph1.copyWith(color: AppStyles.blue),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                formattedTime,
                style:
                    AppStyles.boldanparagraph1.copyWith(color: AppStyles.blue),
              ),
            )
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
                      Expanded(child: _buildItemList())
                    ],
                  ));
  }
}
