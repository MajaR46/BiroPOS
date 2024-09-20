import 'package:biro_pos/components/quantity_increase.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter/widgets.dart';

class RacunScreen extends StatefulWidget {
  final dynamic selectedItem;
  final double itemQuantity;
  final double finalSum;
  final List<dynamic> chosenItems;

  RacunScreen({
    Key? key,
    required this.selectedItem,
    required this.itemQuantity,
    required this.finalSum,
    required this.chosenItems,
  }) : super(key: key);

  @override
  State<RacunScreen> createState() => _RacunScreenState();
}

class _RacunScreenState extends State<RacunScreen> {
  late double finalSum;
  late List<dynamic> chosenItems;

  @override
  void initState() {
    super.initState();
    finalSum = widget.finalSum;
    chosenItems = widget.chosenItems;
  }

  // Function to handle quantity changes
  void _handleQuantityChange(double newQuantity, int index) {
    setState(() {
      chosenItems[index]['quantity'] = newQuantity;
      _updateFinalSum();
    });
  }

  // Function to update the final sum based on item quantities and prices
  void _updateFinalSum() {
    double newFinalSum = 0;

    for (var item in chosenItems) {
      double itemTotal = item['quantity'] * (item['price'] ?? 0);
      newFinalSum += itemTotal;
    }

    setState(() {
      finalSum = newFinalSum;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppStyles.black),
          onPressed: () => Navigator.pop(context, {
            'updatedQuantity':
                chosenItems.map((item) => item['quantity'] as double).toList(),
            'updatedFinalSum': finalSum,
          }),
        ),
        title: Text(
          "Račun",
          style: AppStyles.heading3.copyWith(color: AppStyles.black),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: chosenItems.length,
              itemBuilder: (context, index) {
                final item = chosenItems[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'],
                                style: AppStyles.boldanparagraph1),
                            Text('${item['price'].toString()}€',
                                style: AppStyles.paragraph4),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                            backgroundColor: AppStyles.blue),
                        onPressed: () {},
                        icon: const Icon(Icons.edit),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: IconButton.filled(
                          style: IconButton.styleFrom(
                              backgroundColor: AppStyles.darkGreen),
                          onPressed: () {},
                          icon: const Icon(Icons.percent),
                        ),
                      ),
                      QuantityIncrease(
                        quantity: item['quantity'],
                        onQuantityChanged: (newQuantity) {
                          _handleQuantityChange(newQuantity, index);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            color: AppStyles.silver.withOpacity(0.1),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text(
                        "POPUST:",
                        style: AppStyles.heading3
                            .copyWith(fontWeight: FontWeight.normal),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {},
                        child: Text("5%",
                            style: AppStyles.button1
                                .copyWith(color: AppStyles.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.white,
                          elevation: 1,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 50),
                        ),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton(
                        onPressed: () {},
                        child: Text("10%",
                            style: AppStyles.button1
                                .copyWith(color: AppStyles.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.white,
                          elevation: 1,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 50),
                        ),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        child: Text("15%",
                            style: AppStyles.button1
                                .copyWith(color: AppStyles.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.white,
                          elevation: 1,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 50),
                        ),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        child: Text("?%",
                            style: AppStyles.button1
                                .copyWith(color: AppStyles.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.white,
                          elevation: 1,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 50),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Text("SKUPAJ:", style: AppStyles.heading3),
                      const Spacer(),
                      Text(
                        '$finalSum €',
                        style: AppStyles.cardItemName.copyWith(
                            color: AppStyles.black,
                            fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: Text(
                          "GOTOVINA",
                          style: AppStyles.button2
                              .copyWith(color: AppStyles.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.darkOrange,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(100, 50),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        child: Text("KARTICA",
                            style: AppStyles.button2
                                .copyWith(color: AppStyles.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.red,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(100, 50),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        child: Text("OSTALO",
                            style: AppStyles.button2
                                .copyWith(color: AppStyles.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.blue,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(100, 50),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 16,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
