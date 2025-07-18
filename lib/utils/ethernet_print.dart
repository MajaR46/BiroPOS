import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/searchquery_provider.dart';
import 'package:BiroPOS/providers/selecteditem_provider.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:BiroPOS/utils/error_dialog.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

String sanitizeText(String input) {
  return input
      .replaceAll('č', 'c')
      .replaceAll('Č', 'C')
      .replaceAll('š', 's')
      .replaceAll('Š', 'S')
      .replaceAll('ž', 'z')
      .replaceAll('Ž', 'Z');
}

Future<bool> printReceipt(String text, BuildContext context, WidgetRef ref,
    bool isBesteronSucess) async {
  CapabilityProfile profile;
  String? printerIp;
  int? emptyRows;
  final settings = ref.watch(settingsProvider);
  final vecjiPrint = settings['isCheckedVecjiPrint'] ?? false;

  try {
    profile = await CapabilityProfile.load();
  } catch (e, s) {
    if (context.mounted) {
      ErrorDialogs.showBasicDialog("Napaka pri nalagnju profila $e", context);
    }
    return false;
  }

  final generator =
      Generator(vecjiPrint ? PaperSize.mm80 : PaperSize.mm58, profile);

  try {
    final prefs = await SharedPreferences.getInstance();
    printerIp = prefs.getString('printerIp') ?? '';
    String emptyRowsSettings = prefs.getString('ethernetEmptyRows') ?? '';
    emptyRows = int.tryParse(emptyRowsSettings) ?? 2;
  } catch (e, s) {
    if (context.mounted) {
      ErrorDialogs.showBasicDialog("Napaka pri branju nastavitev $e", context);
    }
    return false;
  }

  if (printerIp == null || printerIp.isEmpty) {
    if (context.mounted) {
      ErrorDialogs.showBasicDialog(
          "IP naslov tiskalnika ni nastavljen", context);
    }
    return false;
  }

  List<int> bytes = [];
  try {
    bool isLargeText = false;
    final lines = text.split('\n');
    for (final line in lines) {
      if (line.contains('#VELIKOST-START#')) {
        isLargeText = true;
      } else if (line.contains('#VELIKOST-END#')) {
        isLargeText = false;
      } else if (line.contains('#QRKODA#')) {
        String qrCodeData = line.replaceAll('#QRKODA#', '').trim();
        if (qrCodeData.endsWith('#')) {
          qrCodeData = qrCodeData.substring(0, qrCodeData.length - 1);
        }
        bytes += generator.qrcode(qrCodeData);
      } else {
        bytes += generator.text(sanitizeText(line),
            styles: PosStyles(
              align: PosAlign.left,
              height: isLargeText ? PosTextSize.size2 : PosTextSize.size1,
            ));
      }
    }

    bytes += generator.feed(emptyRows);
    bytes += generator.cut(mode: PosCutMode.full);
  } catch (e, s) {
    if (context.mounted) {
      ErrorDialogs.showBasicDialog("Napaka pri pripravi računa $e", context);
    }
    return false;
  }

  Future<bool> printTicket(
      List<int> ticket, String ipAddress, bool isBesteronSucess) async {
    PrinterNetworkManager? printer;
    try {
      if (!context.mounted) {
        return false;
      }
      printer = PrinterNetworkManager(ipAddress);

      PosPrintResult connect = await printer
          .connect(timeout: Duration(seconds: 5))
          .catchError((e, s) {
        return PosPrintResult.timeout;
      });

      if (connect != PosPrintResult.success) {
        if (context.mounted) {
          ErrorDialogs.showBasicDialog(
              "Povezava s tiskalnikom ni uspela: ${connect.msg}", context);
        }
        return false;
      }

      PosPrintResult printing =
          await printer.printTicket(ticket).catchError((e, s) {
        return PosPrintResult.timeout;
      });

      if (printing == PosPrintResult.success && isBesteronSucess) {
        return true;
      } else {
        if (context.mounted) {
          ErrorDialogs.showBasicDialog(
              "Ethernet tiskanje ni uspelo: ${printing.msg}", context);
        }
        return false;
      }
    } catch (e, s) {
      if (context.mounted) {
        ErrorDialogs.showBasicDialog(
            "Napaka pri ethernet tiskanju: $e", context);
      }
      return false;
    } finally {
      printer?.disconnect();
    }
  }

  bool result = await printTicket(bytes, printerIp!, isBesteronSucess);
  return result;
}
