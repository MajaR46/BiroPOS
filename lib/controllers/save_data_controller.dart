import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:biro_pos/hive_adaprters/osebje.dart';
import 'package:biro_pos/hive_adaprters/podjetje.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final box = Hive.box('biroposData');
String userId = SessionManager().getLoggedInUserSifra() ?? '';

Future<bool> handleData() async {
  final box = Hive.box('biroposData');
  String? userId = box.get('userId', defaultValue: "");

  try {
    List<String> apiResponseList = await sendRequest(userId!, "BiroPOS.txt");

    await _saveBiroPosData(apiResponseList, box);

    // Categorize and store responses
    categorizeResponse(apiResponseList);

    // Save company tax data for offline use
    await savePodjetjeDavcnaToPrefs();

    return true;
  } catch (e) {
    print("Error fetching data: $e");
    return false;
  }
}

Future<void> _saveBiroPosData(List<String> data, Box box) async {
  await box.put('biroPosData', data);
}

void categorizeResponse(List<String> items) {
  List<Osebje> osebje2 = [];
  List<Podjetje> podatkiPodjetje2 = [];

  for (String item in items) {
    if (item.startsWith('4')) {
      String sifra = item.split('|')[1];
      String username = item.split('|')[2];
      String password = item.split('|')[3];
      String? pravicaPregledPorocil = item.split('|')[4];
      String? pregledSamoSvojihDokumentov = item.split('|')[5];
      String? pravicaStornoProdaja = item.split('|')[6];

      osebje2.add(Osebje(username, password, sifra, pravicaPregledPorocil,
          pregledSamoSvojihDokumentov, pravicaStornoProdaja));
    } else if (item.startsWith('0')) {
      String podjetjeDavcna = item.split('|')[1];
      String imePodjetja = item.split('|')[2];

      podatkiPodjetje2.add(Podjetje(podjetjeDavcna, imePodjetja));
    }
  }

  final box = Hive.box('biroposData');
  box.put('osebje', osebje2);
  box.put('podjetje', podatkiPodjetje2);
}

Future<void> getTables() async {
  List<String> apiResponseList = await sendRequest(userId, "VrniSeznamMiz");
  await box.put('table_data', apiResponseList);
}

Future<void> getOpenTables() async {
  if (userId != null) {
    List<String> apiResponseList =
        await sendRequest(userId, "VrniOdprteMize\t$userId");
    await box.put('open_table_data', apiResponseList);
  } else {
    print("Error: User ID not found in SharedPreferences.");
  }
}

Future<void> getPorocila() async {
  List<String> apiResponseList = await sendRequest(userId, "VrniPorocila");
  await box.put('porocilo_data', apiResponseList);
}

Future<void> savePodjetjeDavcnaToPrefs() async {
  final box = Hive.box(
      'biroposData'); // Access the Hive box where the 'Podjetje' data is stored

  // Retrieve the list of 'Podjetje' objects stored under the key 'podjetje'
  List<Podjetje> podjetjeList =
      box.get('podjetje', defaultValue: []) as List<Podjetje>;

  if (podjetjeList.isNotEmpty) {
    // Access the 'podjetjeDavcna' field of the first 'Podjetje' object
    String podjetjeDavcna = podjetjeList[0].davcna;

    // Save the 'podjetjeDavcna' value to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('podjetjeDavcna', podjetjeDavcna);

    print("Saved podjetjeDavcna to SharedPreferences: $podjetjeDavcna");
  } else {
    print("No podjetje data found.");
  }
}
