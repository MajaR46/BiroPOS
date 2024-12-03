import 'package:flutter/services.dart';

class SunmiPrinter {
  static const MethodChannel _channel = MethodChannel('sunmi_printer');

  static Future<void> printText(String text) async {
    try {
      final bool result =
          await _channel.invokeMethod('printText', {'text': text});
      if (!result) {
        print('Error: Printing failed');
      }
    } on PlatformException catch (e) {
      print('Error: ${e.message}');
    }
  }
}
