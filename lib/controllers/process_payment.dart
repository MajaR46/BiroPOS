import 'dart:async';
import 'dart:io';

import 'package:BiroPOS/components/usb_printer.dart';
import 'package:BiroPOS/utils/ethernet_print.dart';
import 'package:BiroPOS/utils/generate_receipt_code.dart';
import 'package:BiroPOS/utils/utils.dart';
import 'package:BiroPOS/controllers/bluetooth_controller.dart';
import 'package:BiroPOS/controllers/besteron_controller.dart';
import 'package:BiroPOS/utils/save_to_txt.dart';
import 'package:BiroPOS/providers/direct_payment_provider.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/searchquery_provider.dart';
import 'package:BiroPOS/providers/selecteditem_provider.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:BiroPOS/providers/totdal_sum_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProcessPayment {
  final WidgetRef ref;

  ProcessPayment(this.ref);

  Future<void> processPayment(BuildContext context, String paymentType,
      [String? davcnaSt]) async {
    double finalSum = ref.watch(narociloNotifierProvider.notifier).totalSum();
    final settings = ref.watch(settingsProvider);
    final bluetoothPrintanje = settings['isCheckedBluetoothPrintanje'] ?? false;
    final usbPrintanje = settings['isCheckedUsbPrintanje'] ?? false;
    final receiptCode = settings['isCheckedReceiptCode'] ?? false;
    final ethernetPrintanje = settings['isCheckedEthernetPrint'] ?? false;
    bool isBesteronSucess = true;

    final paymentMethods = ref.watch(paymentMethodProvider);

    final prefs = await SharedPreferences.getInstance();

    String? posUrlNastavitve = prefs.getString('POS') ?? "";
    String? tid = prefs.getString('TID');

    if (paymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ne najdem načinov plačil!")),
      );
      return;
    }

    if (paymentType == "KAR" && posUrlNastavitve.isNotEmpty) {
      try {
        final besteronResponse = await callBesteron(finalSum);
        String result = besteronResponse['result'];
        String besteronRacun = besteronResponse['receipt'];
        if (result != "Success") {
          isBesteronSucess = false;
        }
        if (bluetoothPrintanje) {
          await BluetoothService.sendData([besteronRacun], ref,
              addEmptyLines: false, context: context, showDialog: false);
        } else if (usbPrintanje) {
          await UsbPrint.sendDataUsb([besteronRacun]);
        } else if (ethernetPrintanje) {
          printReceipt(besteronRacun, context, ref, isBesteronSucess);
        } else if (Platform.isWindows) {
          List<String> cleanLines = ocistiVrstice([besteronRacun]);
          String finalReceiptLines = cleanLines.join('\n');
          saveFileNextToExe(finalReceiptLines, context, ref, isBesteronSucess);
        } else {
          await Utils.printTextWithIntegratedSunmi(
              context, besteronRacun, ref, isBesteronSucess);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Napaka pri komunikaciji z Besteronom: ${e.toString()}"),
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }
    }

    // Gotovina
    try {
      List<String> modifiedResponse;
      List<String> response = [];

      if (isBesteronSucess) {
        response = await ref
            .read(orderProvider)
            .createOrder(context, paymentType, davcnaSt);
      }

      if (receiptCode == true) {
        modifiedResponse = insertCodeInReceipt(response);
      } else {
        modifiedResponse = response;
      }

      if (isBesteronSucess == true) {
        if (bluetoothPrintanje) {
          await _processBluetoothPrinting(context, modifiedResponse,
              paymentType, finalSum, isBesteronSucess);
        } else if (usbPrintanje) {
          await _processUsbPrinting(modifiedResponse, isBesteronSucess);
        } else if (ethernetPrintanje) {
          printReceipt(
              modifiedResponse.join('\n'), context, ref, isBesteronSucess);
        } else if (Platform.isWindows) {
          List<String> cleanLines = ocistiVrstice(modifiedResponse);
          String finalReceiptLines = cleanLines.join('\n');
          saveFileNextToExe(finalReceiptLines, context, ref, isBesteronSucess);
        } else {
          await _processInnerPrinting(context, modifiedResponse, paymentType,
              finalSum, isBesteronSucess);
        }
        _updateFinalSum();
      }
    } catch (e) {
      String errorMessage = 'An unknown error occurred';
      if (e is SocketException) {
        errorMessage = 'Network Error: Unable to reach server. ${e.message}';
      } else if (e is TimeoutException) {
        errorMessage =
            'Timeout Error: The request timed out. Please try again.';
      } else {
        errorMessage = e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _processBluetoothPrinting(
      BuildContext context,
      List<String> response,
      String paymentType,
      double finalSum,
      bool isBesteronSucess) async {
    try {
      try {
        await isBluetoothConnected(
            context, response); // Preverimo povezavo z Bluetoothom
        await BluetoothService.sendData(response, ref,
            context: context, addEmptyLines: true);

        if (isBesteronSucess) {
          ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
          clearSelectedItem(ref);
          clearSearchQuery(ref);
        }
      } catch (e) {
        // Napaka pri pošiljanju podatkov preko Bluetootha
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Napaka pri pošiljanju podatkov preko Bluetootha: ${e.toString()}"),
            duration: const Duration(seconds: 5), // Daljša prikaz napake
          ),
        );
      } finally {
        // Set total to zero in case of error or success
        ref.read(totalSumProvider.notifier).state =
            ref.read(narociloNotifierProvider.notifier).totalSum();
      }
    } catch (e) {
      // Splošna napaka pri obdelavi plačila
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Napaka pri obdelavi plačila: ${e.toString()}"),
          duration: const Duration(seconds: 5), // Daljša prikaz napake
        ),
      );
    } finally {
      // Set total to zero in case of error or success
      ref.read(totalSumProvider.notifier).state =
          ref.read(narociloNotifierProvider.notifier).totalSum();
    }
  }

  static Future<bool> isBluetoothConnected(
      BuildContext context, List<String> response) async {
    // Added BuildContext
    try {
      final bluetoothConnected = await BluetoothService.isBluetoothConnected();
      final bluetoothEnabled = await BluetoothService.isBluetoothEnabled();

      if (!bluetoothConnected || !bluetoothEnabled) {
        // await ErrorDialogs.showBluetoothErrorDialog(context, response);
        // await ErrorDialogs.showResponseDialog(response, context!);
        return false; // Bluetooth is not connected or enabled
      }
      return true; // Bluetooth is connected and enabled
    } catch (e) {
      // Handle any errors during the Bluetooth check
      return false; // Consider Bluetooth not connected in case of an error
    }
  }

  Future<void> _processUsbPrinting(
      List<String> response, bool isBesteronSucess) async {
    final filteredResponse = Utils.filterEmptyLines(response);

    await UsbPrint.sendDataUsb(filteredResponse);
    if (isBesteronSucess) {
      ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
      clearSelectedItem(ref);
      clearSearchQuery(ref);
    }
  }

  Future<void> _processInnerPrinting(
      BuildContext context,
      List<String> response,
      String paymentType,
      double finalSum,
      bool isBesteronSucess,
      {String? davcnaSt}) async {
    final filteredResponse = Utils.filterEmptyLines(response);
    final prefs = await SharedPreferences.getInstance();

    // String? posUrlNastavitve = prefs.getString('POS') ?? "";

    final printableResponse = filteredResponse.join("\r\n");

    // Dodaj zamik 2 sekundi (lahko spremeniš trajanje)

    await Utils.printTextWithIntegratedSunmi(
        context, printableResponse, ref, isBesteronSucess);

    if (isBesteronSucess) {
      ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
      clearSelectedItem(ref);
      clearSearchQuery(ref);
    }
  }

  void _updateFinalSum() {
    double total = ref.watch(narociloNotifierProvider.notifier).totalSum();
    if (total == null) {}
  }
}
