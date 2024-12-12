import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/components/numpad.dart';
import 'package:biro_pos/controllers/print.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:biro_pos/models/podjetje.dart';
import 'package:biro_pos/screens/api_key_screen.dart';
import 'package:biro_pos/screens/meni_screen.dart';
import 'package:biro_pos/screens/test.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ResponseCategory { osebje }

abstract class ResponseItem {
  final String ime;
  final ResponseCategory kategorija;

  ResponseItem(this.ime, this.kategorija);

  @override
  String toString() {
    return ime;
  }
}

class Osebje extends ResponseItem {
  final String password;
  final String sfira;
  Osebje(String ime, this.password, this.sfira)
      : super(ime, ResponseCategory.osebje);
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  DateTime currentDate = DateTime.now();
  final TextEditingController _logininputcontroller = TextEditingController();
  final bool _isHidden = true;
  List<Osebje> osebje = [];
  List<Podjetje> podjetje = [];

  @override
  void initState() {
    super.initState();
    _handleData();
  }

  Future<bool> _handleData() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId') ?? "";

    try {
      List<String> apiResponseList = await sendRequest(userId, "BiroPOS.txt");
      await _saveBiroPosData(apiResponseList);
      _categorizeResponse(apiResponseList);

      return true;
    } catch (e) {
      print("Error fetching data: $e");
      return false;
    }
  }

  Future<void> _saveBiroPosData(List<String> apiResponseList) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> biroPosData = apiResponseList; // Convert list to a string
    await prefs.setStringList('biropos_data', biroPosData); // Save the data
  }

  Future<void> getTables() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId') ?? "";

    List<String> apiResponseList = await sendRequest(userId, "VrniSeznamMiz");
    await prefs.setStringList('table_data', apiResponseList);
  }

  Future<void> getOpenTables() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId != null) {
      List<String> apiResponseList =
          await sendRequest(userId, "VrniOdprteMize\t$userId");
      await prefs.setStringList('open_table_data', apiResponseList);
    } else {
      print("Error: User ID not found in SharedPreferences.");
    }
  }

  Future<void> getPorocila() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId') ?? "";

    List<String> apiResponseList = await sendRequest(userId, "VrniPorocila");
    await prefs.setStringList('porocilo_data', apiResponseList);
  }

  void _categorizeResponse(List<String> items) {
    List<Osebje> osebje2 = [];
    List<Podjetje> podatkiPodjetje2 = [];

    for (String item in items) {
      if (item.startsWith('4')) {
        String sifra = item.split('|')[1];
        String username = item.split('|')[2];
        String password = item.split('|')[3];

        osebje2.add(Osebje(username, password, sifra));
      } else if (item.startsWith('0')) {
        String podjetjeDavcna = item.split('|')[1];
        String imePodjetja = item.split('|')[2];

        podatkiPodjetje2.add(Podjetje(podjetjeDavcna, imePodjetja));
      }
    }

    setState(() {
      osebje = osebje2;
      podjetje = podatkiPodjetje2;
    });
  }

  void _handleOKPressed() async {
    final inputPassword = _logininputcontroller.text;
    String formattedDate = DateFormat("dd").format(currentDate);
    String formattedTime = DateFormat("mm").format(currentDate);

    if (inputPassword == "12${formattedTime}5${formattedDate}98") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const ApiKeyScreen(isDefaultPassword: true)),
      );
      return;
    }

    Osebje? matchedUser;
    for (var user in osebje) {
      if (user.password == inputPassword) {
        matchedUser = user;
        break;
      }
    }

    if (matchedUser != null) {
      // Store the matched user session
      SessionManager().saveSession(matchedUser.ime, matchedUser.sfira);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', matchedUser.sfira);
      await prefs.setString('userName', matchedUser.ime);
      await prefs.setString('userPassword', matchedUser.password);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const MeniScreen()));

      await getTables();
      await getOpenTables();
      await getPorocila();
      await prefs.setString('podjetjeDavcna', podjetje[0].toString());
    } else if (inputPassword == "999") {
      SystemNavigator.pop();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nepravilno geslo')));
    }
  }

  _launchURL(String urlString) async {
    Uri url = Uri.parse(urlString);

    if (await launchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _showEchoDialog(List<String> response) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              "Test povezave",
              style: AppStyles.heading3,
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Stanje: ${response[0].replaceAll('|', '')}'),
                  Text('Datum in čas: ${response[1].replaceAll('|', '')}'),
                  Text('Verzija: ${response[2].replaceAll('|', '')}')
                ],
              ),
            ),
            actions: [
              TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppStyles.blue),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"))
            ],
          );
        });
  }

  void _handleTestConnection() async {
    final prefs = await SharedPreferences.getInstance();

    String? userId = prefs.getString('userId') ?? "";

    List<String> responseList = await sendRequest(userId, "echo");

    _showEchoDialog(responseList);
  }

  void _clearText() {
    _logininputcontroller.clear();
  }

  void _refresh() async {
    bool isDataHandled = await _handleData();
    if (isDataHandled) {
      setState(() {
        currentDate = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = SessionManager().isLoggedIn();
    String formattedDate = DateFormat("EEE, dd. MMM yyyy").format(currentDate);
    String formattedTime = DateFormat("HH:mm").format(currentDate);
    print(isLoggedIn);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(
              height: 32,
            ),
            Text('Prijava',
                style: AppStyles.heading1.copyWith(color: AppStyles.black)),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 250,
                child: TextField(
                  obscureText: _isHidden,
                  controller: _logininputcontroller,
                  readOnly: true,
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: AppStyles.silver.withOpacity(0.1),
                      suffixIconColor: AppStyles.blue,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearText,
                        focusColor: AppStyles.blue,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: BorderSide.none,
                      )),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Numpad(
              controller: _logininputcontroller,
              onOKPressed: _handleOKPressed,
            ),
            const SizedBox(
              height: 30,
            ),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ApiKeyScreen(
                                isDefaultPassword: false,
                              )));
                },
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppStyles.blue),
                child: Text(
                  "Api ključ",
                  style: AppStyles.heading3.copyWith(color: AppStyles.white),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleTestConnection,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      "Test\npovezave",
                      textAlign: TextAlign.center,
                      style: AppStyles.button2.copyWith(color: AppStyles.black),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 80,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _refresh,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      "Osveži",
                      textAlign: TextAlign.center,
                      style: AppStyles.button2.copyWith(color: AppStyles.black),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 80,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      printTextWithFormatting("Programska oprema BiroPOS",
                          "BlueTooth Printer", ref);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      "Test\ntiskalnika",
                      textAlign: TextAlign.center,
                      style: AppStyles.button2.copyWith(color: AppStyles.black),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(children: [
              GestureDetector(
                  onTap: () => _launchURL("https://www.biropos.si/"),
                  child: const Text("BiroPOS", style: AppStyles.paragraph1)),
              Spacer(),
              GestureDetector(
                  onTap: () => _launchURL(
                      "https://play.google.com/store/apps/datasafety?id=si.Flop.BiroPOS&pli=1"),
                  child:
                      const Text("Pogoji uporabe", style: AppStyles.paragraph1))
            ]),
            Row(children: [
              Text(
                formattedDate + " " + formattedTime,
                style: AppStyles.heading4
                    .copyWith(color: AppStyles.black, fontSize: 10),
              ),
            ])
          ],
        ),
      ),
    );
  }
}
