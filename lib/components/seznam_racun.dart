import 'package:BiroPOS/components/quantity_increase.dart';
import 'package:BiroPOS/models/narociloitem.dart';
import 'package:BiroPOS/providers/selecteditem_provider.dart';
import 'package:BiroPOS/screens/edit_item_screen.dart';
import 'package:flutter/material.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SeznamRacun extends ConsumerStatefulWidget {
  final List chosenItems;
  final double totalSum;
  final double totalDiscount;
  final Function(String?, String?, String, double, bool, [double?]) openDialog;
  final Function(String, double, String, double) removeItem;
  final Function(String, String, String, double, double, double)
      handleQuantityChange;

  const SeznamRacun({
    super.key,
    required this.chosenItems,
    required this.totalSum,
    required this.totalDiscount,
    required this.openDialog,
    required this.removeItem,
    required this.handleQuantityChange,
  });

  @override
  ConsumerState<SeznamRacun> createState() => _SeznamRacunState();
}

class _SeznamRacunState extends ConsumerState<SeznamRacun> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.chosenItems.isNotEmpty &&
          ref.read(selectedItemProvider) == null) {
        ref.read(selectedItemProvider.notifier).state = widget.chosenItems.last;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: widget.chosenItems.length,
            itemBuilder: (context, index) {
              final item = widget.chosenItems[index];
              final isSelected =
                  ref.watch(selectedItemProvider)?.uniqueId == item.uniqueId;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: GestureDetector(
                  onTap: () {
                    ref.read(selectedItemProvider.notifier).state = item;
                    HapticFeedback.vibrate();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: isSelected
                            ? AppStyles.lightBlue.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
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
                                      item.description,
                                      style: AppStyles.paragraph4.copyWith(
                                          fontStyle: FontStyle.italic),
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
                                        narociloItemUniqueId: item.uniqueId,
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
                                  widget.openDialog(
                                      item.uniqueId,
                                      item.product.id,
                                      item.description,
                                      item.product.price,
                                      false);
                                },
                                icon: const Icon(Icons.percent),
                              ),
                              IconButton.filled(
                                style: IconButton.styleFrom(
                                    backgroundColor: AppStyles.brightRed),
                                onPressed: () {
                                  HapticFeedback.vibrate();
                                  widget.removeItem(
                                    item.product.id,
                                    item.product.price,
                                    item.description,
                                    item.quantity,
                                  );
                                  ref
                                      .read(selectedItemProvider.notifier)
                                      .state = null;
                                },
                                icon: const Icon(Icons.delete),
                              ),
                              const Spacer(),
                              QuantityIncrease(
                                quantity: item.quantity,
                                onQuantityChanged: (newQuantity) {
                                  widget.handleQuantityChange(
                                    item.uniqueId,
                                    item.product.id,
                                    item.description,
                                    newQuantity,
                                    item.product.price,
                                    item.quantity,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
