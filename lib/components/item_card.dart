import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

class ItemCard extends StatelessWidget {
  final String itemName;
  final String itemPrice;
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
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(itemName,
                  style: AppStyles.paragraph3
                      .copyWith(fontWeight: FontWeight.bold)),
            ),
            Text('${itemPrice.toString()} €', style: AppStyles.paragraph4),
            const SizedBox(
              height: 2,
            ),
            Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(itemCategory,
                      style: AppStyles.paragraph4.copyWith(color: textColor)),
                )),
          ],
        ),
      ),
    );
  }
}
