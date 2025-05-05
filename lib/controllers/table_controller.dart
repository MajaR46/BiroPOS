import 'package:BiroPOS/controllers/klic.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';

class TableService {
  static Future<List<Map<String, String>>> fetchTables() async {
    try {
      String? userId = SessionManager().getLoggedInUserSifra();

      String txtData = 'VrniSeznamMiz';
      List<String> apiResponseList = await sendRequest(userId!, txtData);
      List<Map<String, String>> parsedTables = [];

      for (String line in apiResponseList) {
        List<String> splitLine = line.split('|');

        if (splitLine.length >= 4) {
          String prostor = splitLine[0];
          String miza = splitLine[1];
          String cena = splitLine[2].replaceAll(',', '.');

          parsedTables.add({
            'miza': miza,
            'prostor': prostor,
            'cena': cena.isNotEmpty ? cena : '',
          });
        }
      }

      return parsedTables;
    } catch (e) {
      print('Napaka pri pridobivanju miz: $e');
      return [];
    }
  }
}
