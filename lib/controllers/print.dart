import 'dart:io';

import 'package:BiroPOS/components/usb_printer.dart';
import 'package:BiroPOS/providers/totdal_sum_provider.dart';
import 'package:BiroPOS/utils/error_dialog.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunmi_printer_plus/core/enums/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

class Print {
  final WidgetRef ref;

  Print(this.ref);

  static Future<void> printText(
      BuildContext context, List<String> text, WidgetRef ref,
      {bool clearItemsAfterPrint = true}) async {
    final settings = ref.read(settingsProvider);
    final bluetoothPrintanje = settings['isCheckedBluetoothPrintanje'] ?? true;
    final usbPrintanje = settings['isCheckedUsbPrintanje'] ?? false;
    final ethernetPrintanje = settings['isCheckedEthernetPrint'] ?? false;
    final receiptCode = settings['isCheckedReceiptCode'] ?? false;
    bool isBesteronSucess = true;
    final paymentMethods = ref.watch(paymentMethodProvider);
    List<String> modifiedResponse;
    bool bluetoothSucess = false;
    bool usbSucess = false;
    bool integratedPrinterSucess = false;
    bool ethernetSucess = false;
    bool windowsSucess = false;

    BluetoothService bluetoothService = BluetoothService();

    Future<bool> _isBluetoothConnected(
        BuildContext context, List<String> response) async {
      // Added BuildContext
      try {
        final bluetoothConnected =
            await BluetoothService.isBluetoothConnected();
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

    Future<void> _processBluetoothPrinting(
        BuildContext context, List<String> response, bool isBesteronSucess,
        {String? paymentType, double? finalSum}) async {
      try {
        try {
          await _isBluetoothConnected(context, response);
          final result = await BluetoothService.sendData(response, ref,
              context: context, addEmptyLines: true);

          print("RESULT BLUETOOTH $result");

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
              "Napaka pri pošiljanju podatkov preko Bluetootha $e", context);
        } finally {
          final totalSum = ref.read(totalSumProvider);
        }
      } catch (e) {
        // Splošna napaka pri obdelavi plačila
        ErrorDialogs.showBasicDialog("Napaka pri obdelavi plačila $e", context);
      } finally {
        final totalSum = ref.read(totalSumProvider);
      }
    }

    Future<void> _processUsbPrinting(
        List<String> response, bool isBesteronSucess) async {
      final filteredResponse = Utils.filterEmptyLines(response);

      try {
        await UsbPrint.sendDataUsb(filteredResponse);
        usbSucess = true;
      } catch (e) {
        ErrorDialogs.showBasicDialog("Napaka pri USB tiskanju $e", context);
        usbSucess = false;
      }
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

    if (text.any((line) => line.contains("#NAPAKA#"))) {
      ErrorDialogs.showBasicDialog(text.toString(), context);

      return;
    } else {
      if (receiptCode == true) {
        modifiedResponse = insertCodeInReceipt(text);
      } else {
        modifiedResponse = text;
      }

      if (bluetoothPrintanje == true) {
        await _processBluetoothPrinting(
          context,
          modifiedResponse,
          isBesteronSucess,
        );
        if (isBesteronSucess && bluetoothSucess && clearItemsAfterPrint) {
          ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
          clearSelectedItem(ref);
          clearSearchQuery(ref);
        }
      } else if (usbPrintanje) {
        await _processUsbPrinting(modifiedResponse, isBesteronSucess);
        if (isBesteronSucess & usbSucess && clearItemsAfterPrint) {
          ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
          clearSelectedItem(ref);
          clearSearchQuery(ref);
        }
      } else if (ethernetPrintanje) {
        await _processEthernetPrinting(
            modifiedResponse, context, isBesteronSucess);
        if (isBesteronSucess && ethernetSucess && clearItemsAfterPrint) {
          ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
          clearSelectedItem(ref);
          clearSearchQuery(ref);
        }
      } else if (Platform.isWindows) {
        await _processWindowsPrinting(
            modifiedResponse, context, isBesteronSucess);
        if (isBesteronSucess && windowsSucess && clearItemsAfterPrint) {
          ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
          clearSelectedItem(ref);
        }
        ;
      } else {
        try {
          await Future.delayed(Duration(seconds: 2));

          await _processInnerPrinting(
            context,
            modifiedResponse,
            isBesteronSucess,
          );

          if (isBesteronSucess &&
              integratedPrinterSucess &&
              clearItemsAfterPrint) {
            ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
            clearSelectedItem(ref);
            clearSearchQuery(ref);
          }
        } catch (e) {
          ErrorDialogs.showBasicDialog("Napaka $e", context);
        }
      }
    }
  }
}
