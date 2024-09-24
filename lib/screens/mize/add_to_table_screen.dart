import 'package:biro_pos/screens/mize/new_table_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

class AddToTableScreen extends StatefulWidget {
  final String? tableNumber;
  const AddToTableScreen({super.key, this.tableNumber});

  static List<String> tables = [];

  @override
  State<AddToTableScreen> createState() => _AddToTableScreenState();
}

class _AddToTableScreenState extends State<AddToTableScreen> {
  void _addToTableList(String tableNumber) {
    setState(() {
      AddToTableScreen.tables.add(tableNumber);
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
          itemCount: AddToTableScreen.tables.length,
          itemBuilder: (context, index) {
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
                        AddToTableScreen.tables[index],
                        style: AppStyles.heading3,
                      ),
                      Spacer(),
                      Text("CENA",
                          style: AppStyles.heading3
                              .copyWith(fontWeight: FontWeight.normal))
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ElevatedButton(
            onPressed: () async {
              String? newTableNumber = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NewTableScreen()),
              );

              if (newTableNumber != null && newTableNumber.isNotEmpty) {
                _addToTableList(newTableNumber);
              }
            },
            child: Text("Nova miza"),
          ),
        ),
      ]),
    );
  }
}
