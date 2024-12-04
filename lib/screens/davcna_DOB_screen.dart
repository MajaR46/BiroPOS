import 'package:biro_pos/components/numpad.dart';
import 'package:biro_pos/providers/direct_payment_provider.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/screens/blagajna_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DavcnaDOBScreen extends ConsumerStatefulWidget {
  const DavcnaDOBScreen({
    super.key,
  });

  @override
  ConsumerState<DavcnaDOBScreen> createState() => _DavcnaDOBScreenState();
}

class _DavcnaDOBScreenState extends ConsumerState<DavcnaDOBScreen> {
  final TextEditingController _dobController = TextEditingController();
  late OrderService orderService;

  @override
  void initState() {
    super.initState();
    orderService = ref.read(orderProvider);
  }

  void _clearText() {
    _dobController.clear();
  }

  void _showResponseDialog(
    List<String> response,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Server Response"),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(response.join('\n')), // Display the response line by line
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BlagajnaScreen()));
                clearDavcna(
                    ref); // Execute the callback to clear items after dialog is closed
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    void createOrder(davcnaSt) async {
      if (davcnaSt != null) {
        final response = await orderService.createOrder(
            context, "TipDokumenta.DOB", davcnaSt);
        _showResponseDialog(response);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Ni vnesene davčne")));
      }
    }

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
                showCursor: true,
                readOnly: true,
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
            Numpad(
                controller: _dobController,
                onOKPressed: () => {createOrder(_dobController.text)})
          ],
        ),
      ),
    );
  }
}
