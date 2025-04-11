import 'package:BiroPOS/app_styles.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Vracilo {
  static double izracunVracila(WidgetRef ref, double vnesenZnesek) {
    double finalSum = ref.read(narociloNotifierProvider.notifier).totalSum();

    final chosenItems = ref.read(narociloNotifierProvider);

    if (chosenItems.isNotEmpty && vnesenZnesek > finalSum) {
      double vracilo = vnesenZnesek - finalSum;
      return vracilo;
    }
    return 0.0;
  }

  static Future<void> showReturnDialog(BuildContext context,
      double vnesenZnesek, double finalSum, double vracilo) async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Center(child: Text("Vračilo")),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                    "Prejeto: ${vnesenZnesek.toStringAsFixed(2)} €",
                    style: AppStyles.paragraph1,
                  ),
                  Text(
                    "Za plačilo : ${finalSum.toStringAsFixed(2)} €",
                    style: AppStyles.paragraph1,
                  ),
                  Text(""),
                  Text("Vračilo: ${vracilo.toStringAsFixed(2)} €",
                      style: AppStyles.boldanparagraph1),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Zapre dialog
                },
              ),
            ],
          );
        });
  }
}
