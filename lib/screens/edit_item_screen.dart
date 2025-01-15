import 'package:biro_pos/components/ok_button.dart';
import 'package:biro_pos/models/dodatek.dart';
import 'package:biro_pos/models/item.dart';
import 'package:biro_pos/models/narociloitem.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define your screen as ConsumerStatefulWidget to access Riverpod providers
class EditItemScreen extends ConsumerStatefulWidget {
  final String itemName;
  final String itemCategory;
  const EditItemScreen(
      {super.key, required this.itemName, required this.itemCategory});

  @override
  ConsumerState<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  final TextEditingController _opisController = TextEditingController();
  List<String> itemOpis = [];
  List<Dodatek> dodatki = [];
  List<Dodatek> filteredDodatki = [];

  @override
  void initState() {
    super.initState();
    _handleData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final narociloItems = ref.read(narociloNotifierProvider);
      final currentItem = narociloItems.firstWhere(
        (item) => item.product.name == widget.itemName,
        orElse: () => NarociloItem(
          product: Item(name: '', price: 0.0),
          description: '',
        ),
      );

      if (currentItem != null && currentItem.description != null) {
        setState(() {
          _opisController.text = currentItem.description;
        });
      }
    });
  }

  void _updateTextField(String text) {
    setState(() {
      print(itemOpis);
      itemOpis.add(text);
      _opisController.text = itemOpis.join(' ');
    });
  }

  Future<void> _handleData() async {
    try {
      final box = Hive.box('biroposData');
      List<String> apiResponseList =
          List<String>.from(box.get('biroPosData', defaultValue: []));
      _categorizeResponseItems(apiResponseList);

      if (apiResponseList == null) {
        print("No data");
        return;
      }
    } catch (e) {
      print("error loading data $e");
    }
  }

  void _categorizeResponseItems(List<String> items) {
    List<Dodatek> dodatki2 = [];

    for (String item in items) {
      if (item.startsWith('D')) {
        String imeDodatka = item.split('|')[1];
        String pripadajocaKateogrija = item.split('|')[2];
        dodatki2.add(Dodatek(
            ime: imeDodatka, pripadajocaKategorija: pripadajocaKateogrija));
      }
    }

    setState(() {
      dodatki = dodatki2;
      _filterDodatki(widget.itemCategory);
    });
  }

  void _filterDodatki(String categoryId) {
    setState(() {
      filteredDodatki = dodatki
          .where((dodatek) => dodatek.pripadajocaKategorija == categoryId)
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
          item.product.categoryID == widget.itemCategory,
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
                        child: SizedBox(
                          height: 500,
                          child: GridView.builder(
                            shrinkWrap:
                                true, // Add this to avoid taking up extra space
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 3,
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

                narociloNotifier.updateOpis(currentItem.product.id, resultOpis);
                SystemChrome.setEnabledSystemUIMode(
                    SystemUiMode.immersiveSticky);
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    );
  }
}
