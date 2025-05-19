import 'package:BiroPOS/components/ok_button.dart';
import 'package:BiroPOS/controllers/klic.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/tableitem_provider.dart';
import 'package:BiroPOS/screens/blagajna_screen.dart';
import 'package:flutter/material.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrenosMizeScreen extends ConsumerStatefulWidget {
  final String tableNumber;
  const PrenosMizeScreen({super.key, required this.tableNumber});

  @override
  ConsumerState<PrenosMizeScreen> createState() => _PrenosMizeScreenState();
}

class _PrenosMizeScreenState extends ConsumerState<PrenosMizeScreen> {
  final TextEditingController _prenosMizeController = TextEditingController();
  final String? userSifra = SessionManager().getLoggedInUserSifra();
  String? _apiResponse;

  void _clearText() {
    _prenosMizeController.clear();
    setState(() {
      _apiResponse = null;
    });
  }

  Future<void> _prenosMize() async {
    String newTableNumber = _prenosMizeController.text;

    if (newTableNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vnesi številko mize")),
      );
      return;
    }

    // Now call the transferFromTable method and pass the current table number and the new table number
    List<String> serverResponse =
        await ref.read(tableNotifierProvider.notifier).transferFromTable(
              context,
              widget.tableNumber, // Pass the current table number
              newTableNumber, // Pass the new table number from the controller
            );

    if (serverResponse.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BlagajnaScreen()),
      );
    }

    ref.read(narociloNotifierProvider.notifier).clearChosenItems();
    ref.read(tableNotifierProvider.notifier).state = [];
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
            "Prenos mize",
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
                    "Oznaka mize:",
                    style: AppStyles.heading2.copyWith(color: AppStyles.black),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _prenosMizeController,
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
                if (_apiResponse != null)
                  Text(
                    _apiResponse!,
                    style: TextStyle(
                        color: _apiResponse == "Table transferred successfully!"
                            ? Colors.green
                            : Colors.red),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 32),
              child: Align(
                alignment: Alignment.bottomRight,
                child: OKButton(
                  onPressed: _prenosMize,
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
