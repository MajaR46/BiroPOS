import 'dart:async';

import 'package:biro_pos/components/numpad.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

class Keyboard extends StatelessWidget {
  final TextEditingController controller;
  final double quantity;
  final Function(double result) multiply;
  final VoidCallback navigateToRacun;
  final VoidCallback navigateToMizaScreen;
  final VoidCallback navigateToNacinPlacilaScreen;
  final VoidCallback navigateToOpisScreen;
  final VoidCallback paymentGotovina;
  final VoidCallback paymentKartica;

  final dynamic selectedItem;
  final double finalSum;
  final List<dynamic> chosenItems;

  const Keyboard(
      {super.key,
      required this.controller,
      required this.multiply,
      required this.quantity,
      required this.selectedItem,
      required this.finalSum,
      required this.chosenItems,
      required this.navigateToRacun,
      required this.navigateToMizaScreen,
      required this.navigateToNacinPlacilaScreen,
      required this.navigateToOpisScreen,
      required this.paymentGotovina,
      required this.paymentKartica});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      color: AppStyles.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      KeyboardC(controller: controller),
                      KeyboardMultiply(
                          multiply: multiply,
                          quantity: quantity,
                          controller: controller),
                      KeyboardNumber(number: ',', controller: controller)
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      KeyboardNumber(number: "1 .", controller: controller),
                      KeyboardNumber(number: "2 ABC", controller: controller),
                      KeyboardNumber(number: "3 DEF", controller: controller),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      KeyboardNumber(number: "4 GHI", controller: controller),
                      KeyboardNumber(number: "5 JKL", controller: controller),
                      KeyboardNumber(number: "6 MNO", controller: controller),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      KeyboardNumber(number: "7 PQRS", controller: controller),
                      KeyboardNumber(number: "8 TUV", controller: controller),
                      KeyboardNumber(number: "9 WXYZ", controller: controller),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      NumpadDelete(
                        controller: controller,
                        fontSize: 16,
                        borderRadius: 20,
                      ),
                      KeyboardNumber(
                        number: "0",
                        controller: controller,
                      ),
                      KeyboardRedirect(
                        backgroundColor: AppStyles.blue,
                        text: "OPIS ",
                        onPressed: navigateToOpisScreen,
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: KeyboardRedirect(
                    backgroundColor: AppStyles.blue,
                    text: "RAČUN",
                    onPressed: navigateToRacun),
              ),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: KeyboardRedirect(
                    backgroundColor: AppStyles.darkOrange,
                    text: "GOT",
                    onPressed: paymentGotovina),
              ),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: KeyboardRedirect(
                    backgroundColor: AppStyles.red,
                    text: "KAR",
                    onPressed: paymentKartica),
              ),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: KeyboardRedirect(
                    backgroundColor: AppStyles.darkPurple,
                    text: "MIZA",
                    onPressed: navigateToMizaScreen),
              ),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: KeyboardRedirect(
                    backgroundColor: AppStyles.darkGreen,
                    text: "OK",
                    onPressed: navigateToNacinPlacilaScreen),
              )
            ],
          )
        ],
      ),
    );
  }
}

class KeyboardNumber extends StatefulWidget {
  final String number;
  final TextEditingController controller;

  const KeyboardNumber(
      {super.key, required this.number, required this.controller});

  @override
  State<KeyboardNumber> createState() => _KeyboardNumberState();
}

class _KeyboardNumberState extends State<KeyboardNumber> {
  int tapCount = 0;
  Timer? tapTimer;
  bool preventSearch = false; // Flag to prevent search during comma entry

  void _handleTap() {
    setState(() {
      tapCount++;

      String numberWithoutSpace = widget.number.replaceAll(' ', '');
      int availableCharacters = numberWithoutSpace.length;

      if (tapCount <= availableCharacters) {
        String selectedChar = numberWithoutSpace[tapCount - 1];

        // Special handling for the comma to act as a decimal point
        if (selectedChar == ',' && !widget.controller.text.contains(',')) {
          selectedChar = '.'; // Replace the comma with a dot (decimal point)

          // Temporarily disable search logic
          preventSearch = true;
        }

        // Append the selected character to the controller text
        widget.controller.text = widget.controller.text + selectedChar;

        // Optionally, move cursor to the end (if needed)
        widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller.text.length));
      }

      // Reset the tap counter after a small delay to allow multiple taps
      tapTimer?.cancel();
      tapTimer = Timer(const Duration(seconds: 1), () {
        tapCount = 0;
      });
    });
  }

  @override
  void dispose() {
    tapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: AppStyles.silver.withOpacity(0.1),
            padding: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))),
        onPressed: () {
          _handleTap();
        },
        child: Center(
          child: Text(
            widget.number,
            style: AppStyles.boldanparagraph1.copyWith(color: AppStyles.black),
          ),
        ),
      ),
    );
  }
}

class KeyboardC extends StatelessWidget {
  final TextEditingController controller;

  const KeyboardC({super.key, required this.controller});

  void _clearText() {
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 60,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.silver.withOpacity(0.1),
              padding: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15))),
          onPressed: _clearText,
          child: Center(
            child: Text(
              "C",
              style:
                  AppStyles.boldanparagraph1.copyWith(color: AppStyles.black),
            ),
          )),
    );
  }
}

class KeyboardMultiply extends StatelessWidget {
  final TextEditingController controller;
  final double quantity;
  final Function(double result) multiply;

  const KeyboardMultiply({
    super.key,
    required this.multiply,
    required this.quantity,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppStyles.silver.withOpacity(0.1),
          padding: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () {
          double? number = double.tryParse(controller.text);
          if (number != null) {
            multiply(number);
          }
        },
        child: Center(
          child: Text(
            "*",
            style: AppStyles.boldanparagraph1.copyWith(color: AppStyles.black),
          ),
        ),
      ),
    );
  }
}

class KeyboardRedirect extends StatelessWidget {
  final Color backgroundColor;
  final String text;
  final VoidCallback onPressed;

  const KeyboardRedirect(
      {super.key,
      required this.backgroundColor,
      required this.text,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 60,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              padding: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15))),
          onPressed: onPressed,
          child: Center(
            child: Text(
              text,
              style:
                  AppStyles.boldanparagraph1.copyWith(color: AppStyles.white),
            ),
          )),
    );
  }
}
