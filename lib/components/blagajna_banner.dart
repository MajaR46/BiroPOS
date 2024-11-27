import 'package:biro_pos/models/narociloitem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart'; // Assuming this file contains NarociloNotifier and narociloNotifierProvider

class BlagajnaBanner extends ConsumerWidget {
  const BlagajnaBanner({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access the list of items in the cart from the provider
    final cartItems = ref.watch(narociloNotifierProvider);

    // Get the currently selected item, quantity, and total sum from the cartItems
    final selectedItem = cartItems.isNotEmpty ? cartItems.last : null;
    final itemQuantity = selectedItem?.quantity ?? 0.0;
    final totalSum = ref.watch(narociloNotifierProvider.notifier).totalSum();

    // Display the banner content
    return Container(
      color: AppStyles.grey,
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Item details
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Izbrano:", style: AppStyles.paragraph3),
                Text(
                  selectedItem != null ? selectedItem.product.name : '',
                  style: AppStyles.paragraph2
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            // Quantity details
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
            // Sum details
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
      ),
    );
  }
}
