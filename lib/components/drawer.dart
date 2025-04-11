import 'package:BiroPOS/components/landscape_layout.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:BiroPOS/screens/kopija_screen.dart';
import 'package:BiroPOS/screens/login.dart';
import 'package:BiroPOS/screens/meni_screen.dart';
import 'package:BiroPOS/screens/porocila_screen.dart';
import 'package:BiroPOS/screens/pregled_narocil_screen.dart';
import 'package:BiroPOS/screens/storno_screen.dart';
import 'package:BiroPOS/screens/testbluetooth.dart';
import 'package:flutter/material.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomDrawer extends ConsumerStatefulWidget {
  const CustomDrawer({super.key});

  @override
  ConsumerState<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends ConsumerState<CustomDrawer> {
  @override
  void initState() {
    super.initState();
    _loadPrefereces();
  }

  void _logout() {
    SessionManager().clearSession();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  bool toggleHHCene = false;

  Future<void> _loadPrefereces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        toggleHHCene = prefs.getBool('isCheckedHHCene') ?? false;
      });
    } catch (e) {
      print('Error loading preferences: $e');
      // Handle the error gracefully, perhaps show a message or fallback state
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCheckedHHCene', toggleHHCene);
  }

  @override
  Widget build(BuildContext context) {
    final String? user = SessionManager().getLoggedInUserName();
    final chosenItems = ref.watch(narociloNotifierProvider);
    final settings = ref.watch(settingsProvider);
    final prikazujSamoNarocila = settings['isCheckedPrikazujNarocila'] ?? false;
    final prikazNarocil = settings['isCheckedPregledNarocil'] ?? false;

    final String? pravicaStorno = SessionManager().pravicaStorno();
    final String? pravicaPregledPorocil =
        SessionManager().pravicaPregledPorocil();

    return Drawer(
      backgroundColor: AppStyles.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 64.0, left: 16.0),
            child: Text(
              user ?? '',
              style: AppStyles.heading2.copyWith(color: AppStyles.black),
            ),
          ),
          Row(children: [
            const Padding(
              padding: EdgeInsets.only(left: 20, right: 8, top: 48),
              child: Text(
                "HH Cene",
                style: AppStyles.boldanparagraph1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Switch(
                  activeColor: AppStyles.white,
                  activeTrackColor: AppStyles.blue,
                  value: toggleHHCene,
                  onChanged: (value) {
                    HapticFeedback.vibrate();

                    setState(() {
                      toggleHHCene = value;
                    });
                    _savePreferences();
                    ref.read(settingsProvider.notifier).toggleHHCene(value);
                  }),
            ),
          ]),
          const SizedBox(
            height: 46,
          ),
          if (pravicaStorno == "1" && !prikazujSamoNarocila)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 24.0),
              child: SizedBox(
                width: 160,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.vibrate();

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => StornoScreen()));
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppStyles.blue),
                  child: Text(
                    'Storno',
                    style: AppStyles.button1.copyWith(color: AppStyles.white),
                  ),
                ),
              ),
            ),
          if (!prikazujSamoNarocila)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 24.0),
              child: SizedBox(
                width: 160,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.vibrate();

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const KopijaScreen()));
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppStyles.blue),
                  child: Text(
                    'Kopija',
                    style: AppStyles.button1.copyWith(color: AppStyles.white),
                  ),
                ),
              ),
            ),
          if (pravicaPregledPorocil == "1" && !prikazujSamoNarocila)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 24.0),
              child: SizedBox(
                width: 160,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.vibrate();

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PorocilaScreen()));
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppStyles.blue),
                  child: Text(
                    'Poročila',
                    style: AppStyles.button1.copyWith(color: AppStyles.white),
                  ),
                ),
              ),
            ),
          if (prikazNarocil)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
              child: SizedBox(
                width: 160,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.vibrate();

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const PregledNarocilScreen()));
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppStyles.blue),
                  child: Text(
                    'Pregled naročil',
                    style: AppStyles.button1.copyWith(color: AppStyles.white),
                  ),
                ),
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 32.0),
            child: SizedBox(
              width: 160,
              height: 50,
              child: ElevatedButton(
                onPressed: chosenItems.isEmpty
                    ? () {
                        HapticFeedback.vibrate();
                        _logout();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.brightRed,
                ),
                child: Text(
                  'Odjava',
                  style: AppStyles.button1.copyWith(color: AppStyles.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
