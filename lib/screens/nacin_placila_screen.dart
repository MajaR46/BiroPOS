import 'package:biro_pos/controllers/print.dart';
import 'package:biro_pos/providers/direct_payment_provider.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/screens/davcna_dob_screen.dart';
import 'package:biro_pos/screens/davcna_stranka_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NacinPlacilaScreen extends ConsumerStatefulWidget {
  const NacinPlacilaScreen({super.key});

  @override
  ConsumerState<NacinPlacilaScreen> createState() => _NacinPlacilaScreenState();
}

class _NacinPlacilaScreenState extends ConsumerState<NacinPlacilaScreen> {
  late OrderService orderService;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final orderService = ref.watch(orderProvider);
      orderService.initializePaymentMethods();
    });
  }

  @override
  Widget build(BuildContext context) {
    double finalSum = ref.watch(narociloNotifierProvider.notifier).totalSum();
    final paymentMethods = ref.watch(paymentMethodProvider);
    final String? davcnaSt = ref.watch(taxNumberProvider);
    orderService = ref.watch(orderProvider);

    void createOrder(String paymentMethod) async {
      if (paymentMethods.isNotEmpty) {
        final response =
            await orderService.createOrder(context, paymentMethod, davcnaSt);
        final filteredResponse = filterEmptyLines(response);
        final printableResponse = filteredResponse.join("\r\n");
        printTextWithFormatting(printableResponse, "BlueTooth Printer", ref);

        //_showResponseDialog(response);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No payment methods available!")),
        );
      }
    }

    return Scaffold(
        appBar: AppBar(
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
                      if (davcnaSt != null) // Only show if davcnaSt is not null
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Davčna: $davcnaSt",
                            style: AppStyles.paragraph1,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24, left: 8, right: 8),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: paymentMethods.length,
                  itemBuilder: ((context, index) {
                    final paymentMethod = paymentMethods[index];

                    return ElevatedButton(
                      onPressed: () =>
                          createOrder(paymentMethod.kodaNacinaPlacila),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                      child: Text(paymentMethod.nacinPlacila,
                          style: AppStyles.boldanparagraph1
                              .copyWith(color: AppStyles.black)),
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
