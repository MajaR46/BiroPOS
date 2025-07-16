import 'package:BiroPOS/components/narocilo.dart';
import 'package:BiroPOS/components/ok_button.dart';
import 'package:BiroPOS/controllers/klic.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/controllers/test_connection.dart';
import 'package:BiroPOS/models/narociloitem.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/selecteditem_provider.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:BiroPOS/screens/blagajna_screen.dart';
import 'package:flutter/material.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

class NewTableScreen extends ConsumerStatefulWidget {
  const NewTableScreen({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<NewTableScreen> createState() => _NewTableScreenState();
}

class _NewTableScreenState extends ConsumerState<NewTableScreen> {
  final TextEditingController _newTableController = TextEditingController();
  bool _isOnline = true;
  String userId = SessionManager().getLoggedInUserSifra() ?? '';

  @override
  void initState() {
    super.initState();
    checkConnection();
  }

  void _clearText() {
    _newTableController.clear();
  }

  void _addToNewTable(String tableNumber) async {
    List<NarociloItem> chosenItems = ref.read(narociloNotifierProvider);
    String? userId = SessionManager().getLoggedInUserSifra() ?? '';
    final settings = ref.watch(settingsProvider);
    final tiskajNarocilo = settings['isCheckedTiskajNarocilo'] ?? false;

    if (_newTableController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Oznaka mize ne sme biti prazna")));
    } else {
      List<String> narociloItems = [];

      for (var item in chosenItems) {
        String artikelSifra = item.product.id;
        double kolicina = item.quantity;
        double originalPrice = item.product.price;
        num popust = item.discount;
        String opis = item.description;
        String artikelSkupina = item.product.categoryID;

        String narociloItem =
            '$userId\t$tableNumber\t$artikelSifra\t$kolicina\t$originalPrice\t$popust\t$opis\t$artikelSkupina';

        narociloItems.add(narociloItem);
      }

      List<String> posljiNaStreznik =
          await sendRequest(userId, narociloItems.join('\r\n'));

      if (tiskajNarocilo == true) {
        await Narocilo.createNarocilo(ref, true, context, tableNumber);
      }
      ref.read(narociloNotifierProvider.notifier).clearChosenItems();
      var narociloBox = Hive.box('narociloBox');
      await narociloBox.clear();

      clearSelectedItem(ref);
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
    return Scaffold(
      backgroundColor: AppStyles.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: GestureDetector(
          onTap: checkConnection,
          child: AppBar(
            backgroundColor: AppStyles.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppStyles.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text("Nova miza",
                style: AppStyles.heading3.copyWith(color: AppStyles.black)),
            centerTitle: true,
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
          ),
        ),
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
                  autofocus: true,
                  controller: _newTableController,
                  cursorColor: AppStyles.blue,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppStyles.silver.withAlpha((0.1 * 255).round()),
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
              child: OKButton(
                onPressed: () {
                  _addToNewTable(_newTableController.text);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BlagajnaScreen()));
                  HapticFeedback.vibrate();
                },
                text: 'OK',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
