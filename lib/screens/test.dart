import 'package:biro_pos/components/blagajna_banner.dart';
import 'package:flutter/material.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 64),
      child: (Scaffold(
          body: BlagajnaBanner(
        chosenItem: "Vino",
        quantity: 4,
        sum: 10.5,
      ))),
    );
  }
}
