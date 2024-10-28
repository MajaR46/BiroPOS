import 'package:biro_pos/components/ok_button.dart';
import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

class StornoScreen extends StatefulWidget {
  const StornoScreen({super.key});

  @override
  State<StornoScreen> createState() => _StornoScreenState();
}

class _StornoScreenState extends State<StornoScreen> {
  final TextEditingController _stornoRacunController = TextEditingController();
  final String? userSifra = SessionManager().getLoggedInUserSifra();
  String? _apiResponse;

  void _clearText() {
    _stornoRacunController.clear();
    setState(() {
      _apiResponse = null; //
    });
  }

  //to printaj
  _handleData() async {
    try {
      String stRacuna = _stornoRacunController.text;

      String txtData = 'StornoRacuna\t$userSifra\t$stRacuna';
      List<String> apiResponse = await sendRequest(userSifra ?? '', txtData);
      setState(() {
        _apiResponse = apiResponse.join("\n");
      });
    } catch (e) {
      print("Error fetching data: $e");
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
            "Storno računa",
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
                    controller: _stornoRacunController,
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
                const SizedBox(height: 32),
                if (_apiResponse != null) Text(_apiResponse!),
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
