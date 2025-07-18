import 'dart:typed_data';
import 'package:BiroPOS/utils/error_dialog.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/selecteditem_provider.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:flutter/material.dart'; // Import Material package
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunmi_printer_plus/core/enums/enums.dart';
import 'package:sunmi_printer_plus/core/styles/sunmi_qrcode_style.dart';
import 'package:sunmi_printer_plus/core/styles/sunmi_text_style.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod

class Utils {
  static List<String> filterEmptyLines(List<String> lines) {
    return lines
        .map((line) =>
            line.replaceAll('\r', '').replaceAll('\n', '').trimRight())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Future<String> getPreferencesTextSize() async {
    final prefs = await SharedPreferences.getInstance();
    final textSize = prefs.getString('velikostPrintanegaTeksta') ?? '';
    return textSize;
  }

  static Future<void> printTextWithIntegratedSunmi(BuildContext context,
      String text, WidgetRef ref, bool isBesteronSucess) async {
    final SunmiPrinterPlus sunmiPrinterPlus = SunmiPrinterPlus();
    final settings = ref.watch(settingsProvider);
    final vecjiPrint = settings['isCheckedVecjiPrint'] ?? false;

    final cleanedText = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = cleanedText.split('\n');
    final filteredLines = filterEmptyLines(lines);
    final textSize = await Utils().getPreferencesTextSize();

    try {
      // Store the printer status
      final printerStatus = await sunmiPrinterPlus.getStatus();

      if (printerStatus == PrinterStatus.COMM) {
        ErrorDialogs.showBasicDialog(
            "Napaka pri uporabi vgrajenega tiskalnika", context);

        await ErrorDialogs.showResponseDialog(filteredLines, context!);

        return;
      } else {
        print("Printer is not in ERROR state.");
      }
      bool isBold = false;

      for (int i = 0; i < filteredLines.length; i++) {
        final line = filteredLines[i];

        if (line.contains('#VELIKOST-START#')) {
          isBold = true;
        } else if (line.contains('#VELIKOST-END#')) {
          isBold = false;
        } else if (line.contains('#QRKODA#')) {
          String qrCodeData = line.replaceAll('#QRKODA#', '').trim();
          if (qrCodeData.endsWith('#')) {
            qrCodeData = qrCodeData.substring(0, qrCodeData.length - 1);
          }
          if (qrCodeData.isNotEmpty) {
            if (qrCodeData.length > 400) {
              await sunmiPrinterPlus.printText(
                  text: 'QR Code data too long. Please check. Frontend',
                  style: SunmiTextStyle(align: SunmiPrintAlign.LEFT));
            } else {
              await sunmiPrinterPlus.printQrcode(
                  text: qrCodeData, style: SunmiQrcodeStyle(qrcodeSize: 4));
            }
          } else {
            print('QR code data is empty or invalid.');
          }
        } else {
          await sunmiPrinterPlus.printText(
              text: line,
              style: SunmiTextStyle(
                  bold: isBold,
                  fontSize: vecjiPrint ? int.tryParse(textSize) ?? 32 : 24));
        }

        // Check if the line contains "Podpis"
        if (line.toLowerCase().contains("podpis")) {
          const int extraBlankLines = 2;
          // Add 3 blank lines immediately after the "podpis" line
          for (int j = 0; j < extraBlankLines; j++) {
            await sunmiPrinterPlus.printText(
              text: ' ',
            );
          }
        }
      }
      const int extraBlankLines = 3;
      for (int i = 0; i < extraBlankLines; i++) {
        await sunmiPrinterPlus.printText(
          text: ' ',
        );
      }
    } catch (e) {
      if (e
          .toString()
          .contains('kotlin.UninitializedPropertyAccessException')) {
        await ErrorDialogs.showResponseDialog(filteredLines, context!);
        ErrorDialogs.showBasicDialog(
            "Naprava ne podpira integriranega tiskalnika", context);

        ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
        clearSelectedItem(ref);
      } else {
        print('Error during printing: $e');
        ErrorDialogs.showBasicDialog(
            "Napaka pri tiskanju z integriranim tiskalnikom $e", context);

        await ErrorDialogs.showResponseDialog(filteredLines, context!);

        ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
        clearSelectedItem(ref);
      }
    }
  }
}
