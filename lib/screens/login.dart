import 'dart:async';
import 'dart:io';

import 'package:BiroPOS/controllers/bluetooth_controller.dart';
import 'package:BiroPOS/controllers/klic.dart';
import 'package:BiroPOS/components/numpad.dart';
import 'package:BiroPOS/controllers/print.dart';
import 'package:BiroPOS/controllers/save_data_controller.dart';
import 'package:BiroPOS/controllers/test_connection.dart';
import 'package:BiroPOS/providers/status_provider.dart';
import 'package:BiroPOS/utils/error_dialog.dart';
import 'package:BiroPOS/utils/generate_receipt_code.dart';
import 'package:BiroPOS/utils/save_to_txt.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/hive_adaprters/blagajna.dart';
import 'package:BiroPOS/hive_adaprters/osebje.dart';
import 'package:BiroPOS/hive_adaprters/podjetje.dart';
import 'package:BiroPOS/models/bondedBlutetoothDevice.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:BiroPOS/screens/api_key_screen.dart';
import 'package:BiroPOS/screens/blagajna_screen.dart';
import 'package:BiroPOS/screens/meni_screen.dart';
import 'package:flutter/material.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:http/http.dart' as http;

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
  List<Blagajna> blagajna = [];
  final BluetoothService _bluetoothService = BluetoothService();
  String? lastRefresh;
  String verzijaPrograma = '5.30.7';
  String formattedDate = '';
  String formattedTime = '';
  late Timer _timer;
  bool _isOnline = true;
  String userId = SessionManager().getLoggedInUserSifra() ?? '';

  @override
  void initState() {
    super.initState();
    _loadLastRefreshTime();
    checkConnection();

    _initializeBluetooth();

    DateTime currentDate = DateTime.now();
    formattedDate = DateFormat("dd.MM.yyyy").format(currentDate);
    formattedTime = DateFormat("HH:mm").format(currentDate);

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

  Future<void> _initializeBluetooth() async {
    try {
      await _bluetoothService.initializeBluetooth();
      await _bluetoothService.checkBluetoothPermissions();

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
    blagajna = List<Blagajna>.from(box.get('blagajna', defaultValue: []));

    for (var user in osebje) {
      if (user.password == inputPassword) {
        matchedUser = user;
        break;
      }
    }

    if (matchedUser != null) {
      SessionManager().saveSession(
        matchedUser.username,
        matchedUser.sifra,
        matchedUser.pravicaStornoProdaja,
        matchedUser.pravicaPregledPorocil,
      );
      await box.put('userId', matchedUser.sifra);
      await box.put('userName', matchedUser.username);
      await box.put('userPassword', matchedUser.password);

      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const BlagajnaScreen()));
    } else if (inputPassword == "999") {
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      } else {
        exit(0);
      }
    } else {
      ErrorDialogs.showBasicDialog("Nepravilno geslo", context);
      _logininputcontroller.clear();
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
                    HapticFeedback.vibrate();

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
      // Izvedemo samo en klic na strežnik
      List<String> responseList = await sendRequest(userId, "echo");

      if (responseList.isNotEmpty && responseList[0] != "Napaka") {
        // Če smo dobili odgovor, vemo da smo ONLINE
        setState(() {
          _isOnline = true;
        });
        _showEchoDialog(responseList);
      } else {
        setState(() {
          _isOnline = false;
        });
        _showEchoDialog(["Povezava ni uspela", "N/A", "N/A"]);
      }
    } catch (e) {
      // V primeru napake (timeout, socket exception) smo OFFLINE
      setState(() {
        _isOnline = false;
      });
      _showEchoDialog(["Napaka pri povezavi", "N/A", "N/A"]);
    }
  }

  void _clearText() {
    _logininputcontroller.clear();
  }

  void _refresh() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Check if apiKey, IP, and Port are empty
      String apiKey = prefs.getString('apiKey') ?? '';
      String ip = prefs.getString('IP') ?? '';
      String port = prefs.getString('Port') ?? '';
      String? tid = prefs.getString('TID');
      String? ds = prefs.getString('podjetjeDavcna');

      // Set default values if any of them are empty
      if (apiKey.isEmpty || ip.isEmpty || port.isEmpty) {
        await prefs.setString('apiKey', 'test');
        await prefs.setString('IP', '194.247.162.115');
        await prefs.setString('Port', '11111');
      }
      bool isDataHandled = await handleData(ref);
      if (isDataHandled) {
        setState(() {
          DateTime currentDate = DateTime.now();
          lastRefresh = currentDate.toIso8601String();
        });

        if (tid != null && tid.isNotEmpty) {
          final url = Uri.parse(
              'https://www.biropos.si/besteron/tid.php?ds=$ds&tid=$tid');
          unawaited(http.get(url).then((response) {
            if (response.statusCode == 200) {
              print("TID klic OK: ${response.body}");
            } else {
              print("Napaka pri TID klicu: ${response.statusCode}");
            }
          }).catchError((e) {
            print("Napaka pri TID klicu: $e");
          }));
        }
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('refreshDate', lastRefresh!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Podatki so bili osveženi!')),
        );
      }
    } catch (e) {
      ErrorDialogs.showBasicDialog(
          "Napaka pri osveževanju podatkov $e", context);
    }
  }

  void checkConnection() async {
    bool isOnline = await testConnection(userId);
    setState(() {
      _isOnline = isOnline;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = SessionManager().isLoggedIn();

    String formattedLastRefresh = lastRefresh != null
        ? DateFormat("dd.MM.yyyy HH:mm").format(DateTime.parse(lastRefresh!))
        : "Ni podatka";
    return Scaffold(
      backgroundColor: AppStyles.white,
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              //onTap: checkConnection,
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(formattedDate),
                    ),
                  ),
                  Expanded(
                      child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      _isOnline ? "Online" : "Offline",
                      style: AppStyles.paragraph3.copyWith(
                        color:
                            _isOnline ? AppStyles.green : AppStyles.brightRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Text(formattedTime),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Text('Prijava',
                        style: AppStyles.heading1
                            .copyWith(color: AppStyles.black)),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 250,
                        child: TextField(
                          obscureText: _isHidden,
                          readOnly: Platform.isWindows ? false : true,

                          controller: _logininputcontroller,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],

                          style: const TextStyle(
                              fontSize: 20), // Make input text larger
                          decoration: InputDecoration(
                              filled: true,
                              fillColor: AppStyles.silver
                                  .withAlpha((0.1 * 255).round()),
                              suffixIconColor: AppStyles.blue,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _clearText();
                                  HapticFeedback.vibrate();
                                },
                                focusColor: AppStyles.blue,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                                borderSide: BorderSide.none,
                              )),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Numpad(
                      controller: _logininputcontroller,
                      onOKPressed: _handleOKPressed,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 150,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          _refresh();
                          HapticFeedback.vibrate();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.blue),
                        child: Text(
                          "Osveži",
                          style: AppStyles.heading3.copyWith(
                              color: AppStyles.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _handleTestConnection();
                            HapticFeedback.vibrate();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: AppStyles.lightGrey,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Test\npovezave",
                              textAlign: TextAlign.center,
                              style: AppStyles.button2
                                  .copyWith(color: AppStyles.black),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: AppStyles.lightGrey,
                            borderRadius:
                                BorderRadius.circular(25), // rounded corners
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.2), // shadow color
                                spreadRadius: 1, // how wide it spreads
                                blurRadius: 2, // softness of the shadow
                                offset: Offset(
                                    0, 2), // horizontal & vertical offset
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () {
                              HapticFeedback.vibrate();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ApiKeyScreen(
                                    isDefaultPassword: false,
                                  ),
                                ),
                              );
                            },
                            icon: Icon(Icons.settings),
                            color: Colors.black, // icon color
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () {
                            HapticFeedback.vibrate();
                            Print.printText(
                                context, ["Programska oprema BiroPOS"], ref);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: AppStyles.lightGrey,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Test\ntiskalnika",
                              textAlign: TextAlign.center,
                              style: AppStyles.button2
                                  .copyWith(color: AppStyles.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Add some padding at the bottom of scrollable content
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // --- Bottom Fixed Text ---
            Padding(
              // Add padding if needed above the text
              padding: const EdgeInsets.only(
                  top: 8.0), // Space between scroll view and text
              child: Text(
                'Osveženo: $formattedLastRefresh, verzija: $verzijaPrograma',
                style: AppStyles.paragraph3
                    .copyWith(color: AppStyles.black, fontSize: 10),
              ),
            )
          ],
        ),
      ),
    );
  }
}
