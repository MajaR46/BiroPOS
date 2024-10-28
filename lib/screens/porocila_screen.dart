import 'package:biro_pos/controllers/klic.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

class PorocilaScreen extends StatefulWidget {
  const PorocilaScreen({super.key});

  @override
  State<PorocilaScreen> createState() => _PorocilaScreenState();
}

class _PorocilaScreenState extends State<PorocilaScreen> {
  List<String> porocila = [];
  List<String> naslovPorocila = [];

  @override
  void initState() {
    super.initState();
    _handleData();
  }

  _handleData() async {
    try {
      List<String> apiResponseList = await sendRequest("1", "VrniPorocila");

      List<String> extractedTexts = apiResponseList.map((element) {
        String cleanedElement = element.replaceAll('\r', '').trim();
        return cleanedElement.split("|")[0];
      }).toList();

      setState(() {
        porocila = apiResponseList;
        naslovPorocila = extractedTexts;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  //sprintaj na tiskalnik//////
  _prikaziPorocila(String naslovPorocila) async {
    String txtData = 'VrniPorocilo\t$naslovPorocila';

    print("Prepared txtData: '$txtData'");

    List<String> responsePorocilaList = await sendRequest('1', txtData);
    print("Response: $responsePorocilaList");

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
                    child: Container(
                      child: ListTile(
                        title: Text(naslovPorocila[index]),
                      ),
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
