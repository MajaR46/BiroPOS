import 'dart:io';
import 'dart:typed_data';

import 'package:biro_pos/components/utils.dart';
import 'package:biro_pos/controllers/bluetooth_controller.dart';
import 'package:biro_pos/controllers/process_payment.dart';
import 'package:biro_pos/providers/direct_payment_provider.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

class Print {
  final WidgetRef ref;

  Print(this.ref);

  static Future<void> printText(
      BuildContext context, List<String> text, WidgetRef ref) async {
    final settings = ref.watch(settingsProvider);
    final bluetoothPrintanje = settings['isCheckedBluetoothPrintanje'] ?? false;
    final paymentMethods = ref.watch(paymentMethodProvider);
    print(
        "Bluetooth printanje: $bluetoothPrintanje"); // <- DODANO ZA PREVERJANJE

    if (bluetoothPrintanje == true) {
      try {
        await ProcessPayment.isBluetoothConnected(context, text);

        print("Attempting to print via Bluetooth...");

        // Add new line before every item
        await BluetoothService.sendData(text, ref,
            context: context, addEmptyLines: true);

        print("Data sent to Bluetooth printer.");

        print("PRINTANO Z BLUETOOTH");
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Napaka $e")),
        );
        return;
      }
    } else {
      try {
        await Utils.printTextWithIntegratedSunmi(context, text.join('\n'), ref);
        print("PRINTANO Z INTEGRIRANIM");
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Napaka $e")),
        );
      }
    }
  }
}
