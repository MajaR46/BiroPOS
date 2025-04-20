import 'package:BiroPOS/components/ok_button.dart';
import 'package:BiroPOS/components/utils.dart';
import 'package:BiroPOS/controllers/besteron_controller.dart';
import 'package:BiroPOS/controllers/klic.dart';
import 'package:BiroPOS/controllers/print.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:flutter/material.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PorocilaScreen extends ConsumerStatefulWidget {
  const PorocilaScreen({super.key});

  @override
  ConsumerState<PorocilaScreen> createState() => _PorocilaScreenState();
}

class _PorocilaScreenState extends ConsumerState<PorocilaScreen> {
  List<String> porocila = [];
  List<String> naslovPorocila = [];
  bool isLoading = false;
  final TextEditingController vraciloController = TextEditingController();
  double vraciloAmount = 0.0;
  String tid = '';

  @override
  void initState() {
    super.initState();
    _handleData();
  }

  void _clearText() {
    vraciloController.clear();
  }

  _handleData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? TID = prefs.getString('TID') ?? '';

      String userId = SessionManager().getLoggedInUserSifra() ?? '';
      List<String> apiResponseList = await sendRequest(userId, "VrniPorocila");
      List<String> extractedTexts = apiResponseList.map((element) {
        String cleanedElement = element.replaceAll('\r', '').trim();
        return cleanedElement.split("|")[0];
      }).toList();

      setState(() {
        porocila = apiResponseList;
        naslovPorocila = extractedTexts;
        tid = TID;
      });
    } catch (e) {
      setState(() {
        isLoading = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ni vzpostavljene povezave")),
      );
    }
  }

  //sprintaj na tiskalnik//////
  _prikaziPorocila(String naslovPorocila) async {
    final prefs = await SharedPreferences.getInstance();

    String? userId = prefs.getString('userId') ?? "";
    String txtData = 'VrniPorocilo\t$naslovPorocila';

    List<String> responsePorocilaList = await sendRequest(userId, txtData);
    final filteredResponse = Utils.filterEmptyLines(responsePorocilaList);
    final printableResponse = filteredResponse.join("\r\n");
    if (printableResponse != "#NAPAKA#Blagajna je zakljucena#") {
      await Print.printText(context, filteredResponse, ref);
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    Navigator.of(context).pop();

    return responsePorocilaList;
  }

  _porocilaPOS() async {
    final besteronResponse = await besteronPorocilo();

    await Print.printText(context, besteronResponse, ref);
    print("besteron response ${besteronResponse.toString()}");
  }

  Future<void> _vrniPOSZnesek() async {
    final double? vraciloAmount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.white,
        title: Text(
          "Znesek vračila",
          textAlign: TextAlign.center,
          style: AppStyles.heading3,
        ),
        content: TextField(
          controller: vraciloController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppStyles.silver.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearText,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final value =
                  double.tryParse(vraciloController.text.replaceAll(',', '.'));
              Navigator.of(context).pop(value); // Vrnemo znesek in zapremo
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.blue,
            ),
            child: Text(
              "OK",
              style: AppStyles.button1.copyWith(color: AppStyles.white),
            ),
          ),
        ],
      ),
    );

    if (vraciloAmount == null) return;

    final besteronResponse = await besteronVracilo(vraciloAmount);
    String result = besteronResponse['result'];
    String besteronRacun = besteronResponse['receipt'];

    if (result != "Success") {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Napaka pri komunikaciji z Besteronom ")),
        );
      }
    }

    await Print.printText(context, [besteronRacun], ref);
    vraciloController.text = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.white,
      appBar: AppBar(
        backgroundColor: AppStyles.white,
        title: Text(
          "Poročila",
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
      body: Stack(children: [
        Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: naslovPorocila.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.vibrate();

                              _prikaziPorocila(naslovPorocila[index]);
                            },
                            child: ListTile(
                              title: Text(naslovPorocila[index]),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) {
                        return Divider(
                          indent: 7,
                          endIndent: 7,
                          color: AppStyles.silver.withOpacity(0.6),
                          thickness: 1,
                        );
                      },
                    ),
            ),
          ],
        ),
        if (tid != '')
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 32),
            child: Align(
              alignment: Alignment.bottomRight,
              child: OKButton(onPressed: _porocilaPOS, text: "Poročilo POS"),
            ),
          ),
        if (tid != '')
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 32),
            child: Align(
              alignment: Alignment.bottomLeft,
              child:
                  OKButton(onPressed: _vrniPOSZnesek, text: "Vračilo zneska"),
            ),
          )
      ]),
    );
  }
}
