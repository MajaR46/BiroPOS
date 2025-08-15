import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:BiroPOS/components/narocilo.dart';
import 'package:BiroPOS/components/usb_printer.dart';
import 'package:BiroPOS/utils/error_dialog.dart';
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
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunmi_printer_plus/core/enums/enums.dart';
import 'package:sunmi_printer_plus/core/sunmi/sunmi_printer.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

class ProcessPayment {
  final WidgetRef ref;

  ProcessPayment(this.ref);
  bool bluetoothSucess = false;
  bool usbSucess = false;
  bool integratedPrinterSucess = false;
  bool ethernetSucess = false;
  bool windowsSucess = false;

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
      ErrorDialogs.showBasicDialog("Ni načinov plačil", context);

      return;
    }

    if (paymentType == "KAR" && posUrlNastavitve.isNotEmpty) {
      try {
        final besteronResponse = await callBesteron(finalSum)
            .timeout(const Duration(seconds: 90), onTimeout: () {
          throw TimeoutException("Besteron Timeout");
        });

        String result = besteronResponse['result'];
        String besteronRacun = besteronResponse['receipt'];

        if (result != "Success") {
          isBesteronSucess = false;
        }

        //tiskanje prestavljeno sem ker če ne prej natisne naročilo in izbriše izdelek (windows print)
        final tiskajNarociloPriRacunu =
            settings['isCheckedTiskajNarociloPriRacunu'] ?? false;
        if (tiskajNarociloPriRacunu && isBesteronSucess) {
          await Narocilo.createNarocilo(ref, false, context);
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
        ErrorDialogs.showBasicDialog(
            "Napaka pri komunikaciji z Besteronom ${e.toString()}", context);

        return;
      }
    }

    // Gotovina
    try {
      List<String> modifiedResponse;
      List<String> response = [];

      if (isBesteronSucess) {
        print("Kličem createOrder za običajni račun");
        response = await ref
            .read(orderProvider)
            .createOrder(context, ref, paymentType, davcnaSt);
        print("Odgovor createOrder: $response");
      }

      if (receiptCode == true) {
        modifiedResponse = insertCodeInReceipt(response);
      } else {
        modifiedResponse = response;
      }
      int index = modifiedResponse
          .indexWhere((line) => line.contains("#VELIKOST-END#"));
      if (index != -1) {
        modifiedResponse.insert(index + 1, "#VELIKOST-END#");
      }

      if (modifiedResponse.any((line) => line.contains("#NAPAKA#"))) {
        ErrorDialogs.showBasicDialog(modifiedResponse.toString(), context);

        return;
      }
      if (isBesteronSucess == true) {
        if (bluetoothPrintanje) {
          await _processBluetoothPrinting(
            context,
            modifiedResponse,
            isBesteronSucess,
            paymentType: paymentType,
            finalSum: finalSum,
          );
          if (isBesteronSucess && bluetoothSucess) {
            ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
            clearSelectedItem(ref);
            clearSearchQuery(ref);
          }
        } else if (usbPrintanje) {
          await _processUsbPrinting(modifiedResponse, isBesteronSucess);
          if (isBesteronSucess) {
            ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
            clearSelectedItem(ref);
            clearSearchQuery(ref);
          }
        } else if (ethernetPrintanje) {
          await _processEthernetPrinting(
              modifiedResponse, context, isBesteronSucess);
          if (isBesteronSucess && ethernetSucess) {
            ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
            clearSelectedItem(ref);
            clearSearchQuery(ref);
          }
        } else if (Platform.isWindows) {
          await _processWindowsPrinting(
              modifiedResponse, context, isBesteronSucess);
          if (isBesteronSucess && windowsSucess) {
            ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
            clearSelectedItem(ref);
          }
          ;
        } else {
          await _processInnerPrinting(
            context,
            modifiedResponse,
            isBesteronSucess,
            paymentType: paymentType,
            finalSum: finalSum,
          );

          if (isBesteronSucess && integratedPrinterSucess) {
            ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
            clearSelectedItem(ref);
            clearSearchQuery(ref);
          }
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

      ErrorDialogs.showBasicDialog(errorMessage, context);
    }
  }

  Future<void> _processBluetoothPrinting(
      BuildContext context, List<String> response, bool isBesteronSucess,
      {String? paymentType, double? finalSum}) async {
    try {
      try {
        await isBluetoothConnected(context, response);
        final result = await BluetoothService.sendData(response, ref,
            context: context, addEmptyLines: true);

        // Preveri če je rezultat vseboval napako
        if (result.toLowerCase().contains("napaka") ||
            result.toLowerCase().contains("error") ||
            result.toLowerCase().contains("exception")) {
          bluetoothSucess = false;
        } else {
          bluetoothSucess = true;
        }
      } catch (e) {
        // Napaka pri pošiljanju podatkov preko Bluetootha
        bluetoothSucess = false;
        ErrorDialogs.showBasicDialog(
            "Napaka pri pošiljanju podatkov preko Bluetootha ${e.toString()}",
            context);
      } finally {
        // Set total to zero in case of error or success
        ref.read(totalSumProvider.notifier).state =
            ref.read(narociloNotifierProvider.notifier).totalSum();
      }
    } catch (e) {
      ErrorDialogs.showBasicDialog(
          "Napaka pri obdelavi plačila ${e.toString()}", context);
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
  }

  Future<void> _processEthernetPrinting(List<String> modifiedResponse,
      BuildContext context, bool isBesteronSucess) async {
    try {
      bool printResult = await printReceipt(
        modifiedResponse.join('\n'),
        context,
        ref,
        isBesteronSucess,
      );

      ethernetSucess = printResult;
    } catch (e) {
      ethernetSucess = false;
      if (context.mounted) {
        ErrorDialogs.showBasicDialog("Napaka pri tiskanju $e", context);
      }
    }
  }

  Future<void> _processWindowsPrinting(List<String> modifiedResponse,
      BuildContext context, bool isBesteronSucess) async {
    try {
      List<String> cleanLines = ocistiVrstice(modifiedResponse);
      String finalReceiptLines = cleanLines.join('\n');
      bool printResult = await saveFileNextToExe(
          finalReceiptLines, context, ref, isBesteronSucess);
      windowsSucess = printResult;
    } catch (e) {
      windowsSucess = false;
      if (context.mounted) {
        ErrorDialogs.showBasicDialog("Napaka pri tiskanju $e", context);
      }
    }
  }

  Future<void> _processInnerPrinting(
      BuildContext context, List<String> response, bool isBesteronSucess,
      {String? paymentType, double? finalSum, String? davcnaSt}) async {
    final filteredResponse = Utils.filterEmptyLines(response);
    final prefs = await SharedPreferences.getInstance();

    // String? posUrlNastavitve = prefs.getString('POS') ?? "";

    final printableResponse = filteredResponse.join("\r\n");
    final SunmiPrinterPlus sunmiPrinterPlus = SunmiPrinterPlus();

    final printerStatus = await sunmiPrinterPlus.getStatus();

    if (printerStatus == PrinterStatus.COMM) {
      integratedPrinterSucess = false;

      ErrorDialogs.showBasicDialog("Tiskalnik ni inicializiran", context);

      return;
    }

    try {
      await Utils.printTextWithIntegratedSunmi(
          context, printableResponse, ref, isBesteronSucess);
      integratedPrinterSucess = true;
    } catch (e) {
      integratedPrinterSucess = false;
      ErrorDialogs.showBasicDialog("Napaka pri tiskanju $e", context);
    }
  }

  void _updateFinalSum() {
    double total = ref.watch(narociloNotifierProvider.notifier).totalSum();
    if (total == null) {}
  }
}
