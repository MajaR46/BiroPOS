import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/controllers/test_connection.dart';
import 'package:BiroPOS/utils/debouncer.dart';
import 'package:BiroPOS/components/narocilo.dart';
import 'package:BiroPOS/utils/error_dialog.dart';
import 'package:BiroPOS/utils/utils.dart';
import 'package:BiroPOS/controllers/print.dart';
import 'package:BiroPOS/controllers/process_payment.dart';
import 'package:BiroPOS/providers/direct_payment_provider.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:BiroPOS/screens/blagajna_screen.dart';
import 'package:BiroPOS/screens/davcna_dob_screen.dart';
import 'package:BiroPOS/screens/davcna_stranka_screen.dart';
import 'package:flutter/material.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NacinPlacilaScreen extends ConsumerStatefulWidget {
  const NacinPlacilaScreen({super.key});

  @override
  ConsumerState<NacinPlacilaScreen> createState() => _NacinPlacilaScreenState();
}

class _NacinPlacilaScreenState extends ConsumerState<NacinPlacilaScreen> {
  late OrderService orderService;
  late ProcessPayment paymentService;
  final Debouncer _debouncer = Debouncer(miliseconds: 2000);
  String podjetjeDavcna = '';
  bool _isOnline = true;

  String userId = SessionManager().getLoggedInUserSifra() ?? '';

  @override
  void initState() {
    super.initState();
    checkConnection();

    Future.microtask(() {
      final orderService = ref.watch(orderProvider);
      orderService.initializePaymentMethods();
    });
    paymentService = ProcessPayment(ref);
    _loadPrefereces();
  }

  Future<void> _loadPrefereces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        podjetjeDavcna = prefs.getString('podjetjeDavcna') ?? '';
      });
    } catch (e) {
      throw Exception("Ne moram pridobiti preferences");
    }
  }

  void checkConnection() async {
    bool isOnline = await testConnection(userId);
    setState(() {
      _isOnline = isOnline;
    });
  }

  void _processAndPrintResponse(List<String> apiResponse) async {
    try {
      final filteredResponse = Utils.filterEmptyLines(apiResponse);

      await Print.printText(context, filteredResponse, ref);

      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BlagajnaScreen()),
      );
    } catch (e) {
      if (mounted) {
        ErrorDialogs.showBasicDialog("Napaka pri tiskanju", context);
      }
    }
  }

  void createOrder() async {
    try {
      if (podjetjeDavcna.isEmpty) {
        ErrorDialogs.showBasicDialog(
            "Ne najdem davčne številke podjetja", context);
      }

      final response = await orderService.createOrder(
          context, ref, "TipDokumenta.REP", podjetjeDavcna);
      _processAndPrintResponse(response);
    } catch (e) {
      ErrorDialogs.showBasicDialog("Napaka $e", context);
    }
  }

  Future<bool> checkConnection2() async {
    bool success = await testConnection(userId);
    if (!success) {
      String response = "NI POVEZAVE Z BLAGAJNO";
      await ErrorDialogs.showBasicDialog(response, context);
    }
    return success;
  }

  @override
  Widget build(BuildContext context) {
    double finalSum = ref.watch(narociloNotifierProvider.notifier).totalSum();

    final allpaymentMethods = ref.watch(paymentMethodProvider);
    final paymentMethods = finalSum == 0.0
        ? allpaymentMethods.where((pm) => pm.kodaNacinaPlacila != '02').toList()
        : allpaymentMethods;

    final String davcnaSt = ref.watch(taxNumberProvider) ?? '';
    orderService = ref.watch(orderProvider);
    final settings = ref.watch(settingsProvider);
    final tiskajNarociloPriRacunu =
        settings['isCheckedTiskajNarociloPriRacunu'] ?? false;
    final rep = settings['isCheckedREP'] ?? false;

    void paymentPrint(String paymentMethod, String davcnaSt) async {
      try {
        bool connected = await checkConnection2();
        if (!connected) return;
        paymentService.processPayment(context, paymentMethod, davcnaSt);
        if (tiskajNarociloPriRacunu == true) {
          await Narocilo.createNarocilo(ref, false, context);
        }
        clearDavcna(ref);
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => BlagajnaScreen()));
      } catch (e) {
        ErrorDialogs.showBasicDialog("Težava z bluetooth $e", context);
      }
    }

    return Scaffold(
        backgroundColor: AppStyles.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: GestureDetector(
            onTap: checkConnection,
            child: AppBar(
              backgroundColor: AppStyles.white,
              title: Text(
                "Način plačila",
                style: AppStyles.heading3.copyWith(color: AppStyles.black),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppStyles.black),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BlagajnaScreen())),
              ),
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
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    color: AppStyles.silver.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: Column(
                    children: [
                      const Text(
                        "Znesek:",
                        style: AppStyles.heading3,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text('${finalSum.toStringAsFixed(2)} €',
                            style: AppStyles.heading1.copyWith(
                                fontWeight: FontWeight.normal,
                                color: AppStyles.blue)),
                      ),
                      if (davcnaSt.isNotEmpty)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Davčna: $davcnaSt",
                                  style: AppStyles.paragraph1,
                                ),
                                IconButton.outlined(
                                    style: IconButton.styleFrom(
                                        side:
                                            BorderSide(color: AppStyles.blue)),
                                    onPressed: () {
                                      clearDavcna(ref);
                                      HapticFeedback.vibrate();
                                    },
                                    icon: const Icon(
                                      Icons.clear,
                                      size: 12,
                                      color: AppStyles.blue,
                                    ),
                                    constraints: BoxConstraints(
                                        minWidth: 13, minHeight: 13))
                              ],
                            )),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24, left: 8, right: 8),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: paymentMethods.length,
                  itemBuilder: ((context, index) {
                    final String nacinPlacila;
                    final paymentMethod = paymentMethods[index];

                    if (paymentMethod.kodaNacinaPlacila == "01") {
                      nacinPlacila = "GOT";
                    } else if (paymentMethod.kodaNacinaPlacila == "02") {
                      nacinPlacila = "KAR";
                    } else {
                      nacinPlacila = paymentMethod.kodaNacinaPlacila;
                    }

                    return SizedBox(
                      width: 150, // Nastavite fiksno širino
                      height: 50, // Nastavite fiksno višino
                      child: ElevatedButton(
                        onPressed: () {
                          _debouncer.debouce(() async {
                            paymentPrint(nacinPlacila, davcnaSt!);
                            HapticFeedback.vibrate();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.lightGrey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          paymentMethod.nacinPlacila,
                          style: AppStyles.boldanparagraph1
                              .copyWith(color: AppStyles.black),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // dodano za boljši razmik
                  children: [
                    Flexible(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.vibrate();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DavcnaDOBScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          minimumSize: Size(150, 60),
                        ),
                        child: Text(
                          "DOB",
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: rep
                              ? AppStyles.heading4
                                  .copyWith(color: AppStyles.white)
                              : AppStyles.heading3
                                  .copyWith(color: AppStyles.white),
                        ),
                      ),
                    ),
                    if (rep) SizedBox(width: 16),
                    if (rep)
                      Flexible(
                        child: ElevatedButton(
                          onPressed: () {
                            createOrder();
                            HapticFeedback.vibrate();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.blue,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            minimumSize: Size(150, 60),
                          ),
                          child: Text(
                            "REP",
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.heading3
                                .copyWith(color: AppStyles.white),
                          ),
                        ),
                      ),
                    SizedBox(width: 16),
                    Flexible(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.vibrate();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DavcnaStrankaScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          minimumSize: Size(150, 60),
                        ),
                        child: Text(
                          rep ? "STR" : "STRANKA",
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.heading3
                              .copyWith(color: AppStyles.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
