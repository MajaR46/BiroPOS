import 'package:biro_pos/components/error_dialog.dart';
import 'package:biro_pos/components/numpad.dart';
import 'package:biro_pos/controllers/print.dart';
import 'package:biro_pos/providers/direct_payment_provider.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/screens/blagajna_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter/services.dart';
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

  void _processAndPrintResponse(List<String> apiResponse) async {
    try {
      await Future.wait([
        Print.printText(context, apiResponse, ref),
        Print.printText(context, apiResponse, ref)
      ]);

      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BlagajnaScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Napaka pri tiskanju: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    void createOrder(davcnaSt) async {
      try {
        int? davcnaNumber = int.tryParse(davcnaSt); // Convert to int

        if (davcnaNumber != null && davcnaSt.length == 8) {
          final response = await orderService.createOrder(
              context, "TipDokumenta.DOB", davcnaSt);
          _processAndPrintResponse(response);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Davčna številka mora biti dolga 8 znakov")));
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Napaka: $e")));
      }
    }

    return Scaffold(
      backgroundColor: AppStyles.white,
      appBar: AppBar(
        backgroundColor: AppStyles.white,
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
                autofocus: true,
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
