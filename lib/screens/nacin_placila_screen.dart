import 'package:biro_pos/components/debouncer.dart';
import 'package:biro_pos/components/narocilo.dart';
import 'package:biro_pos/components/utils.dart';
import 'package:biro_pos/controllers/print.dart';
import 'package:biro_pos/controllers/process_payment.dart';
import 'package:biro_pos/providers/direct_payment_provider.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/providers/settings_provider.dart';
import 'package:biro_pos/screens/blagajna_screen.dart';
import 'package:biro_pos/screens/davcna_dob_screen.dart';
import 'package:biro_pos/screens/davcna_stranka_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NacinPlacilaScreen extends ConsumerStatefulWidget {
  const NacinPlacilaScreen({super.key});

  @override
  ConsumerState<NacinPlacilaScreen> createState() => _NacinPlacilaScreenState();
}

class _NacinPlacilaScreenState extends ConsumerState<NacinPlacilaScreen> {
  late OrderService orderService;
  late ProcessPayment paymentService;
  final Debouncer _debouncer = Debouncer(miliseconds: 2000);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final orderService = ref.watch(orderProvider);
      orderService.initializePaymentMethods();
    });
    paymentService = ProcessPayment(ref);
  }

  @override
  Widget build(BuildContext context) {
    double finalSum = ref.watch(narociloNotifierProvider.notifier).totalSum();
    final paymentMethods = ref.watch(paymentMethodProvider);
    final String davcnaSt = ref.watch(taxNumberProvider) ?? '';
    orderService = ref.watch(orderProvider);
    final settings = ref.watch(settingsProvider);
    final tiskajNarociloPriRacunu =
        settings['isCheckedTiskajNarociloPriRacunu'] ?? false;

    void paymentPrint(String paymentMethod, String davcnaSt) async {
      try {
        paymentService.processPayment(context, paymentMethod, davcnaSt);
        if (tiskajNarociloPriRacunu == true) {
          await Narocilo.createNarocilo(ref, false, context);
        }
        clearDavcna(ref);
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => BlagajnaScreen()));
      } catch (e) {
        print("Težava z bluetooth");
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Težava z bluetooth!")));
      }
    }

    return Scaffold(
        backgroundColor: AppStyles.white,
        appBar: AppBar(
          backgroundColor: AppStyles.white,
          title: Text(
            "Način plačila",
            style: AppStyles.heading3.copyWith(color: AppStyles.black),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppStyles.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    color: AppStyles.silver.withOpacity(0.1),
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
                    maxCrossAxisExtent: 200, // Nastavite največjo širino gumba
                    childAspectRatio: 2.5, // Ohranite ustrezno razmerje
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
                  children: [
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: SizedBox(
                        width: 150,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.vibrate();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DavcnaDOBScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            "DOB",
                            style: AppStyles.heading3
                                .copyWith(color: AppStyles.white),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: SizedBox(
                        width: 150,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.vibrate();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DavcnaStrankaScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            "STRANKA",
                            style: AppStyles.heading3
                                .copyWith(color: AppStyles.white),
                          ),
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
