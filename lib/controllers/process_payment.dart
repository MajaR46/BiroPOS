import 'dart:async';
import 'dart:io';

import 'package:biro_pos/components/error_dialog.dart';
import 'package:biro_pos/components/utils.dart';
import 'package:biro_pos/controllers/bluetooth_controller.dart';
import 'package:biro_pos/controllers/besteron_controller.dart';
import 'package:biro_pos/controllers/print.dart';
import 'package:biro_pos/providers/direct_payment_provider.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/providers/searchquery_provider.dart';
import 'package:biro_pos/providers/selecteditem_provider.dart';
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
          clearSelectedItem(ref);
          clearSearchQuery(ref);
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
          clearSelectedItem(ref);
          clearSearchQuery(ref);
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
      clearSelectedItem(ref);
      clearSearchQuery(ref);
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
      //await ErrorDialogs.showBluetoothErrorDialog(context, response);
      //await ErrorDialogs.showResponseDialog(response, context!);
      print("PRINT 11");
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
        clearSelectedItem(ref);
        clearSearchQuery(ref);
      }
    }
    await Utils.printTextWithIntegratedSunmi(context, printableResponse, ref);
  }

  void _updateFinalSum() {
    ref.watch(narociloNotifierProvider.notifier).totalSum();
  }
}
