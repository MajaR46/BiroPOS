import 'dart:io';
import 'dart:typed_data';

import 'package:biro_pos/components/utils.dart';
import 'package:biro_pos/controllers/bluetooth_controller.dart';
import 'package:biro_pos/controllers/process_payment.dart';
import 'package:biro_pos/providers/direct_payment_provider.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/providers/searchquery_provider.dart';
import 'package:biro_pos/providers/selecteditem_provider.dart';
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
    final bluetoothPrintanje = settings['isCheckedBluetoothPrintanje'] ?? true;
    final paymentMethods = ref.watch(paymentMethodProvider);
    print(
        "Bluetooth printanje: $bluetoothPrintanje"); // <- DODANO ZA PREVERJANJE
    BluetoothService bluetoothService = BluetoothService();

    if (text.any((line) => line.contains("#NAPAKA#"))) {
      print("response contains napaka");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(text
                .toString())), // Lahko tudi izpišeš celoten seznam za boljši vpogled
      );
      return; // Prepreči nadaljnje obdelave in tiskanje
    } else {
      if (bluetoothPrintanje == true) {
        try {
          bool isConnected =
              await ProcessPayment.isBluetoothConnected(context, text);
          if (isConnected == false) {
            await bluetoothService.connectToDevice(context);
          }

          print("Attempting to print via Bluetooth...");

          // Add new line before every item
          await BluetoothService.sendData(text, ref,
              context: context, addEmptyLines: true);

          print("Data sent to Bluetooth printer.");
          ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
          clearSelectedItem(ref);
          clearSearchQuery(ref);
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
              context, text.join('\n'), ref);
          ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
          clearSelectedItem(ref);
          clearSearchQuery(ref);
          print("PRINTANO Z INTEGRIRANIM");
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Napaka $e")),
          );
        }
      }
    }
  }
}
