// preferences_helper.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart'; // Required for setState if you update UI

class PreferencesHelper {
  static Future<Map<String, dynamic>> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Prepare a map to hold all the values. Use default values if not found.
      final Map<String, dynamic> preferences = {
        'apiKey': prefs.getString('apiKey') ?? 'test', //Provide Default value
        'IP': prefs.getString('IP') ?? '194.247.162.115',
        'Port': prefs.getString('Port') ?? '11111',
        'POS': prefs.getString('POS') ?? '',
        'TID': prefs.getString('TID') ?? '',
        'touchKey': prefs.getString('touchKey') ?? '',
        'textSize': prefs.getString('textSize') ?? '',
        'refreshInterval': prefs.getString('refreshInterval') ?? '',
        'stStolpcev': prefs.getString('stStolpcev') ?? '',
        'isCheckedMoney': prefs.getBool('isCheckedMoney') ?? false,
        'isCheckedOrders': prefs.getBool('isCheckedOrders') ?? false,
        'isCheckedPrikazujNarocila':
            prefs.getBool('isCheckedPrikazujNarocila') ?? false,
        'isCheckedPrikazujRacune':
            prefs.getBool('isCheckedPrikazujRacune') ?? false,
        'isCheckedTiskajNarocilo':
            prefs.getBool('isCheckedTiskajNarocilo') ?? false,
        'isCheckedIzbirajNacinePlacil':
            prefs.getBool('isCheckedIzbirajNacinePlacil') ?? false,
        'isCheckedZakljuciRacun':
            prefs.getBool('isCheckedZakljuciRacun') ?? false,
        'isCheckedPregledNarocilTiskalnik':
            prefs.getBool('isCheckedPregledNarocilTiskalnik') ?? false,
        'isCheckedTiskajNarociloPriRacunu':
            prefs.getBool('isCheckedTiskajNarociloPriRacunu') ?? false,
        'isCheckedPregledNarocil':
            prefs.getBool('isCheckedPregledNarocil') ?? false,
        'isCheckedPrintService':
            prefs.getBool('isCheckedPrintService') ?? false,
        'isCheckedBluetoothPrintanje':
            prefs.getBool('isCheckedBluetoothPrintanje') ?? true,
        'isCheckedEnojniKlik': prefs.getBool('isCheckedEnojniKlik') ?? false,
        'isCheckedBarve': prefs.getBool('isCheckedBarve') ?? false,
      };

      return preferences;
    } catch (e) {
      print('Error loading preferences: $e');
      return {}; // Or handle the error as appropriate
    }
  }
}
