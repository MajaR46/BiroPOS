import 'dart:async';

import 'package:biro_pos/controllers/bluetooth_controller.dart';
import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/components/numpad.dart';
import 'package:biro_pos/controllers/print.dart';
import 'package:biro_pos/controllers/save_data_controller.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:biro_pos/hive_adaprters/osebje.dart';
import 'package:biro_pos/hive_adaprters/podjetje.dart';
import 'package:biro_pos/models/bondedBlutetoothDevice.dart';
import 'package:biro_pos/providers/settings_provider.dart';
import 'package:biro_pos/screens/api_key_screen.dart';
import 'package:biro_pos/screens/blagajna_screen.dart';
import 'package:biro_pos/screens/meni_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

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
  final TextEditingController _logininputcontroller = TextEditingController();
  final bool _isHidden = true;
  List<Osebje> osebje = [];
  List<Podjetje> podjetje = [];
  final BluetoothService _bluetoothService = BluetoothService();
  String? lastRefresh;
  String verzijaPrograma = '5.3.1';
  String formattedDate = '';
  String formattedTime = '';
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
    _loadLastRefreshTime();

    DateTime currentDate = DateTime.now();
    formattedDate = DateFormat("dd.MM.yyyy").format(currentDate);
    formattedTime = DateFormat("HH:mm").format(currentDate);

    setState(() {});

    _timer = Timer.periodic(const Duration(seconds: 2), (Timer timer) {
      DateTime currentDate = DateTime.now();
      setState(() {
        formattedDate = DateFormat("dd.MM.yyyy").format(currentDate);
        formattedTime = DateFormat("HH:mm").format(currentDate);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _logininputcontroller.dispose();
    super.dispose();
  }

  Future<void> _loadLastRefreshTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      lastRefresh = prefs.getString('refreshDate');
    });
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
      final settings = ref.watch(settingsProvider);

      // Attempt to connect to the required device
      for (final device in devices) {
        if (device.name == "InnerPrinter" ||
            device.name == "BlueTooth Printer" ||
            device.name == "IPosPrinter" ||
            device.name == "IPos2Printer" ||
            device.name == "OM BP" ||
            device.name == "P58E" ||
            device.name == "RPP-02" ||
            device.name == "RPP02N" ||
            device.name == "TimPOS" ||
            device.name == "NT barcode scanner") {
          await _bluetoothService.connectToDevice(context);
          print("Connected to ${device.adress}");
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
    DateTime currentDate = DateTime.now();

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
      SessionManager().saveSession(matchedUser.username, matchedUser.sifra,
          matchedUser.pravicaStornoProdaja, matchedUser.pravicaPregledPorocil);
      await box.put('userId', matchedUser.sifra);
      await box.put('userName', matchedUser.username);
      await box.put('userPassword', matchedUser.password);

      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const BlagajnaScreen()));
    } else if (inputPassword == "999") {
      SystemNavigator.pop();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nepravilno geslo')));
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

  static Future<void> testPrinterCompatibility() async {
    final SunmiPrinterPlus printer = SunmiPrinterPlus();

    try {
      // Nastavite višjo pisavo (ESC ! 16)
      List<int> tallerFontCommand = [27, 33, 16]; // Samo višja pisava
      await printer.printEscPos(data: tallerFontCommand);
      await printer.printText(text: "To je višja pisava\n");

      // Ponastavite na privzeto pisavo (ESC ! 0)
      List<int> defaultFontCommand = [27, 33, 0]; // Privzeta pisava
      await printer.printEscPos(data: defaultFontCommand);
      await printer.printText(text: "To je privzeta pisava\n");

      print("Test pisave je bil uspešno izveden.");
    } catch (e) {
      print("Napaka pri testiranju tiskalnika: $e");
    }
  }

  void _handleTestConnection() async {
    String? userId = SessionManager().getLoggedInUserSifra() ?? '';

    try {
      List<String> responseList = await sendRequest(userId, "echo");

      if (responseList.isEmpty) {
        responseList = ["Povezava ni uspela", "N/A", "N/A"];
      }

      _showEchoDialog(responseList);
    } catch (e) {
      _showEchoDialog(["Napaka pri povezavi", "N/A", "N/A"]);
    }
  }

  void _clearText() {
    _logininputcontroller.clear();
  }

  void _refresh() async {
    try {
      bool isDataHandled = await handleData();
      if (isDataHandled) {
        setState(() {
          DateTime currentDate = DateTime.now();
          lastRefresh = currentDate.toIso8601String();
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('refreshDate', lastRefresh!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Podatki so bili osveženi!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Napaka pri osveževanju podatkov: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = SessionManager().isLoggedIn();

    String formattedLastRefresh = lastRefresh != null
        ? DateFormat("dd.MM.yyyy HH:mm").format(DateTime.parse(lastRefresh!))
        : "Ni podatka";
    return Scaffold(
      backgroundColor: AppStyles.white,
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(formattedDate),
                )),
                Expanded(
                    child: Align(
                  alignment: Alignment.topRight,
                  child: Text(formattedTime),
                ))
              ],
            ),
            const SizedBox(
              height: 40,
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
            SizedBox(
              width: 150,
              height: 50,
              child: ElevatedButton(
                onPressed: _refresh,
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppStyles.blue),
                child: Text(
                  "Osveži",
                  style: AppStyles.heading3.copyWith(
                      color: AppStyles.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _handleTestConnection,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Test\npovezave",
                      textAlign: TextAlign.center,
                      style: AppStyles.button2.copyWith(color: AppStyles.black),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ApiKeyScreen(
                                  isDefaultPassword: false,
                                )));
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Api ključ",
                      textAlign: TextAlign.center,
                      style: AppStyles.button2.copyWith(color: AppStyles.black),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    Print.printText(
                        context, ["Programska oprema BiroPOS"], ref);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Test\ntiskalnika",
                      textAlign: TextAlign.center,
                      style: AppStyles.button2.copyWith(color: AppStyles.black),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  'Osveženo: $formattedLastRefresh, verzija: $verzijaPrograma',
                  style: AppStyles.paragraph3
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
