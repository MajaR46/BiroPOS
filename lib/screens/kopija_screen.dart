import 'package:BiroPOS/utils/error_dialog.dart';
import 'package:BiroPOS/components/ok_button.dart';
import 'package:BiroPOS/utils/utils.dart';
import 'package:BiroPOS/controllers/klic.dart';
import 'package:BiroPOS/controllers/print.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/screens/blagajna_screen.dart';
import 'package:flutter/material.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KopijaScreen extends ConsumerStatefulWidget {
  const KopijaScreen({super.key});

  @override
  ConsumerState<KopijaScreen> createState() => _KopijaScreenState();
}

class _KopijaScreenState extends ConsumerState<KopijaScreen> {
  final TextEditingController _kopijaRacunController = TextEditingController();
  final String? userSifra = SessionManager().getLoggedInUserSifra();
  String? _apiResponse;

  void _clearText() {
    _kopijaRacunController.clear();
  }

  Future<void> _handleData() async {
    try {
      final String stRacuna = _kopijaRacunController.text;
      final String txtData = stRacuna.isEmpty
          ? 'VrniZadnjiRacun\t$userSifra'
          : 'VrniKopijoRacuna\t$userSifra\t$stRacuna';

      final List<String> apiResponse =
          await sendRequest(userSifra ?? '', txtData);
      _processAndPrintResponse(apiResponse);
    } catch (e) {
      _showError("Ni izdelkov");
    }
  }

  void _processAndPrintResponse(List<String> apiResponse) async {
    try {
      final filteredResponse = Utils.filterEmptyLines(apiResponse);

      await Print.printText(context, filteredResponse, ref);
      await ErrorDialogs.showResponseDialog(apiResponse, context!);

      if (mounted) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showError("Error during printing: $e");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() {
      _apiResponse = 'Error fetching data';
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppStyles.white,
        appBar: AppBar(
          backgroundColor: AppStyles.white,
          title: Text(
            "Kopija računa",
            style: AppStyles.heading3.copyWith(color: AppStyles.black),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppStyles.black),
            onPressed: () {
              HapticFeedback.vibrate();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 64),
                Center(
                  child: Text(
                    "Številka računa:",
                    style: AppStyles.heading2.copyWith(color: AppStyles.black),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 250,
                  child: TextField(
                    autofocus: true,
                    controller: _kopijaRacunController,
                    cursorColor: AppStyles.blue,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppStyles.silver.withOpacity(0.1),
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
                const SizedBox(height: 16),
                if (_apiResponse != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _apiResponse!,
                      style:
                          AppStyles.paragraph1.copyWith(color: AppStyles.black),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 32),
              child: Align(
                alignment: Alignment.bottomRight,
                child: OKButton(
                  onPressed: _handleData,
                  text: 'OK',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
