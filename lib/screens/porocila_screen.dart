import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/controllers/print.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PorocilaScreen extends ConsumerStatefulWidget {
  const PorocilaScreen({super.key});

  @override
  ConsumerState<PorocilaScreen> createState() => _PorocilaScreenState();
}

class _PorocilaScreenState extends ConsumerState<PorocilaScreen> {
  List<String> porocila = [];
  List<String> naslovPorocila = [];

  @override
  void initState() {
    super.initState();
    _handleData();
  }

  _handleData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> apiResponseList = prefs.getStringList('porocilo_data') ?? [];
      List<String> extractedTexts = apiResponseList.map((element) {
        String cleanedElement = element.replaceAll('\r', '').trim();
        return cleanedElement.split("|")[0];
      }).toList();

      setState(() {
        porocila = apiResponseList;
        naslovPorocila = extractedTexts;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ni izdelkov")),
      );
    }
  }

  //sprintaj na tiskalnik//////
  _prikaziPorocila(String naslovPorocila) async {
    final prefs = await SharedPreferences.getInstance();

    String? userId = prefs.getString('userId') ?? "";
    String txtData = 'VrniPorocilo\t$naslovPorocila';

    List<String> responsePorocilaList = await sendRequest(userId, txtData);
    final filteredResponse = filterEmptyLines(responsePorocilaList);
    final printableResponse = filteredResponse.join("\r\n");
    printTextWithFormatting(printableResponse, "BlueTooth Printer", ref);

    return responsePorocilaList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Poročila",
          style: AppStyles.heading3.copyWith(color: AppStyles.black),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppStyles.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: naslovPorocila.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: GestureDetector(
                    onTap: () => _prikaziPorocila(naslovPorocila[index]),
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
    );
  }
}
