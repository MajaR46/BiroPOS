import 'package:biro_pos/screens/blagajna_screen.dart';
import 'package:biro_pos/screens/kopija_screen.dart';
import 'package:biro_pos/screens/storno_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

class MeniScreen extends StatelessWidget {
  const MeniScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("Meni",
            style: AppStyles.heading3.copyWith(color: AppStyles.black)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 64),
          Center(
            child: SizedBox(
              width: 160,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BlagajnaScreen()));
                },
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppStyles.blue),
                child: Text(
                  "Blagajna",
                  style: AppStyles.button1.copyWith(color: AppStyles.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 128),
          Center(
            child: SizedBox(
              width: 160,
              height: 50,
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const StornoScreen()));
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppStyles.grey),
                  child: Text(
                    "Storno",
                    style: AppStyles.button1.copyWith(color: AppStyles.black),
                  )),
            ),
          ),
          const SizedBox(
            height: 32,
          ),
          Center(
            child: SizedBox(
              width: 160,
              height: 50,
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const KopijaScreen()));
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppStyles.grey),
                  child: Text(
                    "Kopija",
                    style: AppStyles.button1.copyWith(color: AppStyles.black),
                  )),
            ),
          ),
          const SizedBox(
            height: 32,
          ),
          Center(
            child: SizedBox(
              width: 160,
              height: 50,
              child: ElevatedButton(
                  onPressed: () {},
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppStyles.grey),
                  child: Text(
                    "Poročila",
                    style: AppStyles.button1.copyWith(color: AppStyles.black),
                  )),
            ),
          ),
          const SizedBox(
            height: 128,
          ),
          Center(
            child: SizedBox(
              width: 160,
              height: 50,
              child: ElevatedButton(
                  onPressed: () {},
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppStyles.red),
                  child: Text(
                    "Odjava",
                    style: AppStyles.button1.copyWith(color: AppStyles.white),
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
