import 'dart:typed_data';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:flutter/material.dart'; // Import Material package
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

  static Future<void> setFontSize(bool start) async {
    final SunmiPrinterPlus sunmiPrinterPlus = SunmiPrinterPlus();

    try {
      List<int> command;
      if (start) {
        command = [27, 33, 16]; // ESC ! 16 (Large Font)
      } else {
        command = [27, 33, 0]; // ESC ! 0 (Default Font)
      }
      await sunmiPrinterPlus.printEscPos(data: command);
      print('Font size set: ${start ? 'Large' : 'Default'}');
      print("command: $command");
    } catch (e) {
      print('Failed to set font size: $e');
    }
  }

  static Future<void> testPrinterCompatibility() async {
    final SunmiPrinterPlus printer = SunmiPrinterPlus();

    try {
      // Send ESC/POS command to change font size (Large Font)
      List<int> fontSizeCommand = [27, 33, 16]; // ESC ! 16 (Large Font)
      await printer.printEscPos(data: fontSizeCommand);

      // Send a text to test
      await printer.printText(text: "This is a test with large font");

      // Send ESC/POS command to reset font size (Default Font)
      List<int> resetFontSizeCommand = [27, 33, 0]; // ESC ! 0 (Default Font)
      await printer.printEscPos(data: resetFontSizeCommand);

      // Send more text to test
      await printer.printText(text: "This is a test with default font");

      print("Printer responded to ESC/POS commands");
    } catch (e) {
      print("Error during printer test: $e");
    }
  }

  static Future<void> printTextWithIntegratedSunmi(
      BuildContext context, String text, WidgetRef ref) async {
    final SunmiPrinterPlus sunmiPrinterPlus = SunmiPrinterPlus();
    final cleanedText = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = cleanedText.split('\n');
    final filteredLines = filterEmptyLines(lines);
    print("Filtered lines before printing: ${filteredLines.join(', ')}");

    try {
      // Store the printer status
      final printerStatus = await sunmiPrinterPlus.getStatus();
      print("sunmi printer test: $printerStatus");

      if (printerStatus == PrinterStatus.COMM) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Napaka pri uporabi vgrajenega tiskalnika")),
        );
        ref.watch(narociloNotifierProvider.notifier).clearChosenItems();

        return;
      } else {
        print("Printer is not in ERROR state.");
      }
      bool largeFontActive = false;

      for (final line in filteredLines) {
        if (line.contains('#VELIKOST-START#')) {
          await setFontSize(true);
          largeFontActive = true;
        } else if (line.contains('#VELIKOST-END#')) {
          await setFontSize(false);
          largeFontActive = false;
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
          await sunmiPrinterPlus.printText(text: line);
        }
      }

      const int extraBlankLines = 3;
      for (int i = 0; i < extraBlankLines; i++) {
        await sunmiPrinterPlus.printText(
          text: ' ',
        );
      }
      ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
    } catch (e) {
      if (e
          .toString()
          .contains('kotlin.UninitializedPropertyAccessException')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Naprava ne podpira integriranega tiskalnika."),
          ),
        );
        print('Sunmi Printer not available');
        ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
      } else {
        print('Error during printing: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Napaka pri tiskanju: $e")),
        );
        ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
      }
    }
  }
}
