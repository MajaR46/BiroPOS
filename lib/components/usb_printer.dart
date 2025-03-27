import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UsbPrint {
  static const platform = MethodChannel('usb_channel');

  static Future<String> connectUsbPrinter() async {
    try {
      await platform.invokeMethod('connectUsbPrinter');
      return 'Connected';
    } on PlatformException catch (e) {
      return 'Failed to connect: ${e.message}';
    }
  }

  static Future<void> sendDataUsb(List<String> dataLines) async {
    try {
      await platform.invokeMethod('sendDataUsb', {'dataLines': dataLines});
    } on PlatformException catch (e) {
      print("Failed to send data: '${e.message}'.");
      throw e; // Re-throw the exception to be handled by the caller
    }
  }

  static Future<void> printQrCode(String qrCodeData) async {
    try {
      await platform.invokeMethod('printQrCodeUsb', {'qrCodeData': qrCodeData});
    } on PlatformException catch (e) {
      print("Failed to print QR code: '${e.message}'.");
      throw e; // Re-throw the exception
    }
  }

  static Future<String> disconnectUsb() async {
    try {
      await platform.invokeMethod('disconnectUsb');
      return 'Disconnected';
    } on PlatformException catch (e) {
      print("Failed to disconnect: '${e.message}'.");
      return 'Failed to disconnect: ${e.message}';
    }
  }
}
