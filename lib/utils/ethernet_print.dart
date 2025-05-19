import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/searchquery_provider.dart';
import 'package:BiroPOS/providers/selecteditem_provider.dart';
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

void printReceipt(String text, BuildContext context, WidgetRef ref,
    bool isBesteronSucess) async {
  CapabilityProfile profile;
  String? printerIp;
  int? emptyRows;

  try {
    profile = await CapabilityProfile.load();
  } catch (e, s) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('NAPAKA pri nalaganju profila: $e')),
      );
    }
    return;
  }

  final generator = Generator(PaperSize.mm80, profile);

  try {
    final prefs = await SharedPreferences.getInstance();
    printerIp = prefs.getString('printerIp') ?? '';
    String emptyRowsSettings = prefs.getString('ethernetEmptyRows') ?? '';
    emptyRows = int.tryParse(emptyRowsSettings) ?? 2;
  } catch (e, s) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('NAPAKA pri branju nastavitev: $e')),
      );
    }
    return;
  }

  if (printerIp == null || printerIp.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('IP naslov tiskalnika ni nastavljen')),
    );
    return;
  }

  List<int> bytes = [];
  try {
    bool isLargeText = false;
    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('#VELIKOST-START#')) {
        isLargeText = true;
      } else if (line.contains('#VELIKOST-END#')) {
        isLargeText = false;
      } else if (line.contains('#QRKODA#')) {
        String qrCodeData = line.replaceAll('#QRKODA#', '').trim();
        if (qrCodeData.endsWith('#')) {
          qrCodeData = qrCodeData.substring(0, qrCodeData.length - 1);
        }
        print("QRCODEDATA $qrCodeData");
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('NAPAKA pri pripravi računa: $e')),
      );
      print("napaka $e");
    }
    ;
    return;
  }

  Future<void> printTicket(
      List<int> ticket, String ipAddress, bool isBesteronSucess) async {
    PrinterNetworkManager? printer;

    try {
      if (!context.mounted) {
        return;
      }

      printer = PrinterNetworkManager(ipAddress);

      PosPrintResult connect = await printer
          .connect(timeout: Duration(seconds: 5))
          .catchError((e, s) {
        return PosPrintResult.timeout;
      });

      PosPrintResult printing =
          await printer.printTicket(ticket).catchError((e, s) {
        return PosPrintResult.timeout;
      });

      if (printing == PosPrintResult.success && isBesteronSucess) {
        ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
        clearSelectedItem(ref);
        clearSearchQuery(ref);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Ethernet tiskanje ni uspelo: ${printing.msg}')),
          );
        }
      }
    } catch (e, s) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Nepričakovana napaka pri tiskanju z ethernet tiskalnikom: $e')),
        );
      }
    } finally {
      printer?.disconnect();
    }
  }

  await printTicket(
      bytes, printerIp!, isBesteronSucess); // Posredujemo IP naslov
}
