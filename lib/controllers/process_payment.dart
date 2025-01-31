import 'dart:async';
import 'dart:io';

import 'package:biro_pos/components/utils.dart';
import 'package:biro_pos/controllers/bluetooth_controller.dart';
import 'package:biro_pos/controllers/besteron_controller.dart';
import 'package:biro_pos/controllers/print.dart';
import 'package:biro_pos/providers/direct_payment_provider.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/providers/settings_provider.dart';
import 'package:biro_pos/providers/totdal_sum_provider.dart';
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
    final paymentMethods = ref.watch(paymentMethodProvider);

    if (paymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ne najdem načinov plačil!")),
      );
      return;
    }

    try {
      final response = await ref
          .read(orderProvider)
          .createOrder(context, paymentType, davcnaSt);

      // Proceed with printing and other processes if no errors occur
      if (bluetoothPrintanje) {
        try {
          await _processBluetoothPrinting(
              context, response, paymentType, finalSum);
        } catch (e) {
          print("Bluetooth data send failed: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Bluetooth error: $e")),
          );
        }
      } else {
        await _processInnerPrinting(context, response, paymentType, finalSum);
      }
      _updateFinalSum();
    } catch (e) {
      // Catch the exception thrown from sendRequest (NetworkError, TimeoutError)
      String errorMessage = 'An unknown error occurred';

      // Determine if it's a network-related error or a timeout
      if (e is SocketException) {
        errorMessage = 'Network Error: Unable to reach server. ${e.message}';
      } else if (e is TimeoutException) {
        errorMessage =
            'Timeout Error: The request timed out. Please try again.';
      } else if (e is Exception) {
        errorMessage = e.toString();
      }

      // Show the SnackBar with the error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5), // Adjust duration if needed
        ),
      );
    }
  }

  Future<void> _processBluetoothPrinting(BuildContext context,
      List<String> response, String paymentType, double finalSum) async {
    final prefs = await SharedPreferences.getInstance();
    String? posUrlNastavitve = prefs.getString('POS') ?? "";
    String? tid = prefs.getString('TID') ?? "";

    try {
      if (paymentType == "KAR" && posUrlNastavitve.isNotEmpty) {
        try {
          final gotovinaRacun = await callBesteron(finalSum);
          await isBluetoothConnected(context, response);
          await BluetoothService.sendData([gotovinaRacun], ref,
              addEmptyLines: false, context: context);
          if (!gotovinaRacun.contains("Transakcija zavrnjena")) {
            await isBluetoothConnected(context, response);
            await BluetoothService.sendData(response, ref,
                context: context, addEmptyLines: true);
          }
        } catch (e) {
          // Napaka pri komunikaciji z Besteronom
          print("Napaka pri komunikaciji z Besteronom: ${e.toString()}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text("Napaka pri komunikaciji z Besteronom: ${e.toString()}"),
              duration: const Duration(seconds: 5), // Daljša prikaz napake
            ),
          );
          ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
        } finally {
          // Set total to zero in case of error or success
          ref.read(totalSumProvider.notifier).state =
              ref.read(narociloNotifierProvider.notifier).totalSum();
        }
      } else {
        try {
          await isBluetoothConnected(
              context, response); // Preverimo povezavo z Bluetoothom
          await BluetoothService.sendData(response, ref,
              context: context, addEmptyLines: true);
        } catch (e) {
          // Napaka pri pošiljanju podatkov preko Bluetootha
          print("Bluetooth data send failed: ${e.toString()}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Napaka pri pošiljanju podatkov preko Bluetootha: ${e.toString()}"),
              duration: const Duration(seconds: 5), // Daljša prikaz napake
            ),
          );
          ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
        } finally {
          // Set total to zero in case of error or success
          ref.read(totalSumProvider.notifier).state =
              ref.read(narociloNotifierProvider.notifier).totalSum();
        }
      }
    } catch (e) {
      // Splošna napaka pri obdelavi plačila
      print("Napaka pri obdelavi plačila: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Napaka pri obdelavi plačila: ${e.toString()}"),
          duration: const Duration(seconds: 5), // Daljša prikaz napake
        ),
      );
      ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
    } finally {
      // Set total to zero in case of error or success
      ref.read(totalSumProvider.notifier).state =
          ref.read(narociloNotifierProvider.notifier).totalSum();
    }
  }

  static Future<void> isBluetoothConnected(
      BuildContext context, List<String> response) async {
    // Added BuildContext
    final bluetoothConnected = await BluetoothService.isBluetoothConnected();
    final bluetoothEnabled = await BluetoothService.isBluetoothEnabled();

    if (!bluetoothConnected || !bluetoothEnabled) {
      var racunLine = response.firstWhere(
        (item) => item.contains("Racun st."),
        orElse: () => "",
      );

      var povezanDokumentLine = response.firstWhere(
        (item) => item.contains("Povezan dokument"),
        orElse: () => "",
      );
      if (racunLine.isNotEmpty) {
        RegExp regex = RegExp(r'Racun st\.\s*:\s*([^\n\r]+)');
        RegExp regex2 = RegExp(r'Povezan dokument\s*:\s*([^\n\r]+)');
        Match? match = regex.firstMatch(racunLine);
        Match? match2 = regex2.firstMatch(povezanDokumentLine);

        var cenaLine = response.firstWhere(
          (item) => item.contains("SKUPAJ EUR"),
          orElse: () => "",
        );

        RegExp regexCena = RegExp(r'SKUPAJ EUR\s*([\d,]+)');
        Match? matchCena = regexCena.firstMatch(cenaLine);
        String cena = matchCena?.group(1)!.trim() ?? '';

        if (match != null || match2 != null) {
          String racunSt = match?.group(1)?.trim() ?? '';

          print("Racun: $racunSt");
          int povezanIndex =
              response.indexWhere((item) => item.contains("Povezan dokument:"));

          String povezanDokument = "";
          if (povezanIndex != -1 && povezanIndex + 1 < response.length) {
            String naslednjaVrstica = response[povezanIndex + 1].trim();

            // Uporabi regex za zajem samo številke računa (brez datuma)
            RegExp regex = RegExp(r'^\S+'); // Prva beseda v vrstici
            Match? match = regex.firstMatch(naslednjaVrstica);

            if (match != null) {
              povezanDokument = match.group(0)!; // Ujemanje
            }
          }
          povezanDokument = povezanDokument.replaceAll(",", "").trim();
          print(
              "Final Povezan dokument: '$povezanDokument'"); // Debugging output

          print("Povezan dokument: $povezanDokument");

          print("Showing AlertDialog for povezanDokument: '$povezanDokument'");

          // Show the modal dialog with extracted Racun st.
          await showDialog(
            context: context, // Uporabi rootNavigator
            builder: (BuildContext context) {
              return AlertDialog(
                title: povezanDokument.isEmpty
                    ? const Text(
                        "Račun je bil narejen, vendar ni povezave s tiskalnikom")
                    : const Text(
                        "Račun je storniran, vendar ni povezave s tiskalnikom"),
                content: povezanDokument.isEmpty
                    ? Text(
                        'Preverite tiskalnik\n'
                        'in naredite kopijo računa\n\n\n'
                        'Številka računa: $racunSt\n\n'
                        'Cena: $cena €',
                        textAlign: TextAlign.center,
                      )
                    : Text(
                        'Preverite tiskalnik\n'
                        'in naredite kopijo računa\n\n\n'
                        'Številka računa: $racunSt\n\n',
                        textAlign: TextAlign.center,
                      ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"),
                  ),
                ],
              );
            },
          );
        } else {
          throw Exception("Ni povezave s tiskalnikom, račun ni narejen");
        }
      }
    }
  }

  Future<void> _processInnerPrinting(BuildContext context,
      List<String> response, String paymentType, double finalSum,
      {String? davcnaSt}) async {
    final filteredResponse = Utils.filterEmptyLines(response);
    final prefs = await SharedPreferences.getInstance();

    String? posUrlNastavitve = prefs.getString('POS') ?? "";

    final printableResponse = filteredResponse.join("\r\n");
    if (paymentType == "KAR" && posUrlNastavitve.isNotEmpty) {
      try {
        final gotovinaRacun = await callBesteron(finalSum);
        await Utils.printTextWithIntegratedSunmi(context, gotovinaRacun, ref);
      } catch (e) {
        print("Napaka pri komunikaciji z Besteronom: ${e.toString()}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Napaka pri komunikaciji z Besteronom: ${e.toString()}"),
            duration: const Duration(seconds: 5), // Daljša prikaz napake
          ),
        );
        ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
      }
    }
    await Utils.printTextWithIntegratedSunmi(context, printableResponse, ref);
  }

  void _updateFinalSum() {
    ref.watch(narociloNotifierProvider.notifier).totalSum();
  }
}
