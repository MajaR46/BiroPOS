import 'package:BiroPOS/app_styles.dart';
import 'package:flutter/material.dart';

class RacunListBanner extends StatelessWidget {
  final double totalDiscount;
  final double totalSum;
  final TextEditingController controller;

  const RacunListBanner(
      {Key? key,
      required this.totalDiscount,
      required this.totalSum,
      required this.controller})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppStyles.lightGrey,
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 2 / 3,
                  ),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable:
                        controller, // Poslušaj spremembe controllerja
                    builder: (context, textEditingValue, child) {
                      String currentText = textEditingValue.text;
                      String filtriranSearch =
                          currentText.replaceAll(RegExp(r'[^0-9]'), '');

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            filtriranSearch,
                            style: AppStyles.paragraph3
                                .copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      );
                    },
                  ),
                  // --- KONEC SPREMEMBE ---
                ),
              ),
            ],
          ),
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
