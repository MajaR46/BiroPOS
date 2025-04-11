import 'package:BiroPOS/app_styles.dart';
import 'package:flutter/material.dart';

class RacunListBanner extends StatelessWidget {
  final double totalDiscount;
  final double totalSum;

  const RacunListBanner(
      {Key? key, required this.totalDiscount, required this.totalSum})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppStyles.lightGrey,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text("Vrednost popusta: "),
                const Spacer(),
                Text('${totalDiscount.toStringAsFixed(2)} €')
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Row(
              children: [
                const Text("SKUPAJ:", style: AppStyles.heading4),
                const Spacer(),
                Text(
                  '${totalSum.toStringAsFixed(2)} €',
                  style: AppStyles.cardItemName.copyWith(
                      color: AppStyles.black, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
