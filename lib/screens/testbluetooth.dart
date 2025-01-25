import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BluetoothPrintScreen extends StatefulWidget {
  @override
  _BluetoothPrintScreenState createState() => _BluetoothPrintScreenState();
}

class _BluetoothPrintScreenState extends State<BluetoothPrintScreen> {
  static const platform = MethodChannel('bluetooth_print_channel');
  List<String> devices = [];
  String? selectedDevice;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _startScan() async {
    try {
      final List<dynamic> deviceList = await platform.invokeMethod('startScan');
      setState(() {
        devices = deviceList.cast<String>();
      });
    } on PlatformException catch (e) {
      print("Error scanning devices: ${e.message}");
    }
  }

  Future<void> _connectToDevice(String deviceAddress) async {
    try {
      await platform
          .invokeMethod('connectToDevice', {'address': deviceAddress});
      setState(() {
        selectedDevice = deviceAddress;
        isConnected = true;
      });
    } on PlatformException catch (e) {
      print("Error connecting device: ${e.message}");
      setState(() {
        selectedDevice = null;
        isConnected = false;
      });
    }
  }

  Future<void> _disconnectDevice() async {
    try {
      await platform.invokeMethod('disconnectDevice');
      setState(() {
        selectedDevice = null;
        isConnected = false;
      });
    } on PlatformException catch (e) {
      print("Error disconnecting device: ${e.message}");
    }
  }

  Future<void> _sendDataToPrinter(List<String> lines) async {
    if (selectedDevice == null || !isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiskalnik ni povezan')),
      );
      return;
    }

    try {
      String dataToPrint = lines.join('\n');
      await platform.invokeMethod('printData', {'data': dataToPrint});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podatki so poslani na tiskalnik')),
      );
    } on PlatformException catch (e) {
      print('Error sending data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Printing (No Lib)'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _startScan,
                  child: const Text('Iskanje tiskalnikov'),
                ),
                if (devices.isNotEmpty)
                  const SizedBox(
                    height: 10,
                  ),
                if (devices.isNotEmpty)
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.white,
                    ),
                    child: ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _connectToDevice(devices[index]),
                            child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selectedDevice == devices[index]
                                        ? Colors.blue.shade100
                                        : Colors.white,
                                    border: Border.all(
                                      color: selectedDevice == devices[index]
                                          ? Colors.blue.shade300
                                          : Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Text(devices[index]),
                                )),
                          );
                        }),
                  ),
                if (selectedDevice != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      'Povezan z: $selectedDevice',
                    ),
                  ),
                ElevatedButton(
                  onPressed: isConnected ? _disconnectDevice : null,
                  child: isConnected
                      ? const Text('Prekini povezavo')
                      : const Text('Prekini povezavo'),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: () {
                    List<String> testLines = [
                      '   programska oprema BiroPOS',
                      '------------------------',
                      'Datum: ${DateTime.now()}',
                      'Streze vas: Uporabnik 1',
                      'Miza: M1',
                      '------------------------',
                      'Naziv           Kol.',
                      '------------------------',
                      'Kava             1',
                      'Cola             2',
                      'Juha             1',
                      '------------------------',
                      ' '
                    ];
                    _sendDataToPrinter(testLines);
                  },
                  child: const Text('Pošlji testne podatke'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
