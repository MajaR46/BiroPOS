import 'package:BiroPOS/components/debouncer.dart';
import 'package:BiroPOS/components/narocilo.dart';
import 'package:BiroPOS/components/vracilo_denarja.dart';
import 'package:BiroPOS/controllers/process_payment.dart';
import 'package:BiroPOS/providers/direct_payment_provider.dart';
import 'package:BiroPOS/providers/searchquery_provider.dart';
import 'package:BiroPOS/providers/selecteditem_provider.dart';
import 'package:BiroPOS/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:BiroPOS/models/narociloitem.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:BiroPOS/app_styles.dart';

class Keyboard extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final VoidCallback navigateToMizaScreen;
  final VoidCallback navigateToNacinPlacilaScreen;
  final VoidCallback navigateToOpisDiscountScreen;
  final VoidCallback navigateToRacun;
  final String opisDiscountButton;
  final String racunArtikliButton;
  final IconData icon;
  final VoidCallback search;

  const Keyboard(
      {super.key,
      required this.controller,
      required this.navigateToMizaScreen,
      required this.navigateToNacinPlacilaScreen,
      required this.navigateToOpisDiscountScreen,
      required this.navigateToRacun,
      required this.opisDiscountButton,
      required this.racunArtikliButton,
      required this.search,
      required this.icon});

  @override
  ConsumerState<Keyboard> createState() => _KeyboardState();
}

class _KeyboardState extends ConsumerState<Keyboard> {
  double itemQuantity = 1;
  double finalSum = 0;
  List<NarociloItem> chosenItems = [];
  final TextEditingController searchController = TextEditingController();
  late ProcessPayment paymentService;
  final Debouncer _debouncer = Debouncer(miliseconds: 2000);

  @override
  void initState() {
    super.initState();
    paymentService = ProcessPayment(ref);
  }

  void _updateFinalSum() {
    final newSum = ref.watch(narociloNotifierProvider.notifier).totalSum();
    setState(() {
      finalSum = newSum;
    });
  }

  void _decreaseQuantity() {
    final selectedItem = ref.watch(selectedItemProvider);

    if (itemQuantity > 1) {
      setState(() {
        itemQuantity--;
      });
      if (selectedItem != null) {
        ref.read(narociloNotifierProvider.notifier).updateQuantity(
            selectedItem.product.id,
            selectedItem.description,
            itemQuantity,
            selectedItem.product.price,
            itemQuantity);
        _updateFinalSum();
      }
    }
  }

  /*  Future<void> _processPayment(BuildContext context, String paymentType) async {
    double finalSum = ref.watch(narociloNotifierProvider.notifier).totalSum();
    final settings = ref.watch(settingsProvider);
    final bluetoothPrintanje = settings['isCheckedBluetoothPrintanje'] ?? false;

    final paymentMethods = ref.watch(paymentMethodProvider);
    if (paymentMethods.isNotEmpty) {
      final response =
          await ref.read(orderProvider).createOrder(context, paymentType);

      if (bluetoothPrintanje == true) {
        await BluetoothService.sendData(response, ref, context);
        _updateFinalSum();
      } else {
        final filteredResponse = filterEmptyLines(response);
        final printableResponse = filteredResponse.join("\r\n");
        if (paymentType == "KAR") {
          final gotovinaRacun = await callBesteron(finalSum);
          await printTextWithFormatting(
              gotovinaRacun, "BlueTooth Printer", ref);
        }
        await printTextWithFormatting(
            printableResponse, "BlueTooth Printer", ref);

        _updateFinalSum();
      }

      // _showResponseDialog(context, response);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No payment methods available!")));
    }
  }
 */
  void _paymentGotovina() {
    _debouncer.debouce(() async {
      final settings = ref.watch(settingsProvider);
      final tiskajNarociloPriRacunu =
          settings['isCheckedTiskajNarociloPriRacunu'] ?? false;
      print("tiskaj : $tiskajNarociloPriRacunu");
      double finalSum = ref.read(narociloNotifierProvider.notifier).totalSum();

      try {
        String searchQuery = ref.watch(searchQueryProvider);
        String filtriranQuery = searchQuery.replaceAll(RegExp(r'[^0-9.]'), '');

        final vnesenZnesek = double.tryParse(filtriranQuery);
        print("vnesen znesek $vnesenZnesek");
        print(ref.watch(searchQueryProvider));

        // Calculate the change
        double vracilo = Vracilo.izracunVracila(ref, vnesenZnesek ?? 0.0);

        if (vnesenZnesek != null && vnesenZnesek > 0.0) {
          await Vracilo.showReturnDialog(
              context, vnesenZnesek ?? 0.0, finalSum, vracilo);
        }

        // Process the payment
        paymentService.processPayment(context, "GOT");

        if (tiskajNarociloPriRacunu) {
          await Narocilo.createNarocilo(ref, false, context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Težava z bluetooth!")));
      }
    });
  }

  void _paymentKartica() {
    _debouncer.debouce(() async {
      final settings = ref.watch(settingsProvider);
      final tiskajNarociloPriRacunu =
          settings['isCheckedTiskajNarociloPriRacunu'] ?? false;
      try {
        paymentService.processPayment(context, "KAR");
        if (tiskajNarociloPriRacunu == true) {
          await Narocilo.createNarocilo(ref, false, context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Težava z bluetooth!")));
      }
    });
  }

  void _handleMultiply(double factor) {
    // Fetch the selected item from the provider
    final selectedItem = ref.read(selectedItemProvider.notifier).state;
    if (selectedItem != null) {
      // Get the current quantity of the selected item
      double currentQuantity = selectedItem.quantity;

      // Multiply the current quantity by the factor
      double newQuantity = currentQuantity * factor;

      // Update the quantity in the provider
      ref.read(narociloNotifierProvider.notifier).updateQuantity(
          selectedItem.product.id,
          selectedItem.description,
          factor,
          selectedItem.product.price,
          selectedItem.quantity);

      print("tuki problem");

      ref.read(selectedItemProvider.notifier).state =
          selectedItem.copyWith(quantity: factor);

      // Update the local state
      setState(() {
        itemQuantity = factor;
      });

      // Update the final sum

      _updateFinalSum();
    } else {
      // Handle the case where no item is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izberi izdelek')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final prikazujSamoNarocila = settings['isCheckedPrikazujNarocila'] ?? false;
    final prikazujSamoRacune = settings['isCheckedPrikazujRacune'] ?? false;
    final paymentMethods = ref.watch(paymentMethodProvider);
    bool obstajaKarPlacilo =
        paymentMethods.any((method) => method.kodaNacinaPlacila == "02");
    String mizaButton;

    final chosenItems = ref.watch(narociloNotifierProvider);

    if (chosenItems.isEmpty) {
      mizaButton = "MIZA";
    } else {
      mizaButton = "NA MIZO";
    }

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
                      KeyboardBack(
                        search: widget.search,
                        icon: widget.icon,
                        height: 50,
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
                    text: widget.racunArtikliButton,
                    onPressed: widget.navigateToRacun),
              ),
              if (!prikazujSamoNarocila)
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: KeyboardRedirect(
                      backgroundColor: AppStyles.brightOrange,
                      text: "GOT",
                      onPressed: _paymentGotovina),
                ),
              if (!prikazujSamoNarocila)
                Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: KeyboardRedirect(
                      backgroundColor: AppStyles.brightRed,
                      text: "KAR",
                      onPressed: obstajaKarPlacilo
                          ? _paymentKartica
                          : () {}, // Posredujemo prazno funkcijo namesto null
                    )),
              if (!prikazujSamoRacune)
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: KeyboardRedirect(
                      backgroundColor: AppStyles.brightPurple,
                      text: mizaButton,
                      onPressed: widget.navigateToMizaScreen),
                ),
              if (!prikazujSamoNarocila)
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: KeyboardRedirect(
                    backgroundColor: AppStyles.green,
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

class KeyboardNumber extends StatefulWidget {
  final String number;
  final TextEditingController controller;

  const KeyboardNumber(
      {super.key, required this.number, required this.controller});

  @override
  State<KeyboardNumber> createState() => _KeyboardNumberState();
}

class _KeyboardNumberState extends State<KeyboardNumber> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: AppStyles.lightGrey,
            padding: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))),
        onPressed: () {
          HapticFeedback.vibrate();

          // If the number is `,`, replace it with `.` (decimal point).
          String newText = widget.number == ',' ? '.' : widget.number;

          // Prevent adding more than one decimal point (.)
          if (newText == '.' && widget.controller.text.contains('.')) {
            return; // Do nothing if the decimal point already exists.
          }

          setState(() {
            widget.controller.text += newText;
          });
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
      height: 50,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.lightGrey,
              padding: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15))),
          onPressed: () {
            HapticFeedback.vibrate();
            _clearText();
          },
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
          backgroundColor: AppStyles.lightGrey,
          padding: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () {
          HapticFeedback.vibrate();

          String sanitizedText =
              controller.text.replaceAll(RegExp(r'[^\d.]'), '');
          double? number = double.tryParse(sanitizedText);
          if (number != null) {
            multiply(number);
            controller.clear();
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
          onPressed: () {
            HapticFeedback.vibrate();
            onPressed();
          },
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

class KeyboardBack extends ConsumerWidget {
  final int fontSize;
  final int borderRadius;
  final int height;
  final VoidCallback? search;
  final IconData icon;

  const KeyboardBack(
      {super.key,
      required this.fontSize,
      required this.borderRadius,
      required this.height,
      this.search,
      required this.icon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosenItems = ref.watch(narociloNotifierProvider);

    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return SizedBox(
      width: 80,
      height: height.toDouble(),
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.lightGrey,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(borderRadius.toDouble()))),
          onPressed: () {
            HapticFeedback.vibrate();
            if (isLandscape && search != null) {
              // Če je landscape in je funkcija na voljo, jo izvedi
              search!();
            } else {
              // Sicer izvedi navigacijo na LoginScreen, če je seznam prazen
              if (chosenItems.isEmpty) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()));
              } else {
                // Ne naredi nič, če je seznam poln v portrait načinu.
                null;
              }
            }
          },
          child: Center(
            child: Icon(
              icon,
              color: AppStyles.black,
              size: fontSize.toDouble(),
            ),
          )),
    );
  }
}
