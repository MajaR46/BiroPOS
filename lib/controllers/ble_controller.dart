import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleProvider with ChangeNotifier {
  bool _isBluetoothSupported = true;
  bool _isLoading = true;
  bool _isScanning = false;
  List<BluetoothDevice> _devicesList = [];

  BleProvider() {
    _checkBluetoothSupport();
  }

  bool get isBluetoothSupported => _isBluetoothSupported;
  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  List<BluetoothDevice> get devicesList => _devicesList;

  Future<void> _checkBluetoothSupport() async {
    _isBluetoothSupported = await FlutterBluePlus.isSupported;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> startScan() async {
    if (_isBluetoothSupported) {
      _isScanning = true;
      notifyListeners();

      // Start scanning for BLE devices
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        _devicesList = results.map((result) => result.device).toList();
        notifyListeners(); // Notify listeners about new devices found
      });

      // Stop scanning after a timeout
      await Future.delayed(const Duration(seconds: 30));
      await FlutterBluePlus.stopScan();
      _isScanning = false;
      notifyListeners();
    }
  }
}
