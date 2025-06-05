import 'dart:io';

import 'package:BiroPOS/utils/error_dialog.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/searchquery_provider.dart';
import 'package:BiroPOS/providers/selecteditem_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:BiroPOS/utils/utils.dart';
import 'package:BiroPOS/models/bondedBlutetoothDevice.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

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
    } on PlatformException catch (e) {
      return [];
    }
  }

  Future<void> initializeBluetooth() async {
    try {
      final String result = await platform.invokeMethod('initializeBluetooth');
    } on PlatformException catch (e) {
      print(
          'BluetoothService: Error during Bluetooth initialization: ${e.message}');
    }
  }

  Future<bool> checkBluetoothPermissions() async {
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

  Future<void> connectToDevice(BuildContext context) async {
    final hasPermissions = await checkBluetoothPermissions();
    if (!hasPermissions) {
      return;
    }
    try {
      for (final device in bondedDevices) {
        if ([
          "InnerPrinter",
          "BlueTooth Printer",
          "IPosPrinter",
          "IPos2Printer",
          "OM BP",
          "P58E",
          "RPP-02",
          "RPP02N",
          "TimPOS",
        ].contains(device.name)) {
          final String result = await platform.invokeMethod(
              'connectToDevice', {'deviceAddress': device.adress});
          print('BluetoothService: Connected to ${device.name}: $result');
        }
      }
    } on PlatformException catch (e) {
      print('Failed to connect: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to connect: ${e.message}")));
    }
  }

  static Future<String> sendData(List<String> response, WidgetRef ref,
      {bool addEmptyLines = true,
      BuildContext? context,
      bool? showDialog = true}) async {
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
      dataLines.addAll(
        ['', '', ' ', ' '],
      );

      print(
          'BluetoothService: sendData with dataLines before processing: $dataLines');

      int podpisIndex =
          dataLines.indexWhere((line) => line.toLowerCase().contains("podpis"));

      // Če je vrstica "Podpis" najdena, vstavi 3 prazne vrstice za njo
      if (podpisIndex != -1) {
        dataLines.insertAll(podpisIndex + 1, ['', '', '']);
      }

      // Send data to platform method
      String result;
      try {
        result = await platform.invokeMethod(
          'sendData',
          {'dataLines': dataLines},
        );
        print('BluetoothService: sendData success: $result');
        if (showDialog == true) {
          await ErrorDialogs.showResponseDialog(response, context!);
        }
        print("PRINT 9");
      } on PlatformException catch (e) {
        String errorMessage = 'Napaka pri pošiljanju podatkov: ${e.message}';
        // await ErrorDialogs.showBluetoothErrorDialog(context!, response);
        await ErrorDialogs.showResponseDialog(response, context!);
        print("PRINT 1");

        if (dataLines.any((line) => line.contains("#NAPAKA#"))) {
          errorMessage += ', odziv strežnika: ${dataLines.join(', ')}';
        }
        result = errorMessage;
      }

      // Ensure the context is passed before attempting to display SnackBar
      if (context != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result)));
      } else {
        print("No context available for SnackBar");
      }

      return result; // Return success or error message
    } catch (e) {
      final errorMessage = 'An unexpected error occurred: ${e.toString()}';
      if (context != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
        //await ErrorDialogs.showBluetoothErrorDialog(context!, response);
        await ErrorDialogs.showResponseDialog(response, context!);
        print("PRINT 2");
      } else {
        //await ErrorDialogs.showBluetoothErrorDialog(context!, response);
        await ErrorDialogs.showResponseDialog(response, context!);

        print("PRINT 3");

        print(errorMessage); // Print error if no context available
      }
      //await ErrorDialogs.showBluetoothErrorDialog(context!, response);
      await ErrorDialogs.showResponseDialog(response, context!);
      print("PRINT 4");

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
