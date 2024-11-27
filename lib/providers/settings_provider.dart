import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends StateNotifier<Map<String, bool>> {
  AppSettings()
      : super({
          'isCheckedPrikazujNarocila': false,
          'isCheckedPrikazujRacune': false
        }) {
    _loadSettings();
  }

  // This method loads the saved preferences asynchronously.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final prikazujNarocila =
        prefs.getBool('isCheckedPrikazujNarocila') ?? false;
    final prikazujRacune = prefs.getBool('isCheckedPrikazujRacune') ?? false;

    // Update the state with both values
    state = {
      'isCheckedPrikazujNarocila': prikazujNarocila,
      'isCheckedPrikazujRacune': prikazujRacune,
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
