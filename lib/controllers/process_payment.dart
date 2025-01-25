import 'package:biro_pos/components/utils.dart';
import 'package:biro_pos/controllers/bluetooth_controller.dart';
import 'package:biro_pos/controllers/besteron_controller.dart';
import 'package:biro_pos/controllers/print.dart';
import 'package:biro_pos/providers/direct_payment_provider.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/providers/settings_provider.dart';
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

    final response = await ref
        .read(orderProvider)
        .createOrder(context, paymentType, davcnaSt);

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
      await _processInnerPrinting(response, paymentType, finalSum);
    }

    _updateFinalSum();
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
          await checkBluetooth(); // Preverimo povezavo z Bluetoothom
          await BluetoothService.sendData([gotovinaRacun], ref,
              addEmptyLines: false, context: context);
          if (!gotovinaRacun.contains("Transakcija zavrnjena")) {
            await checkBluetooth(); // Ponovno preverimo
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
              duration: const Duration(seconds: 15), // Daljša prikaz napake
            ),
          );
        }
      } else {
        try {
          await checkBluetooth(); // Preverimo povezavo z Bluetoothom
          await BluetoothService.sendData(response, ref,
              context: context, addEmptyLines: true);
        } catch (e) {
          // Napaka pri pošiljanju podatkov preko Bluetootha
          print("Bluetooth data send failed: ${e.toString()}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Napaka pri pošiljanju podatkov preko Bluetootha: ${e.toString()}"),
              duration: const Duration(seconds: 15), // Daljša prikaz napake
            ),
          );
        }
      }
    } catch (e) {
      // Splošna napaka pri obdelavi plačila
      print("Napaka pri obdelavi plačila: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Napaka pri obdelavi plačila: ${e.toString()}"),
          duration: const Duration(seconds: 15), // Daljša prikaz napake
        ),
      );
    }
  }

  static Future<void> checkBluetooth() async {
    final bluetoothEnabled = await BluetoothService.isBluetoothEnabled();
    if (!bluetoothEnabled) {
      throw Exception("Bluetooth ni vklopljen");
    }
    // Preverite, če je naprava povezana
    final deviceConnected = await BluetoothService.isBluetoothConnected();
    if (!deviceConnected) {
      throw Exception("Tiskalnik ni povezan.");
    }
  }

  Future<void> _processInnerPrinting(
      List<String> response, String paymentType, double finalSum,
      {String? davcnaSt}) async {
    final filteredResponse = Utils.filterEmptyLines(response);
    final printableResponse = filteredResponse.join("\r\n");
    if (paymentType == "KAR") {
      final gotovinaRacun = await callBesteron(finalSum);
      await Utils.printTextWithIntegratedSunmi(gotovinaRacun, ref);
    }
    await Utils.printTextWithIntegratedSunmi(printableResponse, ref);
  }

  void _updateFinalSum() {
    ref.watch(narociloNotifierProvider.notifier).totalSum();
  }
}
