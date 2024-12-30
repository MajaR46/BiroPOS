import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

class ItemCard extends StatelessWidget {
  final String itemName;
  final String itemPrice;
  final String itemCategory;
  final Color backgroundColor;
  final Color textColor;
  final int stStolpcev;
  final Color cardBackground;
  final bool isAllLayout;

  const ItemCard(
      {super.key,
      required this.itemName,
      required this.itemPrice,
      required this.itemCategory,
      required this.backgroundColor,
      required this.textColor,
      required this.stStolpcev,
      required this.cardBackground,
      required this.isAllLayout});

  @override
  Widget build(BuildContext context) {
    double paddingInCardValue = isAllLayout ? 12.0 : 4.0;
    double paddingOutCardValue = isAllLayout ? 2.0 : 0.0;

    return Padding(
      padding: EdgeInsets.all(paddingOutCardValue),
      child: Container(
        decoration: BoxDecoration(
          color: stStolpcev > 3 ? cardBackground : AppStyles.white,
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
                style:
                    AppStyles.paragraph3.copyWith(fontWeight: FontWeight.bold),
                maxLines: 3, // Limit to 4 lines
                overflow: TextOverflow
                    .ellipsis, // Show ellipsis if the text exceeds 4 lines
              ),
              if (stStolpcev < 3)
                Text(
                  '${itemPrice.toString()} €',
                  style: AppStyles.paragraph4,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 2),
              if (stStolpcev < 3)
                Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      itemCategory,
                      style: AppStyles.paragraph4.copyWith(
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
