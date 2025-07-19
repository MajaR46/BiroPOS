import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/controllers/test_connection.dart';
import 'package:BiroPOS/providers/factor_provider.dart';
import 'package:BiroPOS/providers/status_provider.dart';
import 'package:BiroPOS/utils/debouncer.dart';
import 'package:BiroPOS/components/narocilo.dart';
import 'package:BiroPOS/utils/error_dialog.dart';
import 'package:BiroPOS/utils/search_items.dart';
import 'package:BiroPOS/utils/vracilo_denarja.dart';
import 'package:BiroPOS/controllers/process_payment.dart';
import 'package:BiroPOS/providers/direct_payment_provider.dart';
import 'package:BiroPOS/providers/searchquery_provider.dart';
import 'package:BiroPOS/providers/selectedcategory_provider.dart';
import 'package:BiroPOS/providers/selecteditem_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:BiroPOS/models/narociloitem.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  double visinaGumba = 50;
  double sirinaGumba = 80;
  double fontGumb = 16;
  String userId = SessionManager().getLoggedInUserSifra() ?? '';

  @override
  void initState() {
    super.initState();
    paymentService = ProcessPayment(ref);
    _loadPrefereces();
  }

  void _updateFinalSum() {
    final newSum = ref.watch(narociloNotifierProvider.notifier).totalSum();
    setState(() {
      finalSum = newSum;
    });
  }

  Future<bool> checkConnection() async {
    bool success = await testConnection(userId);
    if (!success) {
      String response = "NI POVEZAVE Z BLAGAJNO";
      await ErrorDialogs.showBasicDialog(response, context);
    }
    return success;
  }

  Future<void> _loadPrefereces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String visinaGumbaPrefs =
          prefs.getString('visinaGumbaTipkovnica') ?? '50';

      String sirinaGumbaPrefs =
          prefs.getString('sirinaGumbaTipkovnica') ?? '80';

      String fontGumbTipkovnicaPrefs =
          prefs.getString('fontGumbTipkovnica') ?? '16';

      visinaGumba = double.tryParse(visinaGumbaPrefs) ?? 50;
      sirinaGumba = double.tryParse(sirinaGumbaPrefs) ?? 80;
      fontGumb = double.tryParse(fontGumbTipkovnicaPrefs) ?? 16;
    } catch (e) {
      throw Exception("Ne moram pridobiti preferences");
    }
  }
  /*

  void _decreaseQuantity() {
    final selectedItem = ref.watch(selectedItemProvider);

    if (itemQuantity > 1) {
      setState(() {
        itemQuantity--;
      });
      if (selectedItem != null) {
        ref.read(narociloNotifierProvider.notifier).updateQuantity(
            selectedItem.uniqueId,
            selectedItem.product.id,
            selectedItem.description,
            itemQuantity,
            selectedItem.product.price,
            itemQuantity);
        _updateFinalSum();
      }
    }
  }
  */

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
      double finalSum = ref.read(narociloNotifierProvider.notifier).totalSum();

      try {
        bool connected = await checkConnection();
        ref.read(onlineStatusProvider.notifier).state = connected;

        if (!connected) return;

        ref.read(searchQueryProvider.notifier).state = widget.controller.text;

        String searchQuery = ref.watch(searchQueryProvider);
        String filtriranQuery = searchQuery.replaceAll(RegExp(r'[^0-9.]'), '');

        print("query $filtriranQuery");
        final vnesenZnesek = double.tryParse(filtriranQuery);

        // Calculate the change
        double vracilo = Vracilo.izracunVracila(ref, vnesenZnesek ?? 0.0);

        if (vnesenZnesek != null && vnesenZnesek > 0.0) {
          await Vracilo.showReturnDialog(
              context, vnesenZnesek, finalSum, vracilo);
        }

        if (tiskajNarociloPriRacunu) {
          await Narocilo.createNarocilo(ref, false, context);
        }
        // Process the payment
        await paymentService.processPayment(context, "GOT");

        widget.controller.clear();
      } catch (e) {
        ErrorDialogs.showBasicDialog("Težava z bluetooth $e", context);
      }
    });
  }

  void _paymentKartica() {
    _debouncer.debouce(() async {
      bool connected = await checkConnection();
      ref.read(onlineStatusProvider.notifier).state = connected;

      if (!connected) return;
      final settings = ref.watch(settingsProvider);
      final tiskajNarociloPriRacunu =
          settings['isCheckedTiskajNarociloPriRacunu'] ?? false;

      await paymentService.processPayment(context, "KAR");
    });
  }

  bool _handleMultiply(
    double factor,
  ) {
    final selectedItem = ref.read(selectedItemProvider.notifier).state;
    if (selectedItem != null) {
      ref.read(narociloNotifierProvider.notifier).updateQuantity(
          selectedItem.uniqueId,
          selectedItem.product.id,
          selectedItem.description,
          factor,
          selectedItem.product.price,
          selectedItem.quantity);

      ref.read(selectedItemProvider.notifier).state =
          selectedItem.copyWith(quantity: factor);

      setState(() {
        itemQuantity = factor;
      });

      _updateFinalSum();
      return true; // Vrnemo true, ker je bila akcija zaključena
    } else {
      ref.read(multiplyFactorProvider.notifier).state = factor;
      widget.controller.clear();

      return false; // Vrnemo false, ker pričakujemo nadaljnji vnos
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
    final newSum = ref.watch(narociloNotifierProvider.notifier).totalSum();

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
                      KeyboardC(
                        controller: widget.controller,
                        sirinaGumba: sirinaGumba,
                        visinaGumba: visinaGumba,
                        fontGumb: fontGumb,
                      ),
                      KeyboardMultiply(
                        multiply: _handleMultiply,
                        quantity: itemQuantity,
                        controller: widget.controller,
                        visinaGumba: visinaGumba,
                        sirinaGumba: sirinaGumba,
                        fontGumb: fontGumb,
                      ),
                      KeyboardNumber(
                        number: ',',
                        controller: widget.controller,
                        sirinaGumba: sirinaGumba,
                        visinaGumba: visinaGumba,
                        fontGumb: fontGumb,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      KeyboardNumber(
                        number: "1",
                        controller: widget.controller,
                        sirinaGumba: sirinaGumba,
                        visinaGumba: visinaGumba,
                        fontGumb: fontGumb,
                      ),
                      KeyboardNumber(
                        number: "2 ABC",
                        controller: widget.controller,
                        sirinaGumba: sirinaGumba,
                        visinaGumba: visinaGumba,
                        fontGumb: fontGumb,
                      ),
                      KeyboardNumber(
                        number: "3 DEF",
                        controller: widget.controller,
                        sirinaGumba: sirinaGumba,
                        visinaGumba: visinaGumba,
                        fontGumb: fontGumb,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      KeyboardNumber(
                        number: "4 GHI",
                        controller: widget.controller,
                        sirinaGumba: sirinaGumba,
                        visinaGumba: visinaGumba,
                        fontGumb: fontGumb,
                      ),
                      KeyboardNumber(
                        number: "5 JKL",
                        controller: widget.controller,
                        sirinaGumba: sirinaGumba,
                        visinaGumba: visinaGumba,
                        fontGumb: fontGumb,
                      ),
                      KeyboardNumber(
                        number: "6 MNO",
                        controller: widget.controller,
                        sirinaGumba: sirinaGumba,
                        visinaGumba: visinaGumba,
                        fontGumb: fontGumb,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      KeyboardNumber(
                        number: "7 PQRS",
                        controller: widget.controller,
                        sirinaGumba: sirinaGumba,
                        visinaGumba: visinaGumba,
                        fontGumb: fontGumb,
                      ),
                      KeyboardNumber(
                        number: "8 TUV",
                        controller: widget.controller,
                        sirinaGumba: sirinaGumba,
                        visinaGumba: visinaGumba,
                        fontGumb: fontGumb,
                      ),
                      KeyboardNumber(
                        number: "9 WXYZ",
                        controller: widget.controller,
                        sirinaGumba: sirinaGumba,
                        visinaGumba: visinaGumba,
                        fontGumb: fontGumb,
                      ),
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
                        visinaGumba: visinaGumba,
                        sirinaGumba: sirinaGumba,
                        fontGumb: fontGumb,
                      ),
                      KeyboardNumber(
                        number: "0",
                        controller: widget.controller,
                        sirinaGumba: sirinaGumba,
                        visinaGumba: visinaGumba,
                        fontGumb: fontGumb,
                      ),
                      KeyboardRedirect(
                        backgroundColor: AppStyles.blue,
                        text: widget.opisDiscountButton,
                        visinaGumba: visinaGumba,
                        sirinaGumba: sirinaGumba,
                        fontGumb: fontGumb,
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
                    visinaGumba: visinaGumba,
                    sirinaGumba: sirinaGumba,
                    fontGumb: fontGumb,
                    onPressed: widget.navigateToRacun),
              ),
              if (!prikazujSamoNarocila)
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: KeyboardRedirect(
                      backgroundColor: AppStyles.brightOrange,
                      text: "GOT",
                      visinaGumba: visinaGumba,
                      sirinaGumba: sirinaGumba,
                      fontGumb: fontGumb,
                      onPressed: () {
                        _paymentGotovina();
                      }),
                ),
              if (!prikazujSamoNarocila)
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: KeyboardRedirect(
                    backgroundColor: AppStyles.brightRed,
                    text: "KAR",
                    visinaGumba: visinaGumba,
                    sirinaGumba: sirinaGumba,
                    fontGumb: fontGumb,
                    onPressed: obstajaKarPlacilo && newSum > 0.00
                        ? () {
                            _paymentKartica();
                            widget.controller.clear();
                          }
                        : () {}, // Empty function if not available
                  ),
                ),
              if (!prikazujSamoRacune)
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: KeyboardRedirect(
                      backgroundColor: AppStyles.brightPurple,
                      text: mizaButton,
                      visinaGumba: visinaGumba,
                      sirinaGumba: sirinaGumba,
                      fontGumb: fontGumb,
                      onPressed: widget.navigateToMizaScreen),
                ),
              if (!prikazujSamoNarocila)
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: KeyboardRedirect(
                    backgroundColor: AppStyles.green,
                    text: "OK",
                    visinaGumba: visinaGumba,
                    sirinaGumba: sirinaGumba,
                    fontGumb: fontGumb,
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
  final double sirinaGumba;
  final double visinaGumba;
  final double fontGumb;

  const KeyboardNumber(
      {super.key,
      required this.number,
      required this.controller,
      required this.sirinaGumba,
      required this.visinaGumba,
      required this.fontGumb});

  @override
  State<KeyboardNumber> createState() => _KeyboardNumberState();
}

class _KeyboardNumberState extends State<KeyboardNumber> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.sirinaGumba,
      height: widget.visinaGumba,
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
            style: TextStyle(
                fontSize: widget.fontGumb,
                fontWeight: FontWeight.bold,
                color: AppStyles.black),
          ),
        ),
      ),
    );
  }
}

class KeyboardC extends ConsumerWidget {
  final TextEditingController controller;
  final double sirinaGumba;
  final double visinaGumba;
  final double fontGumb;

  const KeyboardC(
      {super.key,
      required this.controller,
      required this.sirinaGumba,
      required this.visinaGumba,
      required this.fontGumb});

  void _clearText(WidgetRef ref) {
    controller.clear();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: sirinaGumba,
      height: visinaGumba,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.lightGrey,
              padding: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15))),
          onPressed: () {
            HapticFeedback.vibrate();

            _clearText(ref);
            ref.read(selectedCategoryProvider.notifier).state = 'Vse';
            ref.read(isSearchingProvider.notifier).state = false;
            Future(() {
              ref.read(filteredItemsProvider.notifier).state =
                  []; // ali: naloži vse
              updateNumbersString(controller, ref);
            });
          },
          child: Center(
            child: Text(
              "C",
              style: TextStyle(
                  fontSize: fontGumb,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.black),
            ),
          )),
    );
  }
}

class KeyboardMultiply extends StatelessWidget {
  final TextEditingController controller;
  final double quantity;
  final Function(double result) multiply;
  final double sirinaGumba;
  final double visinaGumba;
  final double fontGumb;

  const KeyboardMultiply(
      {super.key,
      required this.multiply,
      required this.quantity,
      required this.controller,
      required this.sirinaGumba,
      required this.visinaGumba,
      required this.fontGumb});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: sirinaGumba,
      height: visinaGumba,
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
            // Kličemo funkcijo in shranimo njen rezultat
            final bool shouldClear = multiply(number);

            // Počistimo kontroler samo, če je funkcija vrnila true
            if (shouldClear) {
              controller.clear();
            }
          }
        },
        child: Center(
          child: Text(
            "*",
            style: TextStyle(
                fontSize: fontGumb,
                fontWeight: FontWeight.bold,
                color: AppStyles.black),
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
  final double sirinaGumba;
  final double visinaGumba;
  final double fontGumb;

  const KeyboardRedirect(
      {super.key,
      required this.backgroundColor,
      required this.text,
      required this.onPressed,
      required this.visinaGumba,
      required this.sirinaGumba,
      required this.fontGumb});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: sirinaGumba,
      height: visinaGumba,
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
              style: TextStyle(
                  fontSize: fontGumb,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.white),
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
  final double sirinaGumba;
  final double visinaGumba;
  final double fontGumb;

  const KeyboardBack(
      {super.key,
      required this.fontSize,
      required this.borderRadius,
      required this.height,
      this.search,
      required this.icon,
      required this.visinaGumba,
      required this.sirinaGumba,
      required this.fontGumb});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //final chosenItems = ref.watch(narociloNotifierProvider);

    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return SizedBox(
      width: sirinaGumba,
      height: visinaGumba,
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
            } else {}
          },
          child: Center(
            child: Icon(
              icon,
              color: AppStyles.black,
              size: fontGumb,
            ),
          )),
    );
  }
}
