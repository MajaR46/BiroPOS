import 'dart:async';
import 'package:biro_pos/controllers/print.dart';
import 'package:biro_pos/providers/selecteditem_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biro_pos/components/numpad.dart';
import 'package:biro_pos/models/narociloitem.dart';
import 'package:biro_pos/providers/direct_payment_provider.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/providers/settings_provider.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:sunmi_printer_plus/sunmi_style.dart';
import 'dart:typed_data'; // Uvozite Uint8List izdart:typed_data

class Keyboard extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final VoidCallback navigateToMizaScreen;
  final VoidCallback navigateToNacinPlacilaScreen;
  final VoidCallback navigateToOpisDiscountScreen;
  final VoidCallback navigateToRacun;
  final String opisDiscountButton;

  const Keyboard({
    super.key,
    required this.controller,
    required this.navigateToMizaScreen,
    required this.navigateToNacinPlacilaScreen,
    required this.navigateToOpisDiscountScreen,
    required this.navigateToRacun,
    required this.opisDiscountButton,
  });

  @override
  ConsumerState<Keyboard> createState() => _KeyboardState();
}

class _KeyboardState extends ConsumerState<Keyboard> {
  double itemQuantity = 1;
  double finalSum = 0;
  List<NarociloItem> chosenItems = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _updateFinalSum() {
    final newSum = ref.watch(narociloNotifierProvider.notifier).totalSum();
    setState(() {
      finalSum = newSum;
    });
  }

  void _handleMultiply(double factor) {
    final cartItems = ref.watch(narociloNotifierProvider);

    final selectedItem = cartItems.isNotEmpty ? cartItems.last : null;
    if (selectedItem != null) {
      double baseQuantity = 1;
      final newQuantity = baseQuantity * factor;

      setState(() {
        itemQuantity = newQuantity;
      });

      ref
          .read(narociloNotifierProvider.notifier)
          .updateQuantity(selectedItem.product.id, newQuantity);

      _updateFinalSum();
    }
  }

  void _decreaseQuantity() {
    final selectedItem = ref.watch(selectedItemProvider);

    if (itemQuantity > 1) {
      setState(() {
        itemQuantity--;
      });
      if (selectedItem != null) {
        ref
            .read(narociloNotifierProvider.notifier)
            .updateQuantity(selectedItem.product.id, itemQuantity);
        _updateFinalSum();
      }
    }
  }

  Future<void> _processPayment(BuildContext context, String paymentType) async {
    final paymentMethods = ref.watch(paymentMethodProvider);
    if (paymentMethods.isNotEmpty) {
      final response =
          await ref.read(orderProvider).createOrder(context, paymentType);
      final filteredResponse = filterEmptyLines(response);
      final printableResponse = filteredResponse.join("\r\n");
      printTextWithFormatting(printableResponse, "BlueTooth Printer", ref);
      _updateFinalSum();
      // _showResponseDialog(context, response);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No payment methods available!")));
    }
  }

/*   void _showResponseDialog(BuildContext context, List<String> response) {
    final filteredResponse = filterEmptyLines(response);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Server Response"),
          content: SingleChildScrollView(
            child: ListBody(
              children: filteredResponse.map((line) => Text(line)).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(narociloNotifierProvider.notifier).clearChosenItems();
              },
            ),
          ],
        );
      },
    );
  } */

  void _paymentGotovina() {
    _processPayment(context, "GOT");
  }

  void _paymentKartica() {
    _processPayment(context, "KAR");
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final prikazujSamoNarocila = settings['isCheckedPrikazujNarocila'] ?? false;

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
                      KeyboardC(controller: widget.controller),
                      KeyboardMultiply(
                        multiply: _handleMultiply,
                        quantity: itemQuantity,
                        controller: widget.controller,
                      ),
                      KeyboardNumber(number: ',', controller: widget.controller)
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      KeyboardNumber(
                          number: "1", controller: widget.controller),
                      KeyboardNumber(
                          number: "2 ABC", controller: widget.controller),
                      KeyboardNumber(
                          number: "3 DEF", controller: widget.controller),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      KeyboardNumber(
                          number: "4 GHI", controller: widget.controller),
                      KeyboardNumber(
                          number: "5 JKL", controller: widget.controller),
                      KeyboardNumber(
                          number: "6 MNO", controller: widget.controller),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      KeyboardNumber(
                          number: "7 PQRS", controller: widget.controller),
                      KeyboardNumber(
                          number: "8 TUV", controller: widget.controller),
                      KeyboardNumber(
                          number: "9 WXYZ", controller: widget.controller),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      NumpadDelete(
                        height: 50,
                        controller: widget.controller,
                        fontSize: 16,
                        borderRadius: 20,
                      ),
                      KeyboardNumber(
                        number: "0",
                        controller: widget.controller,
                      ),
                      KeyboardRedirect(
                        backgroundColor: AppStyles.blue,
                        text: widget.opisDiscountButton,
                        onPressed: widget.navigateToOpisDiscountScreen,
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
                    onPressed: widget.navigateToRacun),
              ),
              if (!prikazujSamoNarocila)
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: KeyboardRedirect(
                      backgroundColor: AppStyles.darkOrange,
                      text: "GOT",
                      onPressed: _paymentGotovina),
                ),
              if (!prikazujSamoNarocila)
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: KeyboardRedirect(
                      backgroundColor: AppStyles.red,
                      text: "KAR",
                      onPressed: _paymentKartica),
                ),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: KeyboardRedirect(
                    backgroundColor: AppStyles.darkPurple,
                    text: "MIZA",
                    onPressed: widget.navigateToMizaScreen),
              ),
              if (!prikazujSamoNarocila)
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: KeyboardRedirect(
                    backgroundColor: AppStyles.darkGreen,
                    text: "OK",
                    onPressed: () {
                      widget
                          .navigateToNacinPlacilaScreen(); // Navigate to the payment method screen
                    },
                  ),
                ),
            ],
          )
        ],
      ),
    );
  }
}

class KeyboardNumber extends StatelessWidget {
  final String number;
  final TextEditingController controller;

  const KeyboardNumber(
      {super.key, required this.number, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: AppStyles.silver.withOpacity(0.1),
            padding: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))),
        onPressed: () {
          controller.text += number;
        },
        child: Center(
          child: Text(
            number,
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
      height: 50,
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
      height: 50,
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
      height: 50,
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
