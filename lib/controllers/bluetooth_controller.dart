import 'package:biro_pos/components/utils.dart';
import 'package:biro_pos/controllers/print.dart';
import 'package:biro_pos/models/bondedBlutetoothDevice.dart';
import 'package:biro_pos/providers/direct_payment_provider.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BluetoothService {
  static const platform = MethodChannel('bluetooth_channel');
  List<BondedDevice> bondedDevices = [];

  Future<List<BondedDevice>> getBondedDevices() async {
    try {
      final result =
          await platform.invokeMethod<List<dynamic>>('getBondedDevices');
      bondedDevices = result
              ?.map((device) => BondedDevice.fronRawString(device as String))
              .toList() ??
          [];
      return bondedDevices;
    } catch (e) {
      print('Error fetching devices: $e');
      return [];
    }
  }

  Future<void> connectToDevice(String deviceAddress) async {
    try {
      for (final device in bondedDevices) {
        if (device.name == "InnerPrinter") {
          final String result = await platform.invokeMethod(
              'connectToDevice', {'deviceAddress': deviceAddress});
        }
      }
    } on PlatformException catch (e) {
      print('Failed to connect to device: ${e.message}');
    }
  }

  static Future<String> sendData(List<String> response, WidgetRef ref,
      {bool addEmptyLines = true}) async {
    try {
      final filteredResponse =
          Utils.filterEmptyLines(response); // Filter empty lines
      // Apply the character replacement inline to each line
      final List<String> dataLines = filteredResponse.map((line) {
        return line
            .trim()
            .replaceAll('č', 'c')
            .replaceAll('š', 's')
            .replaceAll('ž', 'z')
            .replaceAll('Č', 'C')
            .replaceAll('Š', 'S')
            .replaceAll('Ž', 'Z');
      }).toList();

      // Conditionally add two empty lines at the end of dataLines
      if (addEmptyLines) {
        dataLines.addAll(['', '', '']);
      }

      // Send data to platform method
      final String result = await platform.invokeMethod(
        'sendData',
        {'dataLines': dataLines},
      );

      print("result: ${dataLines.toString()}");
      ref.watch(narociloNotifierProvider.notifier).clearChosenItems();

      return result; // Return success or error message
    } on PlatformException catch (e) {
      return 'Failed to send data: ${e.message}';
    }
  }

  static Future<bool> isBluetoothConnected() async {
    try {
      final bool isConnected =
          await platform.invokeMethod('isBluetoothConnected');
      return isConnected;
    } on PlatformException catch (e) {
      print('Error checking Bluetooth connection: $e');
      return false;
    }
  }

  static Future<bool> isBluetoothEnabled() async {
    try {
      final bool isEnabled = await platform.invokeMethod('isBluetoothEnabled');
      return isEnabled;
    } on PlatformException catch (e) {
      print('Error checking Bluetooth connection: $e');
      return false;
    }
  }
}
