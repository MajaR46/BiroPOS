import 'package:biro_pos/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ItemCard extends ConsumerWidget {
  final String itemName;
  final String itemPrice;
  final String itemCategory;
  final Color itemCategoryTextColor;
  final Color itemNameColor;
  final int stStolpcev;
  final Color cardBackground;
  final bool isAllLayout;
  final dynamic textSize;
  final double minCardHeight;

  const ItemCard(
      {super.key,
      required this.itemName,
      required this.itemPrice,
      required this.itemCategory,
      required this.itemCategoryTextColor,
      required this.itemNameColor,
      required this.stStolpcev,
      required this.cardBackground,
      required this.isAllLayout,
      required this.textSize,
      required this.minCardHeight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double paddingInCardValue = isAllLayout ? 8.0 : 8.0;
    double paddingOutCardValue = isAllLayout ? 2.0 : 0.0;
    final settings = ref.watch(settingsProvider);
    final prikaziCene = settings['isCheckedPrikazCene'] ?? false;

    return Padding(
      padding: EdgeInsets.all(paddingOutCardValue),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minCardHeight),
        child: Container(
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4.0,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(paddingInCardValue),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  itemName,
                  style: AppStyles.paragraph3.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: textSize,
                      color: itemNameColor),
                ),
                if (prikaziCene)
                  Text(
                    '${itemPrice.toString()} €',
                    style: TextStyle(fontSize: textSize - 2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                if (stStolpcev < 3)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        itemCategory,
                        style: TextStyle(
                            fontSize: textSize - 6,
                            color: itemCategoryTextColor,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
