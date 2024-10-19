import 'package:biro_pos/components/blagajna_banner.dart';
import 'package:biro_pos/controllers/ble_controller.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:provider/provider.dart';

import 'package:biro_pos/controllers/klic.dart';
import 'package:flutter/material.dart';

enum ResponseCategory { izdelki, dodatki, osebje }

abstract class ResponseItem {
  final String ime;
  final ResponseCategory kategorija;

  ResponseItem(this.ime, this.kategorija);

  @override
  String toString() {
    return ime;
  }
}

class Izdelek extends ResponseItem {
  final String cena;
  Izdelek(String ime, this.cena) : super(ime, ResponseCategory.izdelki);
}

class Dodatek extends ResponseItem {
  Dodatek(String ime) : super(ime, ResponseCategory.dodatki);
}

class Osebje extends ResponseItem {
  final String password;
  Osebje(String ime, this.password) : super(ime, ResponseCategory.osebje);
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  List<Izdelek> izdelki = [];
  List<Dodatek> dodatki = [];
  List<Osebje> osebje = [];
  String response = "";

  Future<void> _handleData() async {
    List<String> apiResponseList = await sendRequest("1", "BiroPOS.txt");
    print("Data fetched: $apiResponseList");

    _categoriseItems(apiResponseList);
  }

  void _categoriseItems(List<String> items) {
    List<Izdelek> izdelki2 = [];
    List<Dodatek> dodatki2 = [];
    List<Osebje> osebje2 = [];

    for (String item in items) {
      if (item.startsWith('1')) {
        String imeIzdelka = item.split('|')[2];
        String cena = item.split('|')[3];
        String HHcena = item.split('|')[4];
        String podkategorija = item.split('|')[5];
        String eanKoda = item.split('|')[6];
        izdelki2.add(Izdelek(imeIzdelka, cena));
      } else if (item.startsWith('D')) {
        String imeDodatka = item.split('|')[1];
        String kategorijaDodatka = item.split('|')[2];
        dodatki2.add(Dodatek(imeDodatka + kategorijaDodatka));
      } else if (item.startsWith('4')) {
        String userName = item.split('|')[2];
        String password = item.split('|')[3];
        osebje2.add(Osebje(userName, password));
      }
    }

    setState(() {
      izdelki = izdelki2;
      dodatki = dodatki2;
      osebje = osebje2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bleProvider = Provider.of<BleProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Test Screen")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 64),
              child: ElevatedButton(
                onPressed: _handleData, // Call _handleData when pressed
                child: const Text("Show"),
              ),
            ),
            const SizedBox(height: 20), // Add some spacing
            const Text(
              'Izdelki:',
            ),
            ...izdelki.map((item) => Text(item.cena)).toList(),
            const SizedBox(height: 20),
            const Text('Dodatki'),
            ...dodatki.map((item) => Text(item.toString())).toList(),

            const SizedBox(height: 20),
            const Text('Osebje'),
            ...osebje.map((item) => Text(item.password)).toList()
          ],
        ),
      ),
    );
  }
}
