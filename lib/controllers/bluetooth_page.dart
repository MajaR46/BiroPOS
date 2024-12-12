import 'package:biro_pos/controllers/print.dart';
import 'package:biro_pos/providers/direct_payment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BluetoothScreen extends ConsumerStatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

//TTA DELA
class _BluetoothScreenState extends ConsumerState<BluetoothScreen> {
  static const platform = MethodChannel('bluetooth_channel');
  String _status = 'Bluetooth status unknown';
  List<Map<String, String>> _discoveredDevices = [];
  final TextEditingController _dataController = TextEditingController();

  Future<void> startDiscovery() async {
    try {
      await platform.invokeMethod('startDiscovery');
      setState(() {
        _status = 'Discovery started';
      });
    } on PlatformException catch (e) {
      setState(() {
        _status = 'Failed to start discovery: ${e.message}';
      });
    }
  }

  Future<void> getDiscoveredDevices() async {
    try {
      final List<dynamic> devices =
          await platform.invokeMethod('getDiscoveredDevices');

      // Log the raw response to debug
      print('Raw Discovered Devices: $devices');

      setState(() {
        // Convert raw string to List<Map<String, String>>
        _discoveredDevices = devices.map<Map<String, String>>((device) {
          final parts = device.toString().split(' ');

          if (parts.length >= 2) {
            final name = parts.sublist(0, parts.length - 1).join(' ').trim();
            final address = parts.last.replaceAll(RegExp('[()]'), '').trim();

            return {
              'name': name,
              'address': address,
            };
          } else {
            return {
              'name': 'Invalid Device',
              'address': 'N/A',
            };
          }
        }).toList();
      });

      print('Processed Discovered Devices: $_discoveredDevices');
    } on PlatformException catch (e) {
      setState(() {
        _status = 'Failed to get discovered devices: ${e.message}';
      });
      print('Error: ${e.message}');
    }
  }

  Future<void> connectToDevice(String deviceAddress) async {
    try {
      final String result = await platform
          .invokeMethod('connectToDevice', {'deviceAddress': deviceAddress});
      setState(() {
        _status = result; // Display connection status
      });
    } on PlatformException catch (e) {
      setState(() {
        _status = 'Failed to connect to device: ${e.message}';
      });
    }
  }

  Future<void> sendData() async {
    final response = await ref.read(orderProvider).createOrder(context, "KAR");
    final filteredResponse = filterEmptyLines(response);

    // Convert filtered response into a list of strings
    final List<String> dataLines =
        filteredResponse.map((line) => line.trim()).toList();

    // Send the line of text
    final String result = await platform.invokeMethod(
      'sendData',
      {'dataLines': dataLines}, // Send one line at a time
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bluetooth Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(_status),
            ElevatedButton(
              onPressed: startDiscovery,
              child: Text('Start Discovery'),
            ),
            ElevatedButton(
              onPressed: getDiscoveredDevices,
              child: Text('Get Discovered Devices'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _discoveredDevices.length,
                itemBuilder: (context, index) {
                  final device = _discoveredDevices[index];
                  return ListTile(
                    title: Text(device['name'] ?? 'Unknown'),
                    subtitle: Text(device['address'] ?? 'Unknown'),
                    onTap: () => connectToDevice(device['address'] ?? ''),
                  );
                },
              ),
            ),
            TextField(
              controller: _dataController,
              decoration: InputDecoration(
                labelText: 'Data to send (newline-separated)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            ElevatedButton(
              onPressed: sendData,
              child: Text('Send Data'),
            ),
          ],
        ),
      ),
    );
  }
}
