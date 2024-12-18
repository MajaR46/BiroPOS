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
        const SnackBar(content: Text("No payment methods available!")),
      );
      return;
    }

    final response =
        await ref.read(orderProvider).createOrder(context, paymentType);

    if (bluetoothPrintanje) {
      await _processBluetoothPrinting(response, paymentType, finalSum);
    } else {
      await _processInnerPrinting(response, paymentType, finalSum);
    }

    _updateFinalSum();
  }

  Future<void> _processBluetoothPrinting(
      List<String> response, String paymentType, double finalSum) async {
    if (paymentType == "KAR") {
      try {
        print("Calling Besteron with amount: \$${finalSum}");
        final gotovinaRacun = await callBesteron(finalSum);
        await BluetoothService.sendData([gotovinaRacun], ref,
            addEmptyLines: false);
      } catch (e) {
        print("Error in calling Besteron: $e");
      }
    }
    await BluetoothService.sendData(
      response,
      ref,
    );
    _updateFinalSum();
  }

  Future<void> _processInnerPrinting(
      List<String> response, String paymentType, double finalSum) async {
    final filteredResponse = filterEmptyLines(response);
    final printableResponse = filteredResponse.join("\r\n");
    if (paymentType == "KAR") {
      final gotovinaRacun = await callBesteron(finalSum);
      await printTextWithFormatting(gotovinaRacun, "BlueTooth Printer", ref);
    }
    await printTextWithFormatting(printableResponse, "BlueTooth Printer", ref);
  }

  void _updateFinalSum() {
    ref.watch(narociloNotifierProvider.notifier).totalSum();
  }
}
