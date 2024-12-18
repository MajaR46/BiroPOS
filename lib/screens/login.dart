import 'package:biro_pos/controllers/bluetooth_controller.dart';
import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/components/numpad.dart';
import 'package:biro_pos/controllers/print.dart';
import 'package:biro_pos/controllers/save_data_controller.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:biro_pos/hive_adaprters/osebje.dart';
import 'package:biro_pos/hive_adaprters/podjetje.dart';
import 'package:biro_pos/models/bondedBlutetoothDevice.dart';
import 'package:biro_pos/screens/api_key_screen.dart';
import 'package:biro_pos/screens/meni_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
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
  final BluetoothService _bluetoothService = BluetoothService();

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  Future<void> _initializeLoginScreen() async {
    bool dataHandled = await handleData();
    if (dataHandled) {
      // Load the categorized data from Hive
      final box = Hive.box('biroposData');
      osebje = List<Osebje>.from(box.get('osebje', defaultValue: []));
      podjetje = List<Podjetje>.from(box.get('podjetje', defaultValue: []));
      setState(() {});
    }

    await _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    try {
      // Fetch bonded devices
      List<BondedDevice> devices = await _bluetoothService.getBondedDevices();

      // Attempt to connect to the required device
      for (final device in devices) {
        if (device.name == "InnerPrinter") {
          await _bluetoothService.connectToDevice(device.adress);
          print("Connected to InnerPrinter");
          break;
        }
      }
    } catch (e) {
      print("Error initializing Bluetooth: $e");
    }
  }

  void _handleOKPressed() async {
    final inputPassword = _logininputcontroller.text;

    // Format current date and time for default password
    String formattedDate = DateFormat("dd").format(currentDate);
    String formattedTime = DateFormat("mm").format(currentDate);

    // Default password
    if (inputPassword == "12${formattedTime}5${formattedDate}98") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ApiKeyScreen(isDefaultPassword: true),
        ),
      );
      return;
    }

    Osebje? matchedUser;
    final box = Hive.box('biroposData');
    osebje = List<Osebje>.from(box.get('osebje', defaultValue: []));

    for (var user in osebje) {
      if (user.password == inputPassword) {
        matchedUser = user;
        break;
      }
    }

    if (matchedUser != null) {
      SessionManager().saveSession(matchedUser.username, matchedUser.sifra);
      await box.put('userId', matchedUser.sifra);
      await box.put('userName', matchedUser.username);
      await box.put('userPassword', matchedUser.password);

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const MeniScreen()));
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
    String? userId = SessionManager().getLoggedInUserSifra() ?? '';

    List<String> responseList = await sendRequest(userId, "echo");

    _showEchoDialog(responseList);
  }

  void _clearText() {
    _logininputcontroller.clear();
  }

  void _refresh() async {
    bool isDataHandled = await handleData(); // Calls the API and updates Hive
    if (isDataHandled) {
      setState(() {
        currentDate = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podatki so bili osveženi!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Napaka pri osveževanju podatkov')),
      );
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
              height: 48,
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
              height: 24,
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
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  formattedDate + " " + formattedTime,
                  style: AppStyles.heading4
                      .copyWith(color: AppStyles.black, fontSize: 10),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
