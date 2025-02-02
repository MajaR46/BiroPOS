import 'package:biro_pos/app_styles.dart';
import 'package:biro_pos/components/numpad.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class DavcnaStrankaScreen extends ConsumerWidget {
  final TextEditingController _strankaController = TextEditingController();

  DavcnaStrankaScreen({super.key});

  void _clearText() {
    _strankaController.clear();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void _setDavcna() {
      final String davcnaSt = _strankaController.text;

      if (davcnaSt.length == 8) {
        ref.read(taxNumberProvider.notifier).state = davcnaSt;

        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Davčna številka mora imeti 8 znakov!")));
      }
    }

    return Scaffold(
      backgroundColor: AppStyles.white,
      appBar: AppBar(
        backgroundColor: AppStyles.white,
        title: Text(
          "Davčna stranka",
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
                autofocus: true,
                showCursor: true,
                readOnly: true,
                controller: _strankaController,
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
            Numpad(controller: _strankaController, onOKPressed: _setDavcna),
          ],
        ),
      ),
    );
  }
}
