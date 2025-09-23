import 'dart:io';

import 'package:BiroPOS/app_styles.dart';
import 'package:BiroPOS/components/numpad.dart';
import 'package:BiroPOS/controllers/inetis.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/controllers/test_connection.dart';
import 'package:BiroPOS/providers/davcna_provider.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/status_provider.dart';
import 'package:BiroPOS/screens/blagajna_screen.dart';
import 'package:BiroPOS/utils/error_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class DavcnaStrankaScreen extends ConsumerStatefulWidget {
  const DavcnaStrankaScreen({super.key});

  @override
  ConsumerState<DavcnaStrankaScreen> createState() =>
      _DavcnaStrankaScreenState();
}

class _DavcnaStrankaScreenState extends ConsumerState<DavcnaStrankaScreen> {
  final TextEditingController _strankaController = TextEditingController();
  bool _isOnline = true;
  String userId = SessionManager().getLoggedInUserSifra() ?? '';

  void _clearText() {
    _strankaController.clear();
  }

  @override
  void initState() {
    super.initState();
    checkConnection();
  }

  void checkConnection() async {
    bool isOnline = await testConnection(userId);
    if (mounted) {
      ref.read(onlineStatusProvider.notifier).state = isOnline;
    }
  }

  @override
  Widget build(BuildContext context) {
    _isOnline = ref.watch(onlineStatusProvider);
    void _setDavcna() async {
      final String davcnaSt = _strankaController.text;

      if (davcnaSt.length == 8) {
        ref.read(taxNumberProvider.notifier).state = davcnaSt;

        Map<String, String> inetisRezultat = await inetisCall(davcnaSt);

        ref.read(davcnaPodatkiProvider.notifier).state = inetisRezultat;

        Navigator.of(context).pop();
      } else {
        ErrorDialogs.showBasicDialog(
            "Davčna številka mora imeti 8 znakov", context);
      }
    }

    return Scaffold(
      backgroundColor: AppStyles.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: GestureDetector(
          onTap: checkConnection,
          child: AppBar(
            backgroundColor: AppStyles.white,
            title: Text(
              "Davčna stranka",
              style: AppStyles.heading3.copyWith(color: AppStyles.black),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppStyles.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: Text(
                  _isOnline ? "Online" : "Offline",
                  style: AppStyles.paragraph3.copyWith(
                    color: _isOnline ? AppStyles.green : AppStyles.brightRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 64),
        child: Column(
          children: [
            const Text(
              "Številka: ",
              style: AppStyles.heading2,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 300,
              child: TextField(
                autofocus: true,
                readOnly: Platform.isWindows ? false : true,
                showCursor: true,
                controller: _strankaController,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                cursorColor: AppStyles.blue,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppStyles.silver.withAlpha((0.1 * 255).round()),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide.none,
                  ),
                  suffixIconColor: AppStyles.blue,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearText,
                    focusColor: AppStyles.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Numpad(controller: _strankaController, onOKPressed: _setDavcna),
          ],
        ),
      ),
    );
  }
}
