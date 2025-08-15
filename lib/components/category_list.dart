import 'dart:ui';

import 'package:BiroPOS/app_styles.dart';
import 'package:BiroPOS/providers/selectedcategory_provider.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryList extends ConsumerStatefulWidget {
  final Map<String, List<dynamic>> categorizedItems;
  final List<Color> backgroundColors;
  final WidgetRef ref;

  const CategoryList({
    super.key,
    required this.categorizedItems,
    required this.backgroundColors,
    required this.ref,
  });

  @override
  ConsumerState<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends ConsumerState<CategoryList> {
  late String textSize = "";
  late double selectedTextSize;

  Future<void> _loadDropdownValue() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      textSize = prefs.getString('groupsSize') ?? '';
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDropdownValue();
  }

  @override
  Widget build(BuildContext context) {
    final categorySize = double.tryParse(textSize) ?? 16.0;
    List<String> preostaleKategorije = widget.categorizedItems.keys.toList()
      ..sort();
    List<String> sortedCategories = ["Vse", ...preostaleKategorije];

    final settings = ref.watch(settingsProvider);
    final dvojnaVrstica = settings['isCheckedDvojnaVrstica'] ?? false;

    int halfLength = (sortedCategories.length / 2).ceil();
    List<String> firstHalf = sortedCategories.sublist(0, halfLength);
    List<String> seconfHalf = sortedCategories.sublist(halfLength);

    Widget buildCategoryCard(String category) {
      int categoryIndex =
          widget.categorizedItems.keys.toList().indexOf(category);

      Color assignedBackgroundColor = widget
          .backgroundColors[categoryIndex % widget.backgroundColors.length];
      Color assignedTextColor = AppStyles.black;

      return GestureDetector(
          onTap: () {
            widget.ref.read(selectedCategoryProvider.notifier).state = category;
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: assignedBackgroundColor),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Center(
                  child: Text(
                    category,
                    style: AppStyles.paragraph1.copyWith(
                      fontSize: categorySize,
                      color: AppStyles.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ));
    }

    return dvojnaVrstica
        ? SizedBox(
            height: (categorySize + 20) * 3, // vedno enaka logika
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start, // prepreči overflow
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: firstHalf.map(buildCategoryCard).toList()),
                  Row(children: seconfHalf.map(buildCategoryCard).toList()),
                ],
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              height: categorySize + 20,
              child: ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse
                }),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: sortedCategories.length,
                  itemBuilder: (context, index) {
                    String category = sortedCategories[index];

                    int categoryIndex =
                        widget.categorizedItems.keys.toList().indexOf(category);

                    Color assignedBackgroundColor = widget.backgroundColors[
                        categoryIndex % widget.backgroundColors.length];
                    Color assignedTextColor = AppStyles.black;

                    Color textColor;
                    Color backgroundColor;

                    backgroundColor = assignedBackgroundColor;
                    textColor = assignedTextColor;

                    return GestureDetector(
                      onTap: () {
                        widget.ref
                            .read(selectedCategoryProvider.notifier)
                            .state = category;
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
                            padding: const EdgeInsets.symmetric(
                                vertical: 2, horizontal: 8),
                            child: Center(
                              child: Text(
                                category,
                                style: AppStyles.paragraph1.copyWith(
                                    fontSize: categorySize,
                                    color: AppStyles.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ));
  }
}
