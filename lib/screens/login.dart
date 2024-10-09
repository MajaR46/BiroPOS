import 'package:biro_pos/components/klic.dart';
import 'package:biro_pos/components/numpad.dart';
import 'package:biro_pos/screens/api_key_screen.dart';
import 'package:biro_pos/screens/meni_screen.dart';
import 'package:biro_pos/screens/test.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _logininputcontroller = TextEditingController();
  final bool _isHidden = true;

  void _clearText() {
    _logininputcontroller.clear();
  }

  void _handleOKPressed() {
    if (_logininputcontroller.text == "1") {
      //TO DO: spremeni pogoj ko bo povezava na strežnik
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const MeniScreen()));
    }
  }

  _launchURL(String urlString) async {
    Uri url = Uri.parse(urlString);

    if (await launchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _showEchoDialog(List<String> response) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              "Test povezave",
              style: AppStyles.heading3,
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Stanje: ${response[0].replaceAll('|', '')}'),
                  Text('Datum in čas: ${response[1].replaceAll('|', '')}'),
                  Text('Verzija: ${response[2].replaceAll('|', '')}')
                ],
              ),
            ),
            actions: [
              TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppStyles.blue),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"))
            ],
          );
        });
  }

  void _handleTestConnection() async {
    List<String> responseList = await sendRequest("1", "echo");

    _showEchoDialog(responseList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(
              height: 80,
            ),
            Text('Prijava',
                style: AppStyles.heading1.copyWith(color: AppStyles.black)),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 250,
                child: TextField(
                  obscureText: _isHidden,
                  controller: _logininputcontroller,
                  readOnly: true,
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: AppStyles.silver.withOpacity(0.1),
                      suffixIconColor: AppStyles.blue,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearText,
                        focusColor: AppStyles.blue,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: BorderSide.none,
                      )),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Numpad(
              controller: _logininputcontroller,
              onOKPressed: _handleOKPressed,
            ),
            const SizedBox(
              height: 30,
            ),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ApiKeyScreen()));
                },
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppStyles.blue),
                child: Text(
                  "Api ključ",
                  style: AppStyles.heading3.copyWith(color: AppStyles.white),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleTestConnection,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      "Test\npovezave",
                      textAlign: TextAlign.center,
                      style: AppStyles.button2.copyWith(color: AppStyles.black),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 80,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleOKPressed,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      "Osveži",
                      textAlign: TextAlign.center,
                      style: AppStyles.button2.copyWith(color: AppStyles.black),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 80,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TestScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      "Test\ntiskalnika",
                      textAlign: TextAlign.center,
                      style: AppStyles.button2.copyWith(color: AppStyles.black),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 30,
            ),
            Row(children: [
              GestureDetector(
                  onTap: () => _launchURL("https://www.biropos.si/"),
                  child: const Text("BiroPOS", style: AppStyles.paragraph1)),
              const Spacer(),
              GestureDetector(
                  onTap: () => _launchURL(
                      "https://play.google.com/store/apps/datasafety?id=si.Flop.BiroPOS&pli=1"),
                  child:
                      const Text("Pogoji uporabe", style: AppStyles.paragraph1))
            ])
          ],
        ),
      ),
    );
  }
}
