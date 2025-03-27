import 'package:biro_pos/app_styles.dart';
import 'package:biro_pos/providers/selectedcategory_provider.dart';
import 'package:biro_pos/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryList extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
          itemBuilder: (context, index) {
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
                        style: AppStyles.paragraph1.copyWith(
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
