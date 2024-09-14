import 'package:biro_pos/screens/meni_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Aligns all child widgets to the left
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 64.0, left: 16.0),
            child: Text(
              'Demo Blagajnk',
              style: AppStyles.heading2.copyWith(color: AppStyles.black),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 32.0),
            child: SizedBox(
              width: 160,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MeniScreen()),
                  );
                },
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppStyles.blue),
                child: Text(
                  "Meni",
                  style: AppStyles.button1.copyWith(color: AppStyles.white),
                ),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 32.0),
            child: SizedBox(
              width: 160,
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.red,
                ),
                child: Text(
                  'Odjava',
                  style: AppStyles.button1.copyWith(color: AppStyles.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
