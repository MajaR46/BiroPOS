import 'package:biro_pos/components/ok_button.dart';
import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/models/item.dart';
import 'package:biro_pos/models/narociloitem.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/screens/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define your screen as ConsumerStatefulWidget to access Riverpod providers
class EditItemScreen extends ConsumerStatefulWidget {
  final String itemName;
  const EditItemScreen({super.key, required this.itemName});

  @override
  ConsumerState<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  final TextEditingController _opisController = TextEditingController();
  List<String> itemOpis = [];
  List<Dodatek> dodatki = [];

  @override
  void initState() {
    super.initState();
    _handleData();
  }

  void _updateTextField(String text) {
    setState(() {
      itemOpis.add(text);
      _opisController.text = itemOpis.join(' ');
    });
  }

  Future<void> _handleData() async {
    List<String> apiResponseList = await sendRequest("1", "BiroPOS.txt");
    _categorizeResponseItems(apiResponseList);
  }

  void _categorizeResponseItems(List<String> items) {
    List<Dodatek> dodatki2 = [];

    for (String item in items) {
      if (item.startsWith('D')) {
        String imeDodatka = item.split('|')[1];
        dodatki2.add(Dodatek(imeDodatka));
      }
    }

    setState(() {
      dodatki = dodatki2;
    });
  }

  void _clearText() {
    _opisController.clear();
    itemOpis.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Access the list of NarociloItems from the NarociloNotifier provider
    final narociloItems = ref.watch(narociloNotifierProvider);
    final narociloNotifier =
        ref.read(narociloNotifierProvider.notifier); // To modify state

    if (narociloItems.isEmpty) {
      return const Center(child: Text('No item found to edit.'));
    }

    final currentItem = narociloItems.firstWhere(
      (item) => item.product.name == widget.itemName,
      orElse: () => NarociloItem(
        product:
            Item(name: '', price: 0.0), // A default NarociloItem if not found
      ),
    );

    if (currentItem == null) {
      return const Center(child: Text('Item not found.'));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppStyles.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Opis",
            style: AppStyles.heading3.copyWith(color: AppStyles.black)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 32, left: 16, right: 16),
            child: Column(
              children: [
                // Example: Displaying and updating the first NarociloItem
                if (narociloItems.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                        color: AppStyles.silver.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Text(currentItem.product.name,
                              style: AppStyles.heading3),
                          const Spacer(),
                          Text(
                            '${currentItem.product.price.toStringAsFixed(2)} €',
                            style: AppStyles.heading3
                                .copyWith(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
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
                  padding: const EdgeInsets.only(top: 32, left: 16, right: 16),
                  child: SizedBox(
                    height: 500,
                    child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 3,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16),
                        itemCount: dodatki.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                              onTap: () {
                                _updateTextField(dodatki[index].ime);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppStyles.blue, // Background color
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Center(
                                  child: Text(
                                    dodatki[index].ime,
                                    style: AppStyles.button1
                                        .copyWith(color: AppStyles.white),
                                  ),
                                ),
                              ));
                        }),
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 32),
            child: Align(
              alignment: Alignment.bottomRight,
              child: OKButton(onPressed: () {
                final resultOpis = _opisController.text.trim();

                // Update the opis for the selected NarociloItem
                narociloNotifier.updateOpis(currentItem.product.id, resultOpis);
                Navigator.of(context).pop();
              }),
            ),
          ),
        ],
      ),
    );
  }
}
