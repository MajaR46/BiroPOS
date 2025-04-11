import 'package:BiroPOS/controllers/bluetooth_controller.dart';
import 'package:BiroPOS/models/bondedBlutetoothDevice.dart';
import 'package:BiroPOS/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  final BluetoothService _bluetoothService = BluetoothService();

  @override
  void initState() {
    super.initState();
    _initializePrinterAndPrint(); // ✅ Calls async function correctly

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    Future.delayed(const Duration(seconds: 7), () {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    });
  }

  Future<bool> _checkBluetoothPermissions() async {
    // Preverite bluetooth povezavo tukaj. Če ni dovoljena se jo zahteva
    if (await _bluetoothService.checkBluetoothPermissions() == true) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> _initializePrinterAndPrint() async {
    await _initializeBluetooth();
    bool hasPermissions = await _checkBluetoothPermissions();

    if (!hasPermissions) {
      print("Bluetooth permissions not granted.  Cannot print.");
      return;
    }

    try {
      await BluetoothService.sendData(["Programska oprema BiroPOS"], ref,
          context: context, addEmptyLines: false);
      print("Printing triggered successfully on startup.");
    } catch (e) {
      print("Failed to print on startup: $e");
    }
  }

  Future<void> _initializeBluetooth() async {
    try {
      await _bluetoothService.initializeBluetooth();
      // Fetch bonded devices
      List<BondedDevice> devices = await _bluetoothService.getBondedDevices();

      // Attempt to connect to the required device
      for (final device in devices) {
        if (device.name == "InnerPrinter" ||
            device.name == "BlueTooth Printer" ||
            device.name == "IPosPrinter" ||
            device.name == "IPos2Printer" ||
            device.name == "OM BP" ||
            device.name == "P58E" ||
            device.name == "RPP-02" ||
            device.name == "RPP02N" ||
            device.name == "TimPOS" ||
            device.name == "NT barcode scanner") {
          await _bluetoothService.connectToDevice(context);
          print("Connected to ${device.adress}");
          break;
        }
      }
    } catch (e) {
      print("Error initializing Bluetooth: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Image.asset("assets/images/logo.png"),
    ));
  }
}
