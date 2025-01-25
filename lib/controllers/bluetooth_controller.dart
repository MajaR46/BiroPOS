import 'dart:io';

import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/components/utils.dart';
import 'package:biro_pos/models/bondedBlutetoothDevice.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  static const platform = MethodChannel('bluetooth_channel');
  List<BondedDevice> bondedDevices = [];

  Future<List<BondedDevice>> getBondedDevices() async {
    try {
      print('BluetoothService: Getting bonded devices...');
      final result =
          await platform.invokeMethod<List<dynamic>>('getBondedDevices');
      print('BluetoothService: Bonded devices raw result: $result');
      bondedDevices = result
              ?.map((device) => BondedDevice.fronRawString(device as String))
              .toList() ??
          [];
      print('BluetoothService: Bonded devices parsed: $bondedDevices');
      return bondedDevices;
    } on PlatformException catch (e) {
      print('BluetoothService: Error fetching devices: $e');
      return [];
    }
  }

  Future<bool> _checkBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.bluetoothConnect.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.bluetoothConnect.request();
        if (result != PermissionStatus.granted) {
          print('BluetoothService: Bluetooth permission not granted.');
          return false;
        }
      }

      final statusScan = await Permission.bluetoothScan.status;
      if (statusScan != PermissionStatus.granted) {
        final result = await Permission.bluetoothScan.request();
        if (result != PermissionStatus.granted) {
          print('BluetoothService: Bluetooth scan permission not granted.');
          return false;
        }
      }
    }
    return true;
  }

  Future<void> connectToDevice(
      String deviceAddress, BuildContext context) async {
    final hasPermissions = await _checkBluetoothPermissions();
    if (!hasPermissions) {
      return;
    }
    try {
      for (final device in bondedDevices) {
        if (device.name == "InnerPrinter" ||
            device.name == "BlueTooth Printer" ||
            device.name == "IPosPrinter" ||
            device.name == "IPos2Printer" ||
            device.name == "OM BP" ||
            device.name == "P58E" ||
            device.name == "RPP-02" ||
            device.name == "RPP02N" ||
            device.name == "TimPOS") {
          final String result = await platform.invokeMethod(
              'connectToDevice', {'deviceAddress': deviceAddress});
          print('BluetoothService: Connected to device: $result');
          return; // Successfully connected
        }
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Device not found!")));
    } on PlatformException catch (e) {
      print('Failed to connect to device: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to connect to device: ${e.message}")));
    }
  }

  static Future<String> sendData(List<String> response, WidgetRef ref,
      {bool addEmptyLines = true, BuildContext? context}) async {
    try {
      final filteredResponse =
          Utils.filterEmptyLines(response); // Filter empty lines
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
        dataLines.addAll(
          ['', '', ''],
        );
      }

      print(
          'BluetoothService: sendData with dataLines before processing: $dataLines');

      // Send data to platform method
      String result;
      try {
        result = await platform.invokeMethod(
          'sendData',
          {'dataLines': dataLines},
        );
        print('BluetoothService: sendData success: $result');
      } on PlatformException catch (e) {
        result = 'Failed to send data: ${e.message}';
        print(result);
      }

      // Ensure the context is passed before attempting to display SnackBar
      if (context != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result)));
      } else {
        print("No context available for SnackBar");
      }

      ref.watch(narociloNotifierProvider.notifier).clearChosenItems();

      return result; // Return success or error message
    } catch (e) {
      final errorMessage = 'An unexpected error occurred: ${e.toString()}';
      if (context != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      } else {
        print(errorMessage); // Print error if no context available
      }
      return errorMessage; // Return error message
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
