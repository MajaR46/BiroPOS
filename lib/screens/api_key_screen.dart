import 'package:BiroPOS/app_styles.dart';
import 'package:BiroPOS/components/ok_button.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:BiroPOS/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiKeyScreen extends ConsumerStatefulWidget {
  final bool isDefaultPassword;
  const ApiKeyScreen({super.key, required this.isDefaultPassword});

  @override
  ConsumerState<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends ConsumerState<ApiKeyScreen> {
  final TextEditingController _controllerApiKey = TextEditingController();
  final TextEditingController _controllerTouchKey = TextEditingController();
  final TextEditingController _controllerTextSize = TextEditingController();
  final TextEditingController _controllerRefresh = TextEditingController();
  final TextEditingController _controllerIP = TextEditingController();
  final TextEditingController _controllerPort = TextEditingController();
  final TextEditingController _controllerPOS = TextEditingController();
  final TextEditingController _controllerTID = TextEditingController();
  final TextEditingController _controllerStStolpcev = TextEditingController();

  bool _isCheckedMoney = false;
  bool _isCheckedOrders = false;
  bool _isCheckedPrikazujNarocila = false;
  bool _isCheckedPrikazujRacune = false;
  bool _isCheckedTiskajNarocilo = false;
  bool _isCheckedIzbirajNacinePlacil = false;
  bool _isCheckedZakljuciRacun = false;
  bool _isCheckedPregledNarocilTiskalnik = false;
  bool _isCheckedTiskajNarociloPriRacunu = false;
  bool _isCheckedPregledNarocil = false;
  bool _isCheckedPrintService = false;
  bool _isCheckedBluetoothPrintanje = true;
  bool _isCheckedEnojniKlik = false;
  bool _isCheckedBarve = false;
  bool _isCheckedPrikazCene = false;
  bool _isCheckedUsbPrintanje = false;
  bool _isCheckedVecjiPrint = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String apiKey = prefs.getString('apiKey') ?? '';
      String ip = prefs.getString('IP') ?? '';
      String port = prefs.getString('Port') ?? '';

      // Set default values if any of them are empty
      if (apiKey.isEmpty || ip.isEmpty || port.isEmpty) {
        await prefs.setString('apiKey', 'test');
        await prefs.setString('IP', '194.247.162.115');
        await prefs.setString('Port', '11111');
      }

      setState(() {
        _controllerApiKey.text = prefs.getString('apiKey') ?? '';
        _controllerIP.text = prefs.getString('IP') ?? '';
        _controllerPort.text = prefs.getString('Port') ?? '';
        _controllerPOS.text = prefs.getString('POS') ?? '';
        _controllerTID.text = prefs.getString('TID') ?? '';
        _controllerTouchKey.text = prefs.getString('touchKey') ?? '';
        _controllerTextSize.text = prefs.getString('textSize') ?? '';
        _controllerRefresh.text = prefs.getString('refreshInterval') ?? '';
        _controllerStStolpcev.text = prefs.getString('stStolpcev') ?? '';

        _isCheckedMoney = prefs.getBool('isCheckedMoney') ?? false;
        _isCheckedOrders = prefs.getBool('isCheckedOrders') ?? false;
        _isCheckedPrikazujNarocila =
            prefs.getBool('isCheckedPrikazujNarocila') ?? false;
        _isCheckedPrikazujRacune =
            prefs.getBool('isCheckedPrikazujRacune') ?? false;
        _isCheckedTiskajNarocilo =
            prefs.getBool('isCheckedTiskajNarocilo') ?? false;
        _isCheckedIzbirajNacinePlacil =
            prefs.getBool('isCheckedIzbirajNacinePlacil') ?? false;
        _isCheckedZakljuciRacun =
            prefs.getBool('isCheckedZakljuciRacun') ?? false;
        _isCheckedPregledNarocilTiskalnik =
            prefs.getBool('isCheckedPregledNarocilTiskalnik') ?? false;
        _isCheckedTiskajNarociloPriRacunu =
            prefs.getBool('isCheckedTiskajNarociloPriRacunu') ?? false;

        _isCheckedPregledNarocil =
            prefs.getBool('isCheckedPregledNarocil') ?? false;
        _isCheckedPrintService =
            prefs.getBool('isCheckedPrintService') ?? false;
        _isCheckedBluetoothPrintanje =
            prefs.getBool('isCheckedBluetoothPrintanje') ?? false;
        _isCheckedEnojniKlik = prefs.getBool('isCheckedEnojniKlik') ?? false;
        _isCheckedBarve = prefs.getBool('isCheckedBarve') ?? false;
        _isCheckedPrikazCene = prefs.getBool('isCheckedPrikazCene') ?? false;
        _isCheckedUsbPrintanje =
            prefs.getBool('isCheckedUsbPrintanje') ?? false;
        _isCheckedVecjiPrint = prefs.getBool('isCheckedVecjiPrint') ?? false;
      });
    } catch (e) {
      print('Error loading preferences: $e');
      // Handle the error gracefully, perhaps show a message or fallback state
    }
  }

  // Shranjevanje vrednosti v SharedPreferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiKey', _controllerApiKey.text);
    await prefs.setString('IP', _controllerIP.text);
    await prefs.setString('Port', _controllerPort.text);
    await prefs.setString('POS', _controllerPOS.text);
    await prefs.setString('TID', _controllerTID.text);
    await prefs.setString('touchKey', _controllerTouchKey.text);
    await prefs.setString('textSize', _controllerTextSize.text);
    await prefs.setString('refreshInterval', _controllerRefresh.text);
    await prefs.setString('stStolpcev', _controllerStStolpcev.text);
    await prefs.setBool('isCheckedMoney', _isCheckedMoney);
    await prefs.setBool('isCheckedOrders', _isCheckedOrders);
    await prefs.setBool(
        'isCheckedPrikazujNarocila', _isCheckedPrikazujNarocila);

    await prefs.setBool('isCheckedPrikazujRacune', _isCheckedPrikazujRacune);
    await prefs.setBool('isCheckedTiskajNarocilo', _isCheckedTiskajNarocilo);
    await prefs.setBool(
        'isCheckedIzbirajNacinePlacil', _isCheckedIzbirajNacinePlacil);
    await prefs.setBool('isCheckedZakljuciRacun', _isCheckedZakljuciRacun);
    await prefs.setBool(
        'isCheckedPregledNarocilTiskalnik', _isCheckedPregledNarocilTiskalnik);
    await prefs.setBool(
        'isCheckedTiskajNarociloPriRacunu', _isCheckedTiskajNarociloPriRacunu);

    await prefs.setBool('isCheckedPregledNarocil', _isCheckedPregledNarocil);
    await prefs.setBool('isCheckedPrintService', _isCheckedPrintService);
    await prefs.setBool(
        'isCheckedBluetoothPrintanje', _isCheckedBluetoothPrintanje);
    await prefs.setBool('isCheckedEnojniKlik', _isCheckedEnojniKlik);
    await prefs.setBool('isCheckedBarve', _isCheckedBarve);
    await prefs.setBool('isCheckedPrikazCene', _isCheckedPrikazCene);
    await prefs.setBool('isCheckedUsbPrintanje', _isCheckedUsbPrintanje);
    await prefs.setBool('isCheckedVecjiPrint', _isCheckedVecjiPrint);

    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isButtonsDisabled = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppStyles.white,
      appBar: AppBar(
        backgroundColor: AppStyles.white,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.black),
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()));
              HapticFeedback.vibrate();
            }),
        title: const Text("Nastavitve",
            style: TextStyle(fontSize: 20, color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Api ključ:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        ApiKeyTextfield(
                            controller: _controllerApiKey, isHidden: true)
                      ],
                    ),
                    if (widget.isDefaultPassword)
                      Column(
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('IP:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ApiKeyTextfield(
                            controller: _controllerIP,
                            isHidden: false,
                          ),
                        ],
                      ),
                    if (widget.isDefaultPassword)
                      Column(
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Port:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ApiKeyTextfield(
                            controller: _controllerPort,
                            isHidden: false,
                          ),
                        ],
                      ),
                    if (widget.isDefaultPassword)
                      Column(
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('POS terminal:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ApiKeyTextfield(
                            controller: _controllerPOS,
                            isHidden: false,
                          ),
                        ],
                      ),
                    if (widget.isDefaultPassword)
                      Column(
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('TID:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ApiKeyTextfield(
                            controller: _controllerTID,
                            isHidden: false,
                          ),
                        ],
                      ),
                    const SizedBox(
                      height: 32,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text("Bluetooth printanje:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyCheckbox(
                          value: _isCheckedBluetoothPrintanje,
                          onChanged: (bool? value) {
                            setState(() {
                              _isCheckedBluetoothPrintanje = value ?? false;
                            });
                            ref
                                .read(settingsProvider.notifier)
                                .toggleBluetoothPrinting(value ?? false);
                          },
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text("USB printanje:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyCheckbox(
                          value: _isCheckedUsbPrintanje,
                          onChanged: (bool? value) {
                            setState(() {
                              _isCheckedUsbPrintanje = value ?? false;
                            });
                            ref
                                .read(settingsProvider.notifier)
                                .toggleUsbPrintanje(value ?? false);
                          },
                        ),
                      ],
                    ),
                    if (widget.isDefaultPassword)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Text("Prikazuj samo naročila:",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ApiKeyCheckbox(
                            value: _isCheckedPrikazujNarocila,
                            onChanged: (bool? value) {
                              setState(() {
                                _isCheckedPrikazujNarocila = value ?? false;
                              });
                              ref
                                  .read(settingsProvider.notifier)
                                  .togglePrikazujNarocila(value ?? false);
                            },
                          ),
                        ],
                      ),
                    if (widget.isDefaultPassword)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Text("Prikazuj samo račune:",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ApiKeyCheckbox(
                            value: _isCheckedPrikazujRacune,
                            onChanged: (bool? value) {
                              setState(() {
                                _isCheckedPrikazujRacune = value ?? false;
                              });
                              ref
                                  .read(settingsProvider.notifier)
                                  .togglePrikazujRacune(value ?? false);
                            },
                          ),
                        ],
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text("Vprašaj za ceno, če je 0,0:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyCheckbox(
                          value: _isCheckedMoney,
                          onChanged: (bool? value) {
                            setState(() {
                              _isCheckedMoney = value ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                    if (widget.isDefaultPassword)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Text("Tiskaj naročilo:",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ApiKeyCheckbox(
                            value: _isCheckedTiskajNarocilo,
                            onChanged: (bool? value) {
                              setState(() {
                                _isCheckedTiskajNarocilo = value ?? false;
                              });
                              ref
                                  .read(settingsProvider.notifier)
                                  .toggleTiskajNarocilo(value ?? false);
                            },
                          ),
                        ],
                      ),
                    Row(
                      children: [
                        const Expanded(
                          child: Text("Velikost pisave touch tipke:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        DropdownMenu(
                            onSelected: (value) {
                              if (value != null) {
                                setState(() {
                                  _controllerTouchKey.text = value;
                                });
                              }
                            },
                            initialSelection: _controllerTouchKey.text,
                            width: 150,
                            menuStyle: const MenuStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                  const Color.fromARGB(255, 235, 233, 233)),
                            ),
                            dropdownMenuEntries: const <DropdownMenuEntry<
                                String>>[
                              DropdownMenuEntry(
                                  value: 'Majhna', label: 'Majhna'),
                              DropdownMenuEntry(
                                  value: 'Srednja', label: 'Srednja'),
                              DropdownMenuEntry(
                                  value: 'Velika', label: 'Velika')
                            ])
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text("Osveži št. minut:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyTextfield(
                          controller: _controllerRefresh,
                          inputwidth: 90,
                          isHidden: false,
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text("Pregled naročil tiskalnik:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyCheckbox(
                          value: _isCheckedPregledNarocilTiskalnik,
                          onChanged: (bool? value) {
                            setState(() {
                              _isCheckedPregledNarocilTiskalnik =
                                  value ?? false;
                            });
                            ref
                                .read(settingsProvider.notifier)
                                .togglePregledNarocilTiskalnik(value ?? false);
                          },
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text('Število stolpcev:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyTextfield(
                          controller: _controllerStStolpcev,
                          inputwidth: 150,
                          isHidden: false,
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text("Privzete barve:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyCheckbox(
                          value: _isCheckedBarve,
                          onChanged: (bool? value) {
                            setState(() {
                              _isCheckedBarve = value ?? false;
                            });
                            ref
                                .read(settingsProvider.notifier)
                                .toggleBarve(value ?? false);
                          },
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text("Prikaži cene:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyCheckbox(
                          value: _isCheckedPrikazCene,
                          onChanged: (bool? value) {
                            setState(() {
                              _isCheckedPrikazCene = value ?? false;
                            });
                            ref
                                .read(settingsProvider.notifier)
                                .togglePrikazCene(value ?? false);
                          },
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text("Touch enojni klik:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyCheckbox(
                          value: _isCheckedEnojniKlik,
                          onChanged: (bool? value) {
                            setState(() {
                              _isCheckedEnojniKlik = value ?? false;
                            });
                            ref
                                .read(settingsProvider.notifier)
                                .toogleEnojniKlik(value ?? false);
                          },
                        ),
                      ],
                    ),
                    if (widget.isDefaultPassword)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Text("Tiskaj naročilo pri računu:",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ApiKeyCheckbox(
                            value: ref.watch(settingsProvider)[
                                    'isCheckedTiskajNarociloPriRacunu'] ??
                                false,
                            onChanged: (bool? value) {
                              setState(() {
                                _isCheckedTiskajNarociloPriRacunu =
                                    value ?? false;
                              });

                              // Update provider state
                              ref
                                  .read(settingsProvider.notifier)
                                  .toggleTiskajNarociloPriRacunu(
                                      value ?? false);
                            },
                          ),
                        ],
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text("Pregled naročil:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyCheckbox(
                          value: _isCheckedPregledNarocil,
                          onChanged: (bool? value) {
                            setState(() {
                              _isCheckedPregledNarocil = value ?? false;
                            });
                            ref
                                .read(settingsProvider.notifier)
                                .togglePregledNarocil(value ?? false);
                          },
                        ),
                      ],
                    ),
                    if (widget.isDefaultPassword)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Text("Večja velikost teksta pri računu:",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ApiKeyCheckbox(
                            value: ref.watch(
                                    settingsProvider)['isCheckedVecjiPrint'] ??
                                false,
                            onChanged: (bool? value) {
                              setState(() {
                                _isCheckedVecjiPrint = value ?? false;
                              });

                              // Update provider state
                              ref
                                  .read(settingsProvider.notifier)
                                  .toggleVecjiPrint(value ?? false);
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 24, top: 8),
              child: Align(
                alignment: Alignment.bottomRight,
                child: OKButton(
                  onPressed: () {
                    HapticFeedback.vibrate();

                    _savePreferences();
                    SystemChrome.setEnabledSystemUIMode(
                        SystemUiMode.immersiveSticky);
                  },
                  text: 'Shrani',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ApiKeyTextfield extends StatelessWidget {
  final TextEditingController controller;
  final double? inputwidth;
  final bool isHidden;
  const ApiKeyTextfield(
      {super.key,
      required this.controller,
      this.inputwidth,
      required this.isHidden});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: inputwidth,
        child: TextField(
          controller: controller,
          obscureText: isHidden,
          textAlignVertical: TextAlignVertical.bottom,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppStyles.blue, width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppStyles.blue, width: 2),
            ),
          ),
        ));
  }
}

class ApiKeyCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const ApiKeyCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (_) {
            onChanged(_);
            HapticFeedback.vibrate();
          },
          activeColor: AppStyles.blue,
        ),
      ],
    );
  }
}
