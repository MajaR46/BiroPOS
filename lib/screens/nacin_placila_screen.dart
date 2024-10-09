import 'package:biro_pos/screens/davcna_dob_screen.dart';
import 'package:biro_pos/screens/davcna_stranka_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

class NacinPlacilaScreen extends StatelessWidget {
  final double finalSum;
  const NacinPlacilaScreen({super.key, required this.finalSum});

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.only(top: 24, bottom: 24),
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
                padding: const EdgeInsets.only(top: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.darkOrange,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))),
                    child: Text(
                      "GOTOVINA",
                      style:
                          AppStyles.heading3.copyWith(color: AppStyles.white),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))),
                    child: Text(
                      "KARTICA",
                      style:
                          AppStyles.heading3.copyWith(color: AppStyles.white),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.silver,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))),
                    child: Text(
                      "TRR",
                      style:
                          AppStyles.heading3.copyWith(color: AppStyles.white),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 64),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 60,
                      child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: ((context) => DavcnaDOBScreen())));
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppStyles.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15))),
                          child: Text(
                            "DOB",
                            style: AppStyles.heading3
                                .copyWith(color: AppStyles.black),
                          )),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 150,
                      height: 60,
                      child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        DavcnaStrankaScreen()));
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppStyles.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15))),
                          child: Text(
                            "STRANKA",
                            style: AppStyles.heading3
                                .copyWith(color: AppStyles.black),
                          )),
                    )
                  ],
                ),
              )
            ],
          ),
        ));
  }
}
