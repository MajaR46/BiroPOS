import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

class ItemCard extends StatelessWidget {
  final String itemName;
  final double itemPrice;
  final String itemCategory;
  final Color backgroundColor;
  final Color textColor;

  const ItemCard(
      {super.key,
      required this.itemName,
      required this.itemPrice,
      required this.itemCategory,
      required this.backgroundColor,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppStyles.white,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(itemName, style: AppStyles.boldanparagraph1),
            ),
            Text('${itemPrice.toString()}\€', style: AppStyles.paragraph3),
            SizedBox(
              height: 8,
            ),
            Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(itemCategory,
                      style: AppStyles.paragraph3.copyWith(color: textColor)),
                )),
          ],
        ),
      ),
    );
  }
}
