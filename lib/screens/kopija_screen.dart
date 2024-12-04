import 'package:biro_pos/components/ok_button.dart';
import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/controllers/print.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
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

  //to printaj
  _handleData() async {
    try {
      String stRacuna = _kopijaRacunController.text;
      List<String> apiResponse;

      if (stRacuna.isEmpty) {
        String txtDataZadnjiracun = 'VrniZadnjiRacun\t$userSifra';
        apiResponse = await sendRequest(userSifra ?? '', txtDataZadnjiracun);
        final filteredResponse = filterEmptyLines(apiResponse);
        final printableResponse = filteredResponse.join("\r\n");
        printTextWithFormatting(printableResponse, "BlueTooth Printer", ref);
      } else {
        String txtData = 'VrniKopijoRacuna\t$userSifra\t$stRacuna';
        apiResponse = await sendRequest(userSifra ?? '', txtData);
        final filteredResponse = filterEmptyLines(apiResponse);
        final printableResponse = filteredResponse.join("\r\n");
        printTextWithFormatting(printableResponse, "BlueTooth Printer", ref);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ni izdelkov")),
      );
      setState(() {
        _apiResponse = 'Error fetching data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Kopija računa",
            style: AppStyles.heading3.copyWith(color: AppStyles.black),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppStyles.black),
            onPressed: () => Navigator.of(context).pop(),
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

                // Display the API response below the TextField
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
                child: OKButton(onPressed: _handleData),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
