import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends StateNotifier<Map<String, bool>> {
  AppSettings()
      : super({
          'isCheckedPrikazujNarocila': false,
          'isCheckedPrikazujRacune': false,
          'isCheckedBluetoothPrintanje': false,
          'isCheckedEnojniKlik': false,
          'isCheckedPregledNarocil': false,
          'isCheckedHHCene': false,
          'isCheckedPregledNarocilTiskalnik': false,
          'isCheckedBarve': false,
          'isCheckedTiskajNarociloPriRacunu': false,
          'isCheckedTiskajNarocilo': false,
          'isCheckedUsbPrintanje': false,
          'isCheckedEthernetPrint': false,
          'isCheckedReceiptCode': false,
          'isCheckedMoney': false,
          'isCheckedREP': false,
          'isCheckedDvojnaVrstica': false,
        }) {
    _loadSettings();
  }

  // This method loads the saved preferences asynchronously.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final prikazujNarocila =
        prefs.getBool('isCheckedPrikazujNarocila') ?? false;
    final prikazujRacune = prefs.getBool('isCheckedPrikazujRacune') ?? false;
    final bluetoothprintanje =
        prefs.getBool('isCheckedBluetoothPrintanje') ?? false;
    final enojniKlik = prefs.getBool('isCheckedEnojniKlik') ?? false;
    final pregledNarocil = prefs.getBool('isCheckedPregledNarocil') ?? false;
    final hhCene = prefs.getBool('isCheckedHHCene') ?? false;
    final pregledNarocilTiskalnik =
        prefs.getBool('isCheckedPregledNarocilTiskalnik') ?? false;
    final itemBarve = prefs.getBool('isCheckedBarve') ?? false;
    final tiskajNarociloPriRacunu =
        prefs.getBool('isCheckedTiskajNarociloPriRacunu') ?? false;
    final tiskajNarocilo = prefs.getBool('isCheckedTiskajNarocilo') ?? false;
    final prikaziCene = prefs.getBool('isCheckedPrikazCene') ?? false;
    final usbPrintanje = prefs.getBool('isCheckedUsbPrintanje') ?? false;
    final ethernetPrint = prefs.getBool('isCheckedEthernetPrint') ?? false;
    final receiptCode = prefs.getBool('isCheckedReceiptCode') ?? false;
    final isCheckedMoney = prefs.getBool('isCheckedMoney') ?? false;
    final isCheckedREP = prefs.getBool('isCheckedREP') ?? false;
    final isCheckedDvojnaVrstica =
        prefs.getBool('isCheckedDvojnaVrstica') ?? false;

    // Update the state with both values
    state = {
      'isCheckedPrikazujNarocila': prikazujNarocila,
      'isCheckedPrikazujRacune': prikazujRacune,
      'isCheckedBluetoothPrintanje': bluetoothprintanje,
      'isCheckedEnojniKlik': enojniKlik,
      'isCheckedPregledNarocil': pregledNarocil,
      'isCheckedHHCene': hhCene,
      'isCheckedPregledNarocilTiskalnik': pregledNarocilTiskalnik,
      'isCheckedBarve': itemBarve,
      'isCheckedTiskajNarociloPriRacunu': tiskajNarociloPriRacunu,
      'isCheckedTiskajNarocilo': tiskajNarocilo,
      'isCheckedPrikazCene': prikaziCene,
      'isCheckedUsbPrintanje': usbPrintanje,
      'isCheckedEthernetPrint': ethernetPrint,
      'isCheckedReceiptCode': receiptCode,
      'isCheckedMoney': isCheckedMoney,
      'isCheckedREP': isCheckedREP,
      'isCheckedDvojnaVrstica': isCheckedDvojnaVrstica,
    };
  }

  void togglePrikazujNarocila(bool isEnabled) {
    state = {
      ...state,
      'isCheckedPrikazujNarocila': isEnabled,
    };
    _saveSetting('isCheckedPrikazujNarocila',
        isEnabled); // Save the new value for PrikazujNarocila
  }

  void togglePrikazujRacune(bool isEnabled) {
    state = {
      ...state,
      'isCheckedPrikazujRacune': isEnabled,
    };
    _saveSetting('isCheckedPrikazujRacune',
        isEnabled); // Save the new value for PrikazujRacune
  }

  void toggleBluetoothPrinting(bool isEnabled) {
    state = {...state, 'isCheckedBluetoothPrintanje': isEnabled};
    _saveSetting('isCheckedBluetoothPrintanje', isEnabled);
  }

  void toogleEnojniKlik(bool isEnabled) {
    state = {...state, 'isCheckedEnojniKlik': isEnabled};
    _saveSetting('isCheckedEnojniKlik', isEnabled);
  }

  void togglePregledNarocil(bool isEnabled) {
    state = {...state, 'isCheckedPregledNarocil': isEnabled};
    _saveSetting('isCheckedPregledNarocil', isEnabled);
  }

  void toggleHHCene(bool isEnabled) {
    state = {...state, 'isCheckedHHCene': isEnabled};
    _saveSetting('isCheckedHHCene', isEnabled);
  }

  void togglePregledNarocilTiskalnik(bool isEnabled) {
    state = {...state, 'isCheckedPregledNarocilTiskalnik': isEnabled};
    _saveSetting('isCheckedPregledNarocilTiskalnik', isEnabled);
  }

  void toggleBarve(bool isEnabled) {
    state = {...state, 'isCheckedBarve': isEnabled};
    _saveSetting('isCheckedBarve', isEnabled);
  }

  void toggleTiskajNarociloPriRacunu(bool isEnabled) {
    state = {...state, 'isCheckedTiskajNarociloPriRacunu': isEnabled};
    _saveSetting('isCheckedTiskajNarociloPriRacunu', isEnabled);
  }

  void toggleTiskajNarocilo(bool isEnabled) {
    state = {...state, 'isCheckedTiskajNarocilo': isEnabled};
    _saveSetting('isCheckedTiskajNarocilo', isEnabled);
  }

  void togglePrikazCene(bool isEnabled) {
    state = {...state, 'isCheckedPrikazCene': isEnabled};
    _saveSetting('isCheckedPrikazCene', isEnabled);
  }

  void toggleUsbPrintanje(bool isEnabled) {
    state = {...state, 'isCheckedUsbPrintanje': isEnabled};
    _saveSetting('isCheckedUsbPrintanje', isEnabled);
  }

  void toggleVecjiPrint(bool isEnabled) {
    state = {...state, 'isCheckedVecjiPrint': isEnabled};
    _saveSetting('isCheckedVecjiPrint', isEnabled);
  }

  void toggleEthernetPrint(bool isEnabled) {
    state = {...state, 'isCheckedEthernetPrint': isEnabled};
    _saveSetting('isCheckedEthernetPrint', isEnabled);
  }

  void toggleReceiptCode(bool isEnabled) {
    state = {...state, 'isCheckedReceiptCode': isEnabled};
    _saveSetting('isCheckedReceiptCode', isEnabled);
  }

  void toggleIsCheckedMoney(bool isEnabled) {
    state = {...state, 'isCheckedMoney': isEnabled};
    _saveSetting('isCheckedMoney', isEnabled);
  }

  void toggleREP(bool isEnabled) {
    state = {...state, 'isCheckedREP': isEnabled};
    _saveSetting('isCheckedREP', isEnabled);
  }

  void toggleDvojnaVrstica(bool isEnabled) {
    state = {...state, 'isCheckedDvojnaVrstica': isEnabled};
    _saveSetting('isCheckedDvojnaVrstica', isEnabled);
  }

  // This method saves the state to SharedPreferences.
  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}

// Create the provider for managing the settings
final settingsProvider = StateNotifierProvider<AppSettings, Map<String, bool>>(
  (ref) => AppSettings(),
);
