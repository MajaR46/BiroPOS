import 'package:biro_pos/components/ok_button.dart';
import 'package:biro_pos/screens/api_key_screen.dart';
import 'package:biro_pos/screens/racun_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter/widgets.dart';

class EditItemScreen extends StatefulWidget {
  final String itemName;
  final double itemDiscountedPrice;

  const EditItemScreen(
      {super.key, required this.itemName, required this.itemDiscountedPrice});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final TextEditingController _opisController = TextEditingController();
  final List<String> itemOpis = [];

  void _updateTextField(String text) {
    setState(() {
      itemOpis.add(text);
      _opisController.text = itemOpis.join(' ');
    });
  }

  void _clearText() {
    _opisController.clear();
    itemOpis.clear();
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
        title: Text("Opis",
            style: AppStyles.heading3.copyWith(color: AppStyles.black)),
        centerTitle: true,
      ),
      body: Stack(
        // Ensure the body is a Stack
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 32, left: 16, right: 16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: AppStyles.silver.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Text(widget.itemName, style: AppStyles.heading3),
                        Spacer(),
                        Text(
                          widget.itemDiscountedPrice.toStringAsFixed(2) + ' €',
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
                  padding: const EdgeInsets.only(top: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 50,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppStyles.blue,
                            ),
                            onPressed: () {
                              _updateTextField("Z");
                            },
                            child: Text(
                              "Z",
                              style: AppStyles.button1
                                  .copyWith(color: AppStyles.white),
                            )),
                      ),
                      SizedBox(
                        height: 50,
                        width: 120,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppStyles.blue,
                            ),
                            onPressed: () {
                              _updateTextField("Brez");
                            },
                            child: Text("Brez",
                                style: AppStyles.button1
                                    .copyWith(color: AppStyles.white))),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: Wrap(
                    spacing: 30,
                    runSpacing: 30,
                    children: <Widget>[
                      SizedBox(
                        width: 120,
                        height: 50,
                        child: ElevatedButton(
                            onPressed: () {
                              _updateTextField("Sladkor");
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppStyles.silver.withOpacity(0.1),
                                elevation: 0),
                            child: Text(
                              "Sladkor",
                              style: AppStyles.button1
                                  .copyWith(color: AppStyles.black),
                            )),
                      ),
                      SizedBox(
                        width: 120,
                        height: 50,
                        child: ElevatedButton(
                            onPressed: () {
                              _updateTextField("Mleko");
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppStyles.silver.withOpacity(0.1),
                                elevation: 0),
                            child: Text(
                              "Mleko",
                              style: AppStyles.button1
                                  .copyWith(color: AppStyles.black),
                            )),
                      ),
                      SizedBox(
                        width: 120,
                        height: 50,
                        child: ElevatedButton(
                            onPressed: () {
                              _updateTextField("Smetana");
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppStyles.silver.withOpacity(0.1),
                                elevation: 0),
                            child: Text(
                              "Smetana",
                              style: AppStyles.button1
                                  .copyWith(color: AppStyles.black),
                            )),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          OKButton(onPressed: () {
            final result = {'opis': itemOpis.join(' ')};
            Navigator.of(context).pop(result);
          }),
        ],
      ),
    );
  }
}
