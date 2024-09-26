import 'package:biro_pos/app_styles.dart';
import 'package:biro_pos/components/ok_button.dart';
import 'package:flutter/material.dart';

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final TextEditingController _controllerApiKey = TextEditingController();
  final TextEditingController _controllerTouchKey = TextEditingController();
  final TextEditingController _controllerTextSize = TextEditingController();
  final TextEditingController _controllerRefresh = TextEditingController();
  bool _isCheckedMoney = false;
  bool _isCheckedOrders = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppStyles.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Nastavitve",
            style: AppStyles.heading3.copyWith(color: AppStyles.black)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Api ključ:', style: AppStyles.paragraph1),
                    const SizedBox(width: 16),
                    ApiKeyTextfield(
                      controller: _controllerApiKey,
                      inputwidth: 230,
                      isHidden: true,
                    )
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("Vprašaj za ceno, če je 0,0:",
                        style: AppStyles.paragraph1),
                    const SizedBox(width: 16),
                    ApiKeyCheckbox(
                      value: _isCheckedMoney,
                      onChanged: (bool? value) {
                        setState(() {
                          _isCheckedMoney = value ?? false;
                        });
                      },
                    )
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Velikost pisave touch tipke:",
                        style: AppStyles.paragraph1),
                    const SizedBox(width: 16),
                    ApiKeyTextfield(
                      controller: _controllerTouchKey,
                      inputwidth: 90,
                      isHidden: false,
                    )
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("Pregled naročil:", style: AppStyles.paragraph1),
                    const SizedBox(width: 16),
                    ApiKeyCheckbox(
                      value: _isCheckedOrders,
                      onChanged: (bool? value) {
                        setState(() {
                          _isCheckedOrders = value ?? false;
                        });
                      },
                    )
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: Container()),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 64.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    fontSize: 16, color: AppStyles.blue)),
                            const SizedBox(width: 8),
                            const Text("Velikost pisave:",
                                style: AppStyles.paragraph1),
                            const SizedBox(width: 16),
                            ApiKeyTextfield(
                              controller: _controllerTextSize,
                              inputwidth: 90,
                              isHidden: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: Container()),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 24.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    fontSize: 16, color: AppStyles.blue)),
                            const SizedBox(width: 8),
                            const Text("Osveži na (št. minut):",
                                style: AppStyles.paragraph1),
                            const SizedBox(width: 16),
                            ApiKeyTextfield(
                              controller: _controllerRefresh,
                              inputwidth: 90,
                              isHidden: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 32),
            child: Align(
              alignment: Alignment.bottomRight,
              child: OKButton(
                onPressed: () {},
              ),
            ),
          )
        ],
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
        obscureText: isHidden,
        controller: controller,
        cursorHeight: 20,
        cursorColor: AppStyles.blue,
        textAlignVertical: TextAlignVertical.bottom,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppStyles.blue, width: 1),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppStyles.blue, width: 2),
          ),
        ),
      ),
    );
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
          onChanged: onChanged,
          activeColor: AppStyles.blue,
        ),
      ],
    );
  }
}
