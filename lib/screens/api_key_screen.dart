import 'package:BiroPOS/app_styles.dart';
import 'package:BiroPOS/components/ok_button.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/controllers/test_connection.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:BiroPOS/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _controllerGroups = TextEditingController();
  final TextEditingController _controllerVelikostNarocila =
      TextEditingController();
  final TextEditingController _controllerPrinterIP = TextEditingController();
  final TextEditingController _controllerEthernetEmptyLines =
      TextEditingController();
  final TextEditingController _controllerVelikostPrintanegaTeksta =
      TextEditingController();
  final TextEditingController _controllerSirinaGumbaTipkovnica =
      TextEditingController();
  final TextEditingController _controllerVisinaGumbaTipkovnica =
      TextEditingController();
  final TextEditingController _controllerFontGumbTipkovnica =
      TextEditingController();

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
  bool _isCheckedEthernetPrint = false;
  bool _isCheckedReceiptCode = false;
  bool _isCheckedREP = false;
  bool _isOnline = true;
  bool _isCheckedDvojnaVrstica = false;
  bool _isCheckedDirektneMize = false;
  String userId = SessionManager().getLoggedInUserSifra() ?? '';
  @override
  void initState() {
    super.initState();
    _loadPreferences();
    //checkConnection();
  }

  void checkConnection() async {
    bool isOnline = await testConnection(userId);
    setState(() {
      _isOnline = isOnline;
    });
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _controllerApiKey.text = prefs.getString('apiKey') ?? 'test';
        _controllerIP.text = prefs.getString('IP') ?? '194.247.162.115';
        _controllerPort.text = prefs.getString('Port') ?? '11111';
        _controllerPOS.text = prefs.getString('POS') ?? '';
        _controllerTID.text = prefs.getString('TID') ?? '';
        _controllerTouchKey.text = prefs.getString('touchKey') ?? '12';
        _controllerTextSize.text = prefs.getString('textSize') ?? '14';
        _controllerRefresh.text = prefs.getString('refreshInterval') ?? '5';
        _controllerStStolpcev.text = prefs.getString('stStolpcev') ?? '2';
        _controllerGroups.text = prefs.getString('groupsSize') ?? '16';
        _controllerVelikostNarocila.text =
            prefs.getString('velikostNarocila') ?? '16';
        _controllerPrinterIP.text = prefs.getString('printerIp') ?? '';
        _controllerEthernetEmptyLines.text =
            prefs.getString('ethernetEmptyRows') ?? '';
        _controllerVelikostPrintanegaTeksta.text =
            prefs.getString('velikostPrintanegaTeksta') ?? '32';
        _controllerSirinaGumbaTipkovnica.text =
            prefs.getString('sirinaGumbaTipkovnica') ?? '80';
        _controllerVisinaGumbaTipkovnica.text =
            prefs.getString('visinaGumbaTipkovnica') ?? '50';
        _controllerFontGumbTipkovnica.text =
            prefs.getString('fontGumbTipkovnica') ?? '16';

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
            prefs.getBool('isCheckedBluetoothPrintanje') ?? true;
        _isCheckedEnojniKlik = prefs.getBool('isCheckedEnojniKlik') ?? false;
        _isCheckedBarve = prefs.getBool('isCheckedBarve') ?? false;
        _isCheckedPrikazCene = prefs.getBool('isCheckedPrikazCene') ?? false;
        _isCheckedUsbPrintanje =
            prefs.getBool('isCheckedUsbPrintanje') ?? false;
        _isCheckedVecjiPrint = prefs.getBool('isCheckedVecjiPrint') ?? false;
        _isCheckedEthernetPrint =
            prefs.getBool('isCheckedEthernetPrint') ?? false;
        _isCheckedReceiptCode = prefs.getBool('isCheckedReceiptCode') ?? false;
        _isCheckedREP = prefs.getBool('isCheckedREP') ?? false;
        _isCheckedDvojnaVrstica =
            prefs.getBool('isCheckedDvojnaVrstica') ?? false;
        _isCheckedDirektneMize =
            prefs.getBool('isCheckedDirektneMize') ?? false;
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
    await prefs.setString('groupsSize', _controllerGroups.text);
    await prefs.setString('velikostNarocila', _controllerVelikostNarocila.text);
    await prefs.setString('printerIp', _controllerPrinterIP.text);
    await prefs.setString(
        'ethernetEmptyRows', _controllerEthernetEmptyLines.text);
    await prefs.setString(
        'velikostPrintanegaTeksta', _controllerVelikostPrintanegaTeksta.text);
    await prefs.setString(
        'sirinaGumbaTipkovnica', _controllerSirinaGumbaTipkovnica.text);
    await prefs.setString(
        'visinaGumbaTipkovnica', _controllerVisinaGumbaTipkovnica.text);
    await prefs.setString(
        'fontGumbTipkovnica', _controllerFontGumbTipkovnica.text);

    ////////////////////////7
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
    await prefs.setBool('isCheckedEthernetPrint', _isCheckedEthernetPrint);
    await prefs.setBool('isCheckedReceiptCode', _isCheckedReceiptCode);
    await prefs.setBool('isCheckedREP', _isCheckedREP);
    await prefs.setBool('isCheckedDvojnaVrstica', _isCheckedDvojnaVrstica);
    await prefs.setBool('isCheckedDirektneMize', _isCheckedDirektneMize);
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isButtonsDisabled = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppStyles.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: GestureDetector(
          //onTap: checkConnection,
          child: AppBar(
            backgroundColor: AppStyles.white,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.black),
                onPressed: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()));
                  HapticFeedback.vibrate();
                }),
            title: Text("Nastavitve",
                style: AppStyles.heading3.copyWith(color: AppStyles.black)),
            centerTitle: true,
            /*
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: Text(
                  _isOnline ? "Online" : "Offline",
                  style: AppStyles.paragraph3.copyWith(
                    color: _isOnline ? AppStyles.green : AppStyles.brightRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
            */
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (widget.isDefaultPassword)
                      const SizedBox(
                        height: 32,
                      ),
                    if (widget.isDefaultPassword)
                      Text("Osnovne nastavitve",
                          style: AppStyles.paragraph1.copyWith(
                              color: AppStyles.black.withOpacity(0.5))),
                    if (widget.isDefaultPassword) Divider(),
                    if (widget.isDefaultPassword)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Align(
                            alignment: Alignment.center,
                            child: Text(
                              'Api ključ:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          ApiKeyTextfield(
                              inputwidth: 500,
                              controller: _controllerApiKey,
                              isHidden: true)
                        ],
                      ),
                    if (widget.isDefaultPassword)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Align(
                            alignment: Alignment.center,
                            child: Text('IP:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ApiKeyTextfield(
                            controller: _controllerIP,
                            isHidden: false,
                            inputwidth: 500,
                          ),
                        ],
                      ),
                    if (widget.isDefaultPassword)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Align(
                            alignment: Alignment.center,
                            child: Text('Port:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ApiKeyTextfield(
                            inputwidth: 500,
                            controller: _controllerPort,
                            isHidden: false,
                          ),
                        ],
                      ),
                    if (widget.isDefaultPassword)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Align(
                            alignment: Alignment.center,
                            child: Text('POS terminal:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ApiKeyTextfield(
                            inputwidth: 500,
                            controller: _controllerPOS,
                            isHidden: false,
                          ),
                        ],
                      ),
                    if (widget.isDefaultPassword)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Align(
                            alignment: Alignment.center,
                            child: Text('TID:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ApiKeyTextfield(
                            inputwidth: 500,
                            controller: _controllerTID,
                            isHidden: false,
                          ),
                        ],
                      ),
                    const SizedBox(
                      height: 32,
                    ),
                    Text("Vrsta tiskanja",
                        style: AppStyles.paragraph1
                            .copyWith(color: AppStyles.black.withOpacity(0.5))),
                    Divider(),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text("Ethernet printanje:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyCheckbox(
                          value: _isCheckedEthernetPrint,
                          onChanged: (bool? value) {
                            setState(() {
                              _isCheckedEthernetPrint = value ?? false;
                            });
                            ref
                                .read(settingsProvider.notifier)
                                .toggleEthernetPrint(value ?? false);
                          },
                        ),
                      ],
                    ),
                    if (_isCheckedEthernetPrint == true)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Align(
                            alignment: Alignment.center,
                            child: Text('Ip naslov tiskalnika:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ApiKeyTextfield(
                            inputwidth: 500,
                            controller: _controllerPrinterIP,
                            isHidden: false,
                          ),
                        ],
                      ),
                    if (_isCheckedEthernetPrint == true)
                      Row(
                        children: [
                          const Expanded(
                            child: Text("Število praznih vrstic:",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ApiKeyTextfield(
                            controller: _controllerEthernetEmptyLines,
                            inputwidth: 150,
                            isHidden: false,
                          ),
                        ],
                      ),
                    const SizedBox(
                      height: 32,
                    ),
                    Text("Naročila",
                        style: AppStyles.paragraph1
                            .copyWith(color: AppStyles.black.withOpacity(0.5))),
                    Divider(),
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
                    const SizedBox(
                      height: 32,
                    ),
                    Text("Velikost pisave",
                        style: AppStyles.paragraph1
                            .copyWith(color: AppStyles.black.withOpacity(0.5))),
                    Divider(),
                    Row(
                      children: [
                        const Expanded(
                          child: Text("Velikost pisave touch tipke:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyTextfield(
                          controller: _controllerTouchKey,
                          inputwidth: 150,
                          isHidden: false,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(
                          child: Text("Velikost pisave skupine:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyTextfield(
                          controller: _controllerGroups,
                          inputwidth: 150,
                          isHidden: false,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(
                          child: Text("Velikost pisave naročila:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyTextfield(
                          controller: _controllerVelikostNarocila,
                          inputwidth: 150,
                          isHidden: false,
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
                            value: _isCheckedVecjiPrint,
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
                    if (_isCheckedVecjiPrint == true)
                      Row(
                        children: [
                          const Expanded(
                            child: Text("Velikost:",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ApiKeyTextfield(
                            controller: _controllerVelikostPrintanegaTeksta,
                            inputwidth: 150,
                            isHidden: false,
                          ),
                        ],
                      ),
                    const SizedBox(
                      height: 32,
                    ),
                    Text("Prikaz blagajne",
                        style: AppStyles.paragraph1
                            .copyWith(color: AppStyles.black.withOpacity(0.5))),
                    Divider(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text("Vprašaj za ceno, če je 0,0:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyCheckbox(
                          value:
                              ref.watch(settingsProvider)['isCheckedMoney'] ??
                                  false,
                          onChanged: (bool? value) {
                            setState(() {
                              _isCheckedMoney = value ?? false;
                            });

                            // Update provider state
                            ref
                                .read(settingsProvider.notifier)
                                .toggleIsCheckedMoney(value ?? false);
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text('Širina gumba:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyTextfield(
                          controller: _controllerSirinaGumbaTipkovnica,
                          inputwidth: 150,
                          isHidden: false,
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text('Višina gumba:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyTextfield(
                          controller: _controllerVisinaGumbaTipkovnica,
                          inputwidth: 150,
                          isHidden: false,
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text('Velikost teksta:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyTextfield(
                          controller: _controllerFontGumbTipkovnica,
                          inputwidth: 150,
                          isHidden: false,
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text("Skupine v dveh vrsticah:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyCheckbox(
                          value: _isCheckedDvojnaVrstica,
                          onChanged: (bool? value) {
                            setState(() {
                              _isCheckedDvojnaVrstica = value ?? false;
                            });
                            ref
                                .read(settingsProvider.notifier)
                                .toggleDvojnaVrstica(value ?? false);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    Text("Ostalo",
                        style: AppStyles.paragraph1
                            .copyWith(color: AppStyles.black.withOpacity(0.5))),
                    Divider(),
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
                          child: Text("Koda na računu:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyCheckbox(
                          value: _isCheckedReceiptCode,
                          onChanged: (bool? value) {
                            setState(() {
                              _isCheckedReceiptCode = value ?? false;
                            });
                            ref
                                .read(settingsProvider.notifier)
                                .toggleReceiptCode(value ?? false);
                          },
                        ),
                      ],
                    ),
                    if (widget.isDefaultPassword)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Text("Reprezentanca:",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ApiKeyCheckbox(
                            value: _isCheckedREP,
                            onChanged: (bool? value) {
                              setState(() {
                                _isCheckedREP = value ?? false;
                              });
                              ref
                                  .read(settingsProvider.notifier)
                                  .toggleREP(value ?? false);
                            },
                          ),
                        ],
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text("Direktne mize:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ApiKeyCheckbox(
                          value: _isCheckedDirektneMize,
                          onChanged: (bool? value) {
                            setState(() {
                              _isCheckedDirektneMize = value ?? false;
                            });
                            ref
                                .read(settingsProvider.notifier)
                                .toggleDirektneMize(value ?? false);
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
          textAlignVertical: TextAlignVertical.center,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 10.0),
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
