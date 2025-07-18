import 'package:flutter/material.dart';

class ErrorDialogs {
  static Future<void> showPrinterErrorDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Napaka pri tiskalniku'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(''),
                Text(
                    'Prosimo, uporabite drug način tiskanja ali preverite nastavitve.'),
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
      },
    );
  }

  static Future<void> showBasicDialog(String text, BuildContext context) async {
    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 300,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop(); // Zapre dialog
                },
              ),
            ],
          );
        });
  }

  static Future<void> showResponseDialog(
      List<String> response, BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  response.join('\n'),
                  style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Zapre dialog
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> showBluetoothErrorDialog(
      BuildContext context, List<String> response) async {
    var racunLine = response.firstWhere(
      (item) => item.contains("Racun st."),
      orElse: () => "",
    );

    var povezanDokumentLine = response.firstWhere(
      (item) => item.contains("Povezan dokument"),
      orElse: () => "",
    );

    if (racunLine.isNotEmpty) {
      RegExp regex = RegExp(r'Racun st\.\s*:\s*([^\n\r]+)');
      RegExp regex2 = RegExp(r'Povezan dokument\s*:\s*([^\n\r]+)');
      Match? match = regex.firstMatch(racunLine);
      Match? match2 = regex2.firstMatch(povezanDokumentLine);

      var cenaLine = response.firstWhere(
        (item) => item.contains("SKUPAJ EUR"),
        orElse: () => "",
      );

      RegExp regexCena = RegExp(r'SKUPAJ EUR\s*([\d,]+)');
      Match? matchCena = regexCena.firstMatch(cenaLine);
      String cena = matchCena?.group(1)!.trim() ?? '';

      if (match != null || match2 != null) {
        String racunSt = match?.group(1)?.trim() ?? '';

        int povezanIndex =
            response.indexWhere((item) => item.contains("Povezan dokument:"));

        String povezanDokument = "";
        if (povezanIndex != -1 && povezanIndex + 1 < response.length) {
          String naslednjaVrstica = response[povezanIndex + 1].trim();

          // Uporabi regex za zajem samo številke računa (brez datuma)
          RegExp regex = RegExp(r'^\S+'); // Prva beseda v vrstici
          Match? match = regex.firstMatch(naslednjaVrstica);

          if (match != null) {
            povezanDokument = match.group(0)!; // Ujemanje
          }
        }
        povezanDokument = povezanDokument.replaceAll(",", "").trim();

        // Show the modal dialog with extracted Racun st.
        await showDialog(
          context: context, // Uporabi rootNavigator
          builder: (BuildContext context) {
            return AlertDialog(
              title: povezanDokument.isEmpty
                  ? const Text(
                      "Račun je bil narejen, vendar ni povezave s tiskalnikom")
                  : const Text(
                      "Račun je storniran, vendar ni povezave s tiskalnikom"),
              content: povezanDokument.isEmpty
                  ? Text(
                      'Preverite tiskalnik\n'
                      'in naredite kopijo računa\n\n\n'
                      'Številka računa: $racunSt\n\n'
                      'Cena: $cena €',
                      textAlign: TextAlign.center,
                    )
                  : Text(
                      'Preverite tiskalnik\n'
                      'in naredite kopijo računa\n\n\n'
                      'Številka računa: $racunSt\n\n',
                      textAlign: TextAlign.center,
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      } else {
        throw Exception("Ni povezave s tiskalnikom, račun ni narejen");
      }
    }
  }
}
