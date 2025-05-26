import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/selecteditem_provider.dart';

class BlagajnaBanner extends ConsumerWidget {
  final TextEditingController controller;

  const BlagajnaBanner({required this.controller, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Opazuj stanja, ki niso odvisna od controllerja tukaj
    final selectedItem = ref.watch(selectedItemProvider);
    final itemQuantity = selectedItem?.quantity ?? 0.0;
    final totalSum = ref.watch(narociloNotifierProvider.notifier).totalSum();

    // Uporabi ValueListenableBuilder za del, ki prikazuje vnos
    return Container(
      color: AppStyles.lightGrey,
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Item details - Ovijemo z ValueListenableBuilder
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 2 / 3,
                    ),
                    // --- ZAČETEK SPREMEMBE ---
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text("Izbrano:", style: AppStyles.paragraph3),
                        Text(
                          (selectedItem != null
                              ? selectedItem.product.name
                              : ''),
                          style: AppStyles.paragraph2
                              .copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Količina:", style: AppStyles.paragraph3),
                    Text(
                      itemQuantity.toStringAsFixed(2),
                      style: AppStyles.paragraph2
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Sum details (ostane enako)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Znesek:", style: AppStyles.paragraph3),
                    Text(
                      totalSum.toStringAsFixed(2),
                      style: AppStyles.paragraph2.copyWith(
                          fontWeight: FontWeight.bold, color: AppStyles.blue),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
