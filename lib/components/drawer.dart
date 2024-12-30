import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:biro_pos/screens/login.dart';
import 'package:biro_pos/screens/meni_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomDrawer extends ConsumerStatefulWidget {
  const CustomDrawer({super.key});

  @override
  ConsumerState<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends ConsumerState<CustomDrawer> {
  void _logout() {
    SessionManager().clearSession();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? user = SessionManager().getLoggedInUserName();
    final chosenItems = ref.watch(narociloNotifierProvider);

    return Drawer(
      backgroundColor: AppStyles.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 64.0, left: 16.0),
            child: Text(
              user!,
              style: AppStyles.heading2.copyWith(color: AppStyles.black),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 32.0),
            child: SizedBox(
              width: 160,
              height: 50,
              child: ElevatedButton(
                onPressed: chosenItems.isEmpty
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MeniScreen()),
                        )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.blue,
                  disabledBackgroundColor: AppStyles.grey,
                ),
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
                onPressed: chosenItems.isEmpty ? () => _logout() : null,
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
