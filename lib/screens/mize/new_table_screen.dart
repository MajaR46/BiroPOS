import 'package:biro_pos/components/ok_button.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

class NewTableScreen extends StatefulWidget {
  const NewTableScreen({super.key});

  @override
  State<NewTableScreen> createState() => _NewTableScreenState();
}

class _NewTableScreenState extends State<NewTableScreen> {
  final TextEditingController _newTableController = TextEditingController();

  void _clearText() {
    _newTableController.clear();
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
        title: Text("Nova miza",
            style: AppStyles.heading3.copyWith(color: AppStyles.black)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 64),
              Center(
                child: Text(
                  "Oznaka mize: ",
                  style: AppStyles.heading2.copyWith(color: AppStyles.black),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _newTableController,
                  cursorColor: AppStyles.blue,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppStyles.silver.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide.none,
                    ),
                    suffixIconColor: AppStyles.blue,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearText,
                      focusColor: AppStyles.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 32),
            child: Align(
              alignment: Alignment.bottomRight,
              child: OKButton(onPressed: () {
                // Pass the table number back to the previous screen
                String tableNumber = _newTableController.text;
                Navigator.of(context).pop(tableNumber);
              }),
            ),
          ),
        ],
      ),
    );
  }
}
