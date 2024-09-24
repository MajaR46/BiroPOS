import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

class OpenTablesScreen extends StatefulWidget {
  const OpenTablesScreen({super.key});

  State<OpenTablesScreen> createState() => _OpenTablesScreenState();
}

class _OpenTablesScreenState extends State<OpenTablesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppStyles.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text("Odprte mize",
              style: AppStyles.heading3.copyWith(color: AppStyles.black)),
          centerTitle: true,
        ),
        body: Center(
          child: Text("To je screen za z odprtimi mizami"),
        ));
  }
}
