import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:biro_pos/providers/settings_provider.dart';
import 'package:biro_pos/screens/blagajna_screen.dart';
import 'package:biro_pos/screens/kopija_screen.dart';
import 'package:biro_pos/screens/login.dart';
import 'package:biro_pos/screens/porocila_screen.dart';
import 'package:biro_pos/screens/storno_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunmi_printer_plus/enums.dart';
// import packages
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:sunmi_printer_plus/sunmi_style.dart';

class MeniScreen extends ConsumerWidget {
  const MeniScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    final prikazujSamoNarocila = settings['isCheckedPrikazujNarocila'] ?? false;

    final bool isLoggedIn = SessionManager().isLoggedIn();
    print(isLoggedIn);

    void logout() {
      SessionManager().clearSession();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }

    List<String> exampleLines = [
      "#VELIKOST-START#", // Začetek velike pisave
      "Naslov Računa",
      "#VELIKOST-END#", // Konec velike pisave
      "Datum: 02.12.2024",
      "Postavka 1: 10.00€",
      "--------------------------------",
      "Postavka 2: 15.00€",
      "Skupaj: 25.00€",
      "#QRKODA#https://example.com#QRKODA#", // QR koda z URL
      "Hvala za obisk!",
    ];

    void printText(text) async {
      await SunmiPrinter.initPrinter();
      await SunmiPrinter.bindingPrinter();
      await SunmiPrinter.startTransactionPrint(true);

      for (final line in exampleLines) {
        await SunmiPrinter.printText(line,
            style: SunmiStyle(
              align: SunmiPrintAlign.LEFT,
              bold: true,
            ));
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
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
          Center(
              child: ElevatedButton(
            onPressed: () {
              printText("To je testtttttttttttt");
            },
            child: Text("Print"),
          )),
          const SizedBox(height: 128),
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
            height: 128,
          ),
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
