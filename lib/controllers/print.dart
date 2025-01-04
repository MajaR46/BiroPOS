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

  static Future<void> printText(BuildContext context, String text,
      String printerName, WidgetRef ref) async {
    final settings = ref.watch(settingsProvider);
    final bluetoothPrintanje = settings['isCheckedBluetoothPrintanje'] ?? false;
    final paymentMethods = ref.watch(paymentMethodProvider);

    if (paymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ne najdem načinov plačil!")),
      );
      return;
    }

    if (bluetoothPrintanje) {
      try {
        await ProcessPayment.checkBluetooth();
        await BluetoothService.sendData([text], ref, addEmptyLines: false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Napaka $e")),
        );
      }
    }

    try {
      await Utils.printTextWithIntegratedSunmi(text, printerName, ref);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Napaka $e")),
      );
    }
  }
}
