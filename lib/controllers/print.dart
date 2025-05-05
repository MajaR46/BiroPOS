import 'dart:io';
import 'dart:typed_data';

import 'package:BiroPOS/components/usb_printer.dart';
import 'package:BiroPOS/components/utils.dart';
import 'package:BiroPOS/controllers/bluetooth_controller.dart';
import 'package:BiroPOS/controllers/process_payment.dart';
import 'package:BiroPOS/controllers/save_to_txt.dart';
import 'package:BiroPOS/providers/direct_payment_provider.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/searchquery_provider.dart';
import 'package:BiroPOS/providers/selecteditem_provider.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
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
    final usbPrintanje = settings['isCheckedUsbPrintanje'] ?? false;

    final paymentMethods = ref.watch(paymentMethodProvider);

    BluetoothService bluetoothService = BluetoothService();

    if (text.any((line) => line.contains("#NAPAKA#"))) {
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

          // Add new line before every item
          await BluetoothService.sendData(text, ref,
              context: context, addEmptyLines: true);

          ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
          clearSelectedItem(ref);
          clearSearchQuery(ref);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Napaka $e")),
          );
          return;
        }
      } else if (usbPrintanje) {
        try {
          await UsbPrint.sendDataUsb(text);
          ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
          clearSelectedItem(ref);
          clearSearchQuery(ref);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Napaka $e")),
          );
          return;
        }
      } else if (Platform.isWindows) {
        List<String> cleanLines = ocistiVrstice(text);
        String finalReceiptLines = cleanLines.join('\n');
        saveFileNextToExe(finalReceiptLines, context, ref);
      } else {
        try {
          await Future.delayed(Duration(seconds: 2));

          await Utils.printTextWithIntegratedSunmi(
              context, text.join('\n'), ref);
          ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
          clearSelectedItem(ref);
          clearSearchQuery(ref);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Napaka $e")),
          );
        }
      }
    }
  }
}
