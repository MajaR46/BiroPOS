import 'package:biro_pos/components/blagajna_banner.dart';
import 'package:biro_pos/components/keyboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TestScreen extends StatelessWidget {
  final TextEditingController _testController = TextEditingController();
  TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: (Scaffold(
          body: BlagajnaBanner(
        chosenItem: "Vino",
        quantity: 4,
        sum: 10.5,
      ))),
    );
  }
}
