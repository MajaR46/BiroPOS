import 'package:biro_pos/components/utils.dart';
import 'package:biro_pos/controllers/bluetooth_controller.dart';
import 'package:biro_pos/controllers/besteron_controller.dart';
import 'package:biro_pos/controllers/print.dart';
import 'package:biro_pos/providers/direct_payment_provider.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProcessPayment {
  final WidgetRef ref;

  ProcessPayment(this.ref);

  Future<void> processPayment(BuildContext context, String paymentType) async {
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

    final response =
        await ref.read(orderProvider).createOrder(context, paymentType);

    if (bluetoothPrintanje) {
      try {
        await _processBluetoothPrinting(
            context, response, paymentType, finalSum);
      } catch (e) {
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
    try {
      // Procesiranje plačila za kartico (KAR)
      if (paymentType == "KAR") {
        print("Calling Besteron with amount: \$${finalSum}");
        try {
          final gotovinaRacun = await callBesteron(finalSum);
          print("gotovina racun $gotovinaRacun");

          await checkBluetooth();
          await BluetoothService.sendData([gotovinaRacun], ref,
              addEmptyLines: false);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Napaka pri komunikaciji z Besteronom: $e")),
          );
        }
      }

      await checkBluetooth();

      // Pošiljanje podatkov za tiskanje
      await BluetoothService.sendData(response, ref);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Napaka $e")),
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
      List<String> response, String paymentType, double finalSum) async {
    final filteredResponse = Utils.filterEmptyLines(response);
    final printableResponse = filteredResponse.join("\r\n");
    if (paymentType == "KAR") {
      final gotovinaRacun = await callBesteron(finalSum);
      await Utils.printTextWithIntegratedSunmi(
          gotovinaRacun, "BlueTooth Printer", ref);
    }
    await Utils.printTextWithIntegratedSunmi(
        printableResponse, "BlueTooth Printer", ref);
  }

  void _updateFinalSum() {
    ref.watch(narociloNotifierProvider.notifier).totalSum();
  }
}
