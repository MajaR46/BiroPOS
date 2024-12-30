import 'package:biro_pos/controllers/bluetooth_page.dart';
import 'package:biro_pos/controllers/besteron_controller.dart';
import 'package:biro_pos/controllers/print.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/providers/settings_provider.dart';
import 'package:biro_pos/screens/blagajna_screen.dart';
import 'package:biro_pos/screens/kopija_screen.dart';
import 'package:biro_pos/screens/login.dart';
import 'package:biro_pos/screens/porocila_screen.dart';
import 'package:biro_pos/screens/pregled_narocil_screen.dart';
import 'package:biro_pos/screens/storno_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MeniScreen extends ConsumerWidget {
  const MeniScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    final prikazujSamoNarocila = settings['isCheckedPrikazujNarocila'] ?? false;
    double finalSum = ref.watch(narociloNotifierProvider.notifier).totalSum();

    final bool isLoggedIn = SessionManager().isLoggedIn();
    final String? pravicaStorno = SessionManager().pravicaStorno();
    final String? pravicaPregledPorocil =
        SessionManager().pravicaPregledPorocil();
    print("pravica Storno $pravicaStorno");
    print("pravicaPregled porocil $pravicaPregledPorocil");

    void logout() {
      SessionManager().clearSession();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppStyles.white,
      appBar: AppBar(
        backgroundColor: AppStyles.white,
        title: Text("Meni",
            style: AppStyles.heading3.copyWith(color: AppStyles.black)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 64),
          Center(
            child: SizedBox(
              width: 160,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BlagajnaScreen()));
                },
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppStyles.blue),
                child: Text(
                  "Blagajna",
                  style: AppStyles.button1.copyWith(color: AppStyles.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 64),
          if (pravicaStorno == "1" && !prikazujSamoNarocila)
            Center(
              child: SizedBox(
                width: 160,
                height: 50,
                child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const StornoScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.grey),
                    child: Text(
                      "Storno",
                      style: AppStyles.button1.copyWith(color: AppStyles.black),
                    )),
              ),
            ),
          const SizedBox(
            height: 32,
          ),
          if (!prikazujSamoNarocila)
            Center(
              child: SizedBox(
                width: 160,
                height: 50,
                child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const KopijaScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.grey),
                    child: Text(
                      "Kopija",
                      style: AppStyles.button1.copyWith(color: AppStyles.black),
                    )),
              ),
            ),
          const SizedBox(
            height: 32,
          ),
          if (pravicaPregledPorocil == "1" && !prikazujSamoNarocila)
            Center(
              child: SizedBox(
                width: 160,
                height: 50,
                child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PorocilaScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.grey),
                    child: Text(
                      "Poročila",
                      style: AppStyles.button1.copyWith(color: AppStyles.black),
                    )),
              ),
            ),
          const SizedBox(
            height: 32,
          ),
          Center(
            child: SizedBox(
              width: 160,
              height: 50,
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const PregledNarocilScreen()));
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppStyles.grey),
                  child: Text(
                    "Pregled naročil",
                    style: AppStyles.button1.copyWith(color: AppStyles.black),
                  )),
            ),
          ),
          const SizedBox(height: 64),
          Center(
            child: SizedBox(
              width: 160,
              height: 50,
              child: ElevatedButton(
                  onPressed: () => logout(),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppStyles.red),
                  child: Text(
                    "Odjava",
                    style: AppStyles.button1.copyWith(color: AppStyles.white),
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
