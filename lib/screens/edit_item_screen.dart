import 'package:BiroPOS/components/ok_button.dart';
import 'package:BiroPOS/models/dodatek.dart';
import 'package:BiroPOS/models/item.dart';
import 'package:BiroPOS/models/narociloitem.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditItemScreen extends ConsumerStatefulWidget {
  final String narociloItemUniqueId;

  final String itemName;
  final String itemCategory;
  final double itemPrice;
  const EditItemScreen(
      {super.key,
      required this.narociloItemUniqueId,
      required this.itemName,
      required this.itemCategory,
      required this.itemPrice});

  @override
  ConsumerState<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  final TextEditingController _opisController = TextEditingController();
  List<String> itemOpis = [];
  List<Dodatek> dodatki = [];
  List<Dodatek> filteredDodatki = [];
  NarociloItem? _currentItem; // Za shranjevanje trenutne postavke

  void initState() {
    super.initState();
    _loadItemData(); // Naloži podatke o postavki
    _handleData(); // Naloži dodatke
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    });
  }

  void _loadItemData() {
    // Najdi postavko v providerju na podlagi uniqueId
    final narociloItems = ref.read(narociloNotifierProvider);
    try {
      final currentItem = narociloItems.firstWhere(
        (item) => item.uniqueId == widget.narociloItemUniqueId,
      );
      setState(() {
        _currentItem = currentItem;
        _opisController.text =
            currentItem.description; // Nastavi obstoječi opis
        // Filtriraj dodatke glede na kategorijo najdene postavke
        if (_currentItem != null && _currentItem!.product.categoryID != null) {
          _filterDodatki(_currentItem!.product.categoryID!);
        }
      });
    } catch (e) {
      // Če postavka ni najdena (napaka ali je bila medtem odstranjena)
      print(
          "Error finding item with uniqueId ${widget.narociloItemUniqueId}: $e");
      // Morda zapri zaslon ali prikaži napako
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  // Funkcija za posodobitev text fielda ostane podobna
  void _updateTextField(String text) {
    // Namesto dodajanja v seznam, direktno manipuliraj z _opisController.text
    final currentText = _opisController.text;
    final selection = _opisController.selection;
    final newText =
        currentText.isEmpty ? text : '$currentText $text'; // Dodaj presledek

    setState(() {
      _opisController.text = newText;
      // Premakni kurzor na konec
      _opisController.selection = TextSelection.fromPosition(
        TextPosition(offset: _opisController.text.length),
      );
    });
  }

  // _handleData, _categorizeResponseItems ostanejo enaki
  Future<void> _handleData() async {
    try {
      final box = Hive.box('biroposData');
      List<String> apiResponseList =
          List<String>.from(box.get('biroPosData', defaultValue: []));
      _categorizeResponseItems(apiResponseList);

      // Ponovno filtriraj dodatke, če item kategorija še ni bila znana ob prvem klicu
      if (_currentItem != null &&
          _currentItem!.product.categoryID != null &&
          filteredDodatki.isEmpty) {
        _filterDodatki(_currentItem!.product.categoryID!);
      }
    } catch (e) {
      print("error loading data $e");
    }
  }

  void _categorizeResponseItems(List<String> items) {
    List<Dodatek> dodatki2 = [];
    for (String item in items) {
      // ... logika ostane enaka ...
      if (item.startsWith('D')) {
        List<String> parts = item.split('|');
        if (parts.length >= 3) {
          // Preveri dolžino
          String imeDodatka = parts[1];
          List<String> pripadajoceKategorije = parts[2].split(',');
          dodatki2.add(Dodatek(
            ime: imeDodatka,
            pripadajoceKategorije: pripadajoceKategorije,
          ));
        }
      }
    }
    // Ne kličemo setState tukaj, ker morda še nimamo kategorije izdelka
    dodatki = dodatki2;
    // Filtriranje se zgodi v _loadItemData ali _handleData, ko imamo kategorijo
  }

  void _filterDodatki(String categoryId) {
    setState(() {
      filteredDodatki = dodatki
          .where(
              (dodatek) => dodatek.pripadajoceKategorije.contains(categoryId))
          .toList();
    });
  }

  void _clearText() {
    _opisController.clear();
    itemOpis.clear();
  }

  @override
  Widget build(BuildContext context) {
    final narociloItems = ref.watch(narociloNotifierProvider);
    final narociloNotifier = ref.read(narociloNotifierProvider.notifier);

    final currentItem = narociloItems.firstWhere(
      (item) =>
          item.product.name == widget.itemName &&
          item.product.categoryID == widget.itemCategory &&
          item.product.price == widget.itemPrice,
      orElse: () => NarociloItem(
        product: Item(name: '', price: 0.0),
      ),
    );

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Dismiss keyboard
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
            overlays: []); // Reinforce UI mode
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppStyles.white,
        appBar: AppBar(
          backgroundColor: AppStyles.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppStyles.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text("Opis",
              style: AppStyles.heading3.copyWith(color: AppStyles.black)),
          centerTitle: true,
        ),
        body: narociloItems.isEmpty
            ? const Center(child: Text('Ni izdelka za dodajanje opisa.'))
            : SingleChildScrollView(
                // Add SingleChildScrollView here
                child: Padding(
                  padding: const EdgeInsets.only(top: 32, left: 16, right: 16),
                  child: Column(
                    children: [
                      if (narociloItems.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: AppStyles.silver.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  currentItem.product.name,
                                  style: AppStyles.heading4,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: SizedBox(
                          width: 250,
                          child: TextField(
                            autofocus: true,
                            controller: _opisController,
                            cursorHeight: 20,
                            cursorColor: AppStyles.blue,
                            textAlignVertical: TextAlignVertical.bottom,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 5.0, horizontal: 10.0),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppStyles.blue, width: 1),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppStyles.blue, width: 2),
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
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 32, left: 16, right: 16),
                        child: GridView.builder(
                          shrinkWrap:
                              true, // Add this to avoid taking up extra space
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent:
                                200, // Nastavite največjo širino gumba
                            childAspectRatio: 2.5, // Ohranite ustrezno razmerje
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredDodatki.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                _updateTextField(filteredDodatki[index].ime);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppStyles.blue, // Background color
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Center(
                                  child: Text(
                                    filteredDodatki[index].ime,
                                    style: AppStyles.button1
                                        .copyWith(color: AppStyles.white),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 32),
          child: Align(
            alignment: Alignment.bottomRight,
            child: OKButton(
              onPressed: () {
                final resultOpis = _opisController.text.trim();

                narociloNotifier.updateOpis(
                  widget.narociloItemUniqueId, // <-- Pošlji uniqueId
                  resultOpis,
                );
                SystemChrome.setEnabledSystemUIMode(
                    SystemUiMode.immersiveSticky);
                Navigator.of(context).pop();
              },
              text: 'OK',
            ),
          ),
        ),
      ),
    );
  }
}
