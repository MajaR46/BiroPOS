import 'package:biro_pos/components/numpad.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

class DavcnaDOBScreen extends StatelessWidget {
  final TextEditingController _dobController = TextEditingController();

  DavcnaDOBScreen({
    super.key,
  });

  void _clearText() {
    _dobController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Davčna DOB",
          style: AppStyles.heading3.copyWith(color: AppStyles.black),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppStyles.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 64),
        child: Column(
          children: [
            const Text(
              "Številka: ",
              style: AppStyles.heading2,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 300,
              child: TextField(
                controller: _dobController,
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
            Numpad(controller: _dobController, onOKPressed: () {})
          ],
        ),
      ),
    );
  }
}
