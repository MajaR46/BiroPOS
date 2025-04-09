import 'package:biro_pos/app_styles.dart';
import 'package:biro_pos/providers/selectedcategory_provider.dart';
import 'package:biro_pos/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryList extends StatefulWidget {
  final Map<String, List<dynamic>> categorizedItems;
  final List<Color> backgroundColors;
  final WidgetRef ref;

  const CategoryList({
    Key? key,
    required this.categorizedItems,
    required this.backgroundColors,
    required this.ref,
  }) : super(key: key);

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  late String dropdownvalue = '';
  late double selectedTextSize;

  Future<void> _loadDropdownValue() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      dropdownvalue = prefs.getString('touchKey') ?? 'Default Value';
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDropdownValue();
  }

  @override
  Widget build(BuildContext context) {
    if (dropdownvalue == "Majhna") {
      selectedTextSize = 11;
    } else if (dropdownvalue == "Srednja") {
      selectedTextSize = 16;
    } else if (dropdownvalue == "Velika") {
      selectedTextSize = 26;
    } else {
      selectedTextSize = 16;
    }
    List<String> preostaleKategorije = widget.categorizedItems.keys.toList()
      ..sort();
    List<String> sortedCategories = ["Vse", ...preostaleKategorije];

    final settings = widget.ref.watch(settingsProvider);
    final defaultColors = settings['isCheckedBarve'] ?? false;
    final selectedCategoryState = widget.ref.watch(selectedCategoryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 36,
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
                widget.ref.read(selectedCategoryProvider.notifier).state =
                    category;
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
                        style: AppStyles.paragraph1.copyWith(
                            fontSize: selectedTextSize,
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
    );
  }
}
