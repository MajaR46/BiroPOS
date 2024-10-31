import 'package:biro_pos/components/ok_button.dart';
import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:biro_pos/screens/blagajna_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

class NewTableScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  const NewTableScreen({
    Key? key,
    required this.items,
  }) : super(key: key);

  @override
  State<NewTableScreen> createState() => _NewTableScreenState();
}

class _NewTableScreenState extends State<NewTableScreen> {
  final TextEditingController _newTableController = TextEditingController();

  void _clearText() {
    _newTableController.clear();
  }

  void _addToNewTable(String tableNumber) async {
    String? userId = SessionManager().getLoggedInUserSifra();

    List<String> narociloItems = [];

    for (var item in widget.items) {
      String artikelSifra = item['artikelSifra'] ?? '';
      double kolicina = item['kolicina'] ?? 1.0;
      double originalPrice = item['originalPrice'] ?? 0.0;
      num popust = item['popust'] ?? 0;
      String opis = item['opis'] ?? '';
      String artikelSkupina = item['artikelSkupina'] ?? '';

      String narociloItem =
          '$userId\t$tableNumber\t$artikelSifra\t$kolicina\t$originalPrice\t$popust\t$opis\t$artikelSkupina';

      print("Narocilo item: $narociloItem");

      narociloItems.add(narociloItem);
    }

    List<String> posljiNaStreznik =
        await sendRequest("1", narociloItems.join('\r\n'));
    print("Poslji na streznik $posljiNaStreznik");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppStyles.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Nova miza",
            style: AppStyles.heading3.copyWith(color: AppStyles.black)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 64),
              Center(
                child: Text(
                  "Oznaka mize: ",
                  style: AppStyles.heading2.copyWith(color: AppStyles.black),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _newTableController,
                  cursorColor: AppStyles.blue,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppStyles.silver.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide.none,
                    ),
                    suffixIconColor: AppStyles.blue,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearText,
                      focusColor: AppStyles.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 32),
            child: Align(
              alignment: Alignment.bottomRight,
              child: OKButton(onPressed: () {
                _addToNewTable(_newTableController.text);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => BlagajnaScreen()));
              }),
            ),
          ),
        ],
      ),
    );
  }
}
