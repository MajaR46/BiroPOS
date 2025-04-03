import 'package:biro_pos/components/quantity_increase.dart';
import 'package:biro_pos/components/racun_list_banner.dart';
import 'package:biro_pos/models/item.dart';
import 'package:biro_pos/models/narociloitem.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/providers/selecteditem_provider.dart';
import 'package:biro_pos/screens/edit_item_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SeznamRacun extends ConsumerWidget {
  final List<NarociloItem> chosenItems;
  final double totalSum;
  final double totalDiscount;
  final Function(String?, String, double, bool, [double?]) openDialog;
  final Function(String, double, String, double) removeItem;
  final Function(double, String, String, double, double) handleQuantityChange;

  const SeznamRacun({
    Key? key,
    required this.chosenItems,
    required this.totalSum,
    required this.totalDiscount,
    required this.openDialog,
    required this.removeItem,
    required this.handleQuantityChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: chosenItems.length,
              itemBuilder: (context, index) {
                final item = chosenItems[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name,
                                    style: AppStyles.boldanparagraph1),
                                Text(
                                  item.description ?? '',
                                  style: AppStyles.paragraph4
                                      .copyWith(fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text('${item.product.price.toString()}€',
                                style: AppStyles.heading3),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton.filled(
                            style: IconButton.styleFrom(
                                backgroundColor: AppStyles.blue),
                            onPressed: () {
                              HapticFeedback.vibrate();
                              FocusScope.of(context).unfocus();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditItemScreen(
                                    itemName: item.product.name,
                                    itemCategory: item.product.categoryID,
                                    itemPrice: item.product.price,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                                backgroundColor: AppStyles.green),
                            onPressed: () {
                              HapticFeedback.vibrate();
                              openDialog(item.product.id, item.description,
                                  item.product.price, false);
                            },
                            icon: const Icon(Icons.percent),
                          ),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                                backgroundColor: AppStyles.brightRed),
                            onPressed: () {
                              HapticFeedback.vibrate();
                              removeItem(
                                item.product.id,
                                item.product.price,
                                item.description,
                                item.quantity,
                              );
                              ref.read(selectedItemProvider.notifier).state =
                                  null;
                            },
                            icon: const Icon(Icons.delete),
                          ),
                          const Spacer(),
                          QuantityIncrease(
                            quantity: item.quantity,
                            onQuantityChanged: (newQuantity) {
                              handleQuantityChange(
                                newQuantity,
                                item.product.id,
                                item.description,
                                item.product.price,
                                item.quantity,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
