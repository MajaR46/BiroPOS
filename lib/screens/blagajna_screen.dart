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
              style: AppStyles.boldanparagraph1.copyWith(color: AppStyles.blue),
            ),
          )
        ],
      ),
      drawer: const CustomDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(child: Text('Failed to load data'))
              : ListView(
                  children: categorizedItems.entries.map((entry) {
                    String category = entry.key;
                    List<dynamic> items = entry.value;

                    int categoryIndex =
                        categorizedItems.keys.toList().indexOf(category);
                    Color assignedBackgroundColor = backgroundColors[
                        categoryIndex %
                            backgroundColors
                                .length]; // & omogoča da se loop ponovi

                    Color assignedTextColor =
                        textColors[categoryIndex % textColors.length];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 110,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final sortedItems = List.from(items)
                                ..sort((item1, item2) =>
                                    (item1['name'] as String)
                                        .compareTo(item2['name'] as String));

                              final item = sortedItems[index];
                              return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: ItemCard(
                                    itemName: item['name'],
                                    itemCategory: item['category'],
                                    itemPrice: item['price'],
                                    backgroundColor: assignedBackgroundColor,
                                    textColor: assignedTextColor,
                                  ));
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
    );
  }
}
