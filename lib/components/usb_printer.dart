import 'package:flutter/services.dart';

class PrinterService {
  static const platform = MethodChannel('com.yourcompany.printer');

  Future<void> printReceipt() async {
    try {
      final result = await platform.invokeMethod('printReceipt');
      print(result);
    } on PlatformException catch (e) {
      print("Napaka pri tisku: ${e.message}");
    }
  }
}
