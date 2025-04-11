import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:BiroPOS/screens/blagajna_screen.dart';
import 'package:BiroPOS/screens/kopija_screen.dart';
import 'package:BiroPOS/screens/login.dart';
import 'package:BiroPOS/screens/porocila_screen.dart';
import 'package:BiroPOS/screens/pregled_narocil_screen.dart';
import 'package:BiroPOS/screens/storno_screen.dart';
import 'package:BiroPOS/screens/testbluetooth.dart';
import 'package:flutter/material.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MeniScreen extends ConsumerWidget {
  const MeniScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    final prikazujSamoNarocila = settings['isCheckedPrikazujNarocila'] ?? false;
    final prikazNarocil = settings['isCheckedPregledNarocil'] ?? false;

    final String? pravicaStorno = SessionManager().pravicaStorno();
    final String? pravicaPregledPorocil =
        SessionManager().pravicaPregledPorocil();

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
              width: MediaQuery.of(context).size.width * 0.5,
              height: 60,
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
                  style: AppStyles.heading3.copyWith(color: AppStyles.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 64),
          if (pravicaStorno == "1" && !prikazujSamoNarocila)
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                height: 60,
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
                      style:
                          AppStyles.heading3.copyWith(color: AppStyles.black),
                    )),
              ),
            ),
          const SizedBox(
            height: 16,
          ),
          if (!prikazujSamoNarocila)
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                height: 60,
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
                      style:
                          AppStyles.heading3.copyWith(color: AppStyles.black),
                    )),
              ),
            ),
          const SizedBox(
            height: 16,
          ),
          if (pravicaPregledPorocil == "1" && !prikazujSamoNarocila)
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                height: 60,
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
                      style:
                          AppStyles.heading3.copyWith(color: AppStyles.black),
                    )),
              ),
            ),
          const SizedBox(
            height: 16,
          ),
          if (prikazNarocil)
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                height: 60,
                child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const PregledNarocilScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.grey),
                    child: Text(
                      "Pregled naročil",
                      style:
                          AppStyles.heading3.copyWith(color: AppStyles.black),
                    )),
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                height: 60,
                child: ElevatedButton(
                    onPressed: () => logout(),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.brightRed),
                    child: Text(
                      "Odjava",
                      style:
                          AppStyles.heading3.copyWith(color: AppStyles.white),
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
