import 'package:biro_pos/components/error_dialog.dart';
import 'package:biro_pos/components/ok_button.dart';
import 'package:biro_pos/components/utils.dart';
import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/controllers/print.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LandscapeLayout extends ConsumerStatefulWidget {
  const LandscapeLayout({super.key});

  @override
  ConsumerState<LandscapeLayout> createState() => _LandscapeLayoutScreenState();
}

class _LandscapeLayoutScreenState extends ConsumerState<LandscapeLayout> {
  static const platform = MethodChannel('bluetooth_channel');
  static const usbPlatform = MethodChannel('usb_channel'); // USB channel
  final TextEditingController _stornoRacunController = TextEditingController();
  final TextEditingController _testDataController =
      TextEditingController(); // For test data
  final String? userSifra = SessionManager().getLoggedInUserSifra();
  String? _apiResponse;
  bool _usbPrinterConnected = false;
  String _status = 'Disconnected';

  @override
  void initState() {
    super.initState();
    _checkUsbConnection(); // Check USB connection on startup
  }

  Future<void> _checkUsbConnection() async {
    try {
      final bool isConnected = await usbPlatform.invokeMethod('isUsbConnected');
      setState(() {
        _usbPrinterConnected = isConnected;
        _status =
            isConnected ? 'USB Printer Connected' : 'USB Printer Disconnected';
      });
    } on PlatformException catch (e) {
      setState(() {
        _usbPrinterConnected = false;
        _status = 'Error checking USB connection: ${e.message}';
      });
    }
  }

  void _clearText() {
    _stornoRacunController.clear();
    setState(() {
      _apiResponse = null;
    });
  }

  Future<void> _connectUsbPrinter() async {
    try {
      final bool? result =
          await usbPlatform.invokeMethod('findAndConnectUsbPrinter');

      if (result != null && result == true) {
        setState(() {
          _usbPrinterConnected = true;
          _status = 'USB Printer Connected';
        });
        _showSnackBar('USB Printer connected successfully!');
      } else {
        setState(() {
          _usbPrinterConnected = false;
          _status = 'USB Printer Connection Failed';
        });
        _showSnackBar('Failed to connect to USB Printer.');
      }
    } on PlatformException catch (e) {
      setState(() {
        _usbPrinterConnected = false;
        _status = 'Failed to connect: ${e.message}';
      });
      _showSnackBar('Failed to connect to USB Printer: ${e.message}');
    }
  }

  Future<void> _printViaUsb(List<String> dataLines) async {
    if (!_usbPrinterConnected) {
      _showSnackBar('USB Printer not connected!');
      return;
    }

    try {
      final String result = await usbPlatform.invokeMethod('sendDataUsb', {
        'dataLines': dataLines,
      });
      setState(() {
        _status = 'Printing completed successfully!';
      });
      _showSnackBar(
          'Printing completed successfully!'); // Show success SnackBar
    } on PlatformException catch (e) {
      setState(() {
        _status = 'Failed to send data via USB: ${e.message}';
      });
      _showSnackBar('Failed to send data: ${e.message}'); // Show error SnackBar
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  _handleData() async {
    try {
      String stRacuna = _stornoRacunController.text;

      String txtData = 'StornoRacuna\t$userSifra\t$stRacuna';
      List<String> apiResponse = await sendRequest(userSifra ?? '', txtData);
      print('api response $apiResponse');

      final filteredResponse = Utils.filterEmptyLines(apiResponse);

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        FocusScope.of(context).unfocus();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

        await _printViaUsb(filteredResponse);
      });
    } catch (e) {
      setState(() {
        _apiResponse = 'Error fetching data';
      });
    }
  }

  //New method for printing test data
  _handleTestData() async {
    List<String> testData = [_testDataController.text];
    await _printViaUsb(testData);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppStyles.white,
        appBar: AppBar(
          backgroundColor: AppStyles.white,
          title: Text(
            "Storno računa",
            style: AppStyles.heading3.copyWith(color: AppStyles.black),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppStyles.black),
            onPressed: () {
              HapticFeedback.vibrate();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: SingleChildScrollView(
          // Wrap Column with SingleChildScrollView
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _connectUsbPrinter,
                    child: Text(_usbPrinterConnected
                        ? 'USB Printer Connected'
                        : 'Connect to USB Printer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _usbPrinterConnected ? Colors.green : AppStyles.blue,
                      foregroundColor: AppStyles.white,
                    ),
                  ),
                  Text(
                    'Status: $_status',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      "Številka računa:",
                      style:
                          AppStyles.heading2.copyWith(color: AppStyles.black),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 250,
                    child: TextField(
                      autofocus: true,
                      controller: _stornoRacunController,
                      cursorColor: AppStyles.blue,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppStyles.silver.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide.none,
                        ),
                        suffixIconColor: AppStyles.blue,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearText,
                          focusColor: AppStyles.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32), // Added spacing
                  Center(
                    child: Text(
                      "Test Data:",
                      style:
                          AppStyles.heading2.copyWith(color: AppStyles.black),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 250,
                    child: TextField(
                      controller: _testDataController,
                      cursorColor: AppStyles.blue,
                      decoration: InputDecoration(
                        hintText: 'Enter test data here',
                        filled: true,
                        fillColor: AppStyles.silver.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _handleTestData,
                    child: const Text('Print Test Data via USB'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyles.green,
                      foregroundColor: AppStyles.white,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 32),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: OKButton(
                    onPressed: _handleData,
                    text: 'OK',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
