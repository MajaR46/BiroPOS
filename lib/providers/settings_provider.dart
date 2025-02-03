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
          'isCheckedTiskajNarocilo': false
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
      'isCheckedTiskajNarocilo': tiskajNarocilo
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
