import 'package:biro_pos/components/ok_button.dart';
import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/screens/mize/new_table_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

class AddToTableScreen extends StatefulWidget {
  final String? tableNumber;
  final double finalSum;
  final dynamic selectedItem;
  final double itemQuantity;
  final List<dynamic> chosenItems;
  const AddToTableScreen(
      {super.key,
      this.tableNumber,
      required this.finalSum,
      required this.itemQuantity,
      required this.chosenItems,
      required this.selectedItem});

  // Use a map to store table numbers with their finalSum
  static Map<String, double> tableSums = {};

  @override
  State<AddToTableScreen> createState() => _AddToTableScreenState();
}

class _AddToTableScreenState extends State<AddToTableScreen> {
  List<Map<String, String>> tables = [];
  Map<String, List<String>> tableItems = {};

  late List<dynamic> chosenItems;

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTables();
    chosenItems = widget.chosenItems;
  }

  Future<void> _fetchTables() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<String> apiResponseList = await sendRequest("1", "VrniSeznamMiz");

      List<Map<String, String>> parsedTables = [];

      for (String line in apiResponseList) {
        List<String> splitLine = line.split('|');

        if (splitLine.length >= 4) {
          String prostor = splitLine[0];
          String miza = splitLine[1];
          String cena = splitLine[2]
              .replaceAll(',', '.'); // Handle possible comma decimal

          parsedTables.add({
            'miza': miza,
            'prostor': prostor,
            'cena': cena.isNotEmpty ? cena : '',
          });
        }
      }

      setState(() {
        tables = parsedTables;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching tables: $e';
        _isLoading = false;
      });
    }
  }

  // Add to table list or update if it already exists
  void _addToTableList(String tableNumber, double sum) {
    setState(() {
      // Update the sum for the table
      if (AddToTableScreen.tableSums.containsKey(tableNumber)) {
        AddToTableScreen.tableSums[tableNumber] =
            AddToTableScreen.tableSums[tableNumber]! + sum;
      } else {
        AddToTableScreen.tableSums[tableNumber] = sum;
      }

      // Add the selected items to the tableItems map
      if (tableItems.containsKey(tableNumber)) {
        tableItems[tableNumber]!
            .addAll(chosenItems.map((item) => item['name'] as String));
      } else {
        tableItems[tableNumber] =
            chosenItems.map((item) => item['name'] as String).toList();
      }

      // Update the table's sum in the `tables` list
      for (var table in tables) {
        if (table['miza'] == tableNumber) {
          double currentSum = double.tryParse(table['cena']!) ?? 0.0;
          currentSum += sum;
          table['cena'] = currentSum.toStringAsFixed(2);
          break;
        }
      }
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
      body: Stack(
        children: [
          if (_isLoading)
            Center(
                child:
                    CircularProgressIndicator()) // Show a loading spinner if loading
          else
            ListView.builder(
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final tableData = tables[index];
                String tableNumber = tableData['miza'] ?? '';
                double tableFinalSum = tableData['cena'] != null
                    ? double.tryParse(tableData['cena'].toString()) ?? 0.0
                    : 0.0;
                List<String> itemsForTable = tableItems[tableNumber] ?? [];

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GestureDetector(
                    onTap: () {
                      _addToTableList(tableNumber, widget.finalSum);
                      print('Added ${widget.finalSum} to table $tableNumber');
                    },
                    child: Card(
                      color: AppStyles.silver.withOpacity(0.1),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Table: $tableNumber',
                                  style: AppStyles.heading3,
                                ),
                                const Spacer(),
                                Text(
                                  'Total: ${tableFinalSum.toStringAsFixed(2)}',
                                  style: AppStyles.heading3
                                      .copyWith(fontWeight: FontWeight.normal),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Items:',
                              style: AppStyles.heading4,
                            ),
                            ...itemsForTable.map((item) => Text(item)).toList(),
                          ],
                        ),
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
              child: OKButton(onPressed: () {
                // You can add functionality for the OK button here
              }),
            ),
          ),
        ],
      ),
    );
  }
}
