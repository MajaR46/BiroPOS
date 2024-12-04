import 'dart:typed_data';

import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:sunmi_printer_plus/sunmi_style.dart';

Future<void> setFontSize(String printerName, bool start) async {
  try {
    List<int> command;
    if (start) {
      command = [27, 33, 16]; // ESC ! 16 (Large Font)
    } else {
      command = [27, 33, 0]; // ESC ! 0 (Default Font)
    }
    if (printerName.contains('BlueTooth Printer') &&
        printerName.contains('C')) {
      command = start ? [27, 33, 19] : [27, 33, 5];
    }
    await SunmiPrinter.printRawData(Uint8List.fromList(command));
    print('Font size set: ${start ? 'Large' : 'Default'}');
  } catch (e) {
    print('Failed to set font size: $e');
  }
}

List<String> filterEmptyLines(List<String> lines) {
  return lines
      .map((line) => line.replaceAll('\r', '').replaceAll('\n', '').trimRight())
      .where((line) => line.isNotEmpty)
      .toList();
}

int countEmptyLines(List<String> lines) {
  int emptyLineCount = 0;

  for (String line in lines) {
    // Preveri, če je vrstica prazna ali vsebuje samo whitespace
    if (line.replaceAll('\r', '').replaceAll('\n', '').trim().isEmpty) {
      emptyLineCount++;
    }
  }

  print("Število praznih vrstic: $emptyLineCount");
  return emptyLineCount;
}

Future<void> printTextWithFormatting(
    String text, String printerName, WidgetRef ref) async {
  final cleanedText = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final lines = cleanedText.split('\n');
  final filteredLines = filterEmptyLines(lines);
  print("Filtered lines before printing: ${filteredLines.join(', ')}");

  try {
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.bindingPrinter();
    await SunmiPrinter.startTransactionPrint(true);
    for (final line in filteredLines) {
      if (line.contains('#QRKODA#')) {
        String qrCodeData = line.replaceAll('#QRKODA#', '').trim();
        if (qrCodeData.endsWith('#')) {
          qrCodeData = qrCodeData.substring(0, qrCodeData.length - 1);
        }
        if (qrCodeData.isNotEmpty) {
          if (qrCodeData.length > 400) {
            await SunmiPrinter.printText('QR Code data too long. Please check.',
                style: SunmiStyle(align: SunmiPrintAlign.LEFT));
          } else {
            await SunmiPrinter.printQRCode(qrCodeData, size: 4);
          }
        } else {
          print('QR code data is empty or invalid.');
        }
      } else if (line.contains('#VELIKOST-START#')) {
        await setFontSize(printerName, true);
      } else if (line.contains('#VELIKOST-END#')) {
        await setFontSize(printerName, false);
      } else {
        await SunmiPrinter.printText(line, style: SunmiStyle());
      }
    }

    // Add extra blank lines at the end
    const int extraBlankLines = 3;
    for (int i = 0; i < extraBlankLines; i++) {
      await SunmiPrinter.printText(' ', style: SunmiStyle());
    }
    ref.watch(narociloNotifierProvider.notifier).clearChosenItems();

    await SunmiPrinter.exitTransactionPrint(true);
  } catch (e) {
    print('Error during printing: $e');
  }
}
