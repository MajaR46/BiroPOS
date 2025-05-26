import 'dart:io';

import 'package:BiroPOS/components/usb_printer.dart';
import 'package:BiroPOS/utils/ethernet_print.dart';
import 'package:BiroPOS/utils/generate_receipt_code.dart';
import 'package:BiroPOS/utils/utils.dart';
import 'package:BiroPOS/controllers/bluetooth_controller.dart';
import 'package:BiroPOS/controllers/process_payment.dart';
import 'package:BiroPOS/utils/save_to_txt.dart';
import 'package:BiroPOS/providers/direct_payment_provider.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/searchquery_provider.dart';
import 'package:BiroPOS/providers/selecteditem_provider.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Print {
  final WidgetRef ref;

  Print(this.ref);

  static Future<void> printText(
      BuildContext context, List<String> text, WidgetRef ref) async {
    final settings = ref.watch(settingsProvider);
    final bluetoothPrintanje = settings['isCheckedBluetoothPrintanje'] ?? true;
    final usbPrintanje = settings['isCheckedUsbPrintanje'] ?? false;
    final ethernetPrintanje = settings['isCheckedEthernetPrint'] ?? false;
    final receiptCode = settings['isCheckedReceiptCode'] ?? false;
    bool isBesteronSucess = true;
    final paymentMethods = ref.watch(paymentMethodProvider);
    List<String> modifiedResponse;

    BluetoothService bluetoothService = BluetoothService();

    if (text.any((line) => line.contains("#NAPAKA#"))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text.toString())),
      );
      return;
    } else {
      if (receiptCode == true) {
        modifiedResponse = insertCodeInReceipt(text);
      } else {
        modifiedResponse = text;
      }

      if (bluetoothPrintanje == true) {
        try {
          bool isConnected = await ProcessPayment.isBluetoothConnected(
              context, modifiedResponse);
          if (isConnected == false) {
            await bluetoothService.connectToDevice(context);
          }

          await BluetoothService.sendData(modifiedResponse, ref,
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
          await UsbPrint.sendDataUsb(modifiedResponse);
          ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
          clearSelectedItem(ref);
          clearSearchQuery(ref);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Napaka $e")),
          );
          return;
        }
      } else if (ethernetPrintanje) {
        printReceipt(
            modifiedResponse.join('\n'), context, ref, isBesteronSucess);
      } else if (Platform.isWindows) {
        List<String> cleanLines = ocistiVrstice(modifiedResponse);
        String finalReceiptLines = cleanLines.join('\n');
        saveFileNextToExe(finalReceiptLines, context, ref, isBesteronSucess);
      } else {
        try {
          await Future.delayed(Duration(seconds: 2));

          await Utils.printTextWithIntegratedSunmi(
              context, modifiedResponse.join('\n'), ref, isBesteronSucess);
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
