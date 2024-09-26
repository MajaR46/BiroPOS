import 'package:biro_pos/components/ok_button.dart';
import 'package:biro_pos/screens/mize/new_table_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

class AddToTableScreen extends StatefulWidget {
  final String? tableNumber;
  final double finalSum;
  const AddToTableScreen({super.key, this.tableNumber, required this.finalSum});

  // Use a map to store table numbers with their finalSum
  static Map<String, double> tableSums = {};

  @override
  State<AddToTableScreen> createState() => _AddToTableScreenState();
}

class _AddToTableScreenState extends State<AddToTableScreen> {
  void _addToTableList(String tableNumber, double sum) {
    setState(() {
      AddToTableScreen.tableSums[tableNumber] = sum;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppStyles.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Dodaj na mizo",
            style: AppStyles.heading3.copyWith(color: AppStyles.black)),
        centerTitle: true,
      ),
      body: Stack(children: [
        ListView.builder(
          itemCount: AddToTableScreen.tableSums.length,
          itemBuilder: (context, index) {
            String tableNumber =
                AddToTableScreen.tableSums.keys.elementAt(index);
            double tableFinalSum = AddToTableScreen.tableSums[tableNumber]!;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: AppStyles.silver.withOpacity(0.1),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text(
                        tableNumber,
                        style: AppStyles.heading3,
                      ),
                      const Spacer(),
                      Text(tableFinalSum.toStringAsFixed(2),
                          style: AppStyles.heading3
                              .copyWith(fontWeight: FontWeight.normal))
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 32),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: SizedBox(
              height: 50,
              width: 120,
              child: ElevatedButton(
                onPressed: () async {
                  String? newTableNumber = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NewTableScreen()),
                  );

                  if (newTableNumber != null && newTableNumber.isNotEmpty) {
                    _addToTableList(newTableNumber, widget.finalSum);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.silver.withOpacity(0.1),
                  padding: EdgeInsets.zero,
                  elevation: 0,
                ),
                child: Text(
                  "NOVA MIZA",
                  style: AppStyles.button1.copyWith(color: AppStyles.black),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 32),
          child: Align(
              alignment: Alignment.bottomRight,
              child: OKButton(onPressed: () {})),
        ),
      ]),
    );
  }
}
