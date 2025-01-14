import 'dart:typed_data';

import 'package:biro_pos/components/utils.dart';
import 'package:biro_pos/controllers/bluetooth_controller.dart';
import 'package:biro_pos/controllers/process_payment.dart';
import 'package:biro_pos/providers/direct_payment_provider.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:sunmi_printer_plus/sunmi_style.dart';

class Print {
  final WidgetRef ref;

  Print(this.ref);

  static Future<void> printText(BuildContext context, List<String> text,
      String printerName, WidgetRef ref) async {
    final settings = ref.watch(settingsProvider);
    final bluetoothPrintanje = settings['isCheckedBluetoothPrintanje'] ?? false;
    final paymentMethods = ref.watch(paymentMethodProvider);

    if (bluetoothPrintanje == true) {
      try {
        await ProcessPayment.checkBluetooth();
        await BluetoothService.sendData(text, ref, addEmptyLines: true);

        print("PRINTANO Z BLUETOOTH");
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Napaka $e")),
        );
        return;
      }
    } else {
      try {
        await Utils.printTextWithIntegratedSunmi(
            text.join('\n'), printerName, ref);
        print("PRINTANO Z INTEGRIRANIM");
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Napaka $e")),
        );
      }
    }
  }
}
