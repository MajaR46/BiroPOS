import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/providers/payment_provider.dart';
import 'package:biro_pos/screens/davcna_dob_screen.dart';
import 'package:biro_pos/screens/davcna_stranka_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter/widgets.dart';
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
    orderService = ref.read(orderProvider);
    orderService.initializePaymentMethods();
  }

  void _showResponseDialog(List<String> response) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Server Response"),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(response.join('\n')), // Display the response line by line
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double finalSum = ref.read(narociloNotifierProvider.notifier).totalSum();
    final paymentMethods = ref.watch(paymentMethodProvider);
    print("načini plačil $paymentMethods");
    orderService = ref.read(orderProvider);

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
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24, left: 8, right: 8),
                child: GridView.builder(
                  shrinkWrap:
                      true, // Add this to make the GridView take only the space it needs
                  physics:
                      NeverScrollableScrollPhysics(), // Disable scrolling within the GridView itself
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
                      onPressed: () async {
                        if (paymentMethods.isNotEmpty) {
                          final response = await orderService.createOrder(
                            context,
                            paymentMethod.kodaNacinaPlacila,
                            "#MIZA#", // example table number
                            "DIREKTENRACUN", // example order type
                          );
                          _showResponseDialog(response);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("No payment methods available!")),
                          );
                        }
                      },
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
                  crossAxisAlignment:
                      CrossAxisAlignment.end, // Aligns children to the bottom
                  children: [
                    Align(
                      alignment: Alignment
                          .bottomLeft, // Aligns button to the bottom left
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
                    Spacer(), // Adds flexible space between the two buttons
                    Align(
                      alignment: Alignment
                          .bottomRight, // Aligns button to the bottom right
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
