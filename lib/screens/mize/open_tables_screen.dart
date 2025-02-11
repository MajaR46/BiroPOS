import 'package:biro_pos/components/ok_button.dart';
import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:biro_pos/screens/mize/miza_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpenTablesScreen extends StatefulWidget {
  const OpenTablesScreen({super.key});

  @override
  State<OpenTablesScreen> createState() => _OpenTablesScreenState();
}

class _OpenTablesScreenState extends State<OpenTablesScreen> {
  List<Map<String, String>> odprteMize = [];
  int? _selectedCardIndex; // Track selected card index

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOpenTables();
  }

  Future<void> _fetchOpenTables() async {
    setState(() {
      _isLoading = false;
    });

    String? userId = SessionManager().getLoggedInUserSifra();

    try {
      String txtData = 'VrniOdprteMize\t$userId';

      List<String> apiResponseList = await sendRequest(userId!, txtData);

      List<Map<String, String>> mize = [];

      for (String line in apiResponseList) {
        List<String> parts = line.split('|');
        if (parts.length < 4) continue;
        String imeMize = parts[1];
        String znesek = parts[2].replaceAll(',', '.');
        String user = parts[3];

        mize.add({
          'imeMize': imeMize,
          'znesek': znesek.isNotEmpty ? znesek : '',
          'user': user
        });

        setState(() {
          odprteMize = mize;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = true;
      });
      print("error $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ni vzpostavljene povezave")),
      );
    }
  }

  void _povecajKolicino() {
    if (_selectedCardIndex != null) {
      final selectedCard = odprteMize[_selectedCardIndex!];
    }
  }

  void _ok() {
    if (_selectedCardIndex != null && odprteMize.isNotEmpty) {
      final selectedCard = odprteMize[_selectedCardIndex!];
      final imeMize = selectedCard['imeMize'];

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MizaDetailsScreen(imeMize: imeMize!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppStyles.white,
        appBar: AppBar(
          backgroundColor: AppStyles.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppStyles.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text("Odprte mize",
              style: AppStyles.heading3.copyWith(color: AppStyles.black)),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: odprteMize.length,
                            itemBuilder: (context, index) {
                              final tableData = odprteMize[index];
                              String oznakaMize = tableData['imeMize'] ?? '';
                              double znesek = tableData['znesek'] != null
                                  ? double.tryParse(
                                          tableData['znesek'].toString()) ??
                                      0.0
                                  : 0.0;
                              String user = tableData['user'] ?? '';

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCardIndex = index;
                                      _ok();
                                    });
                                  },
                                  child: Card(
                                    color: AppStyles.silver.withOpacity(0.1),
                                    elevation: 0,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 24),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Miza $oznakaMize',
                                                style: AppStyles.heading3,
                                              ),
                                            ],
                                          ),
                                          Flexible(
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                  maxWidth:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          1 /
                                                          3),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '${znesek.toStringAsFixed(2)}€',
                                                    style: AppStyles.heading3
                                                        .copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                user,
                                                style: AppStyles.paragraph3,
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            })),
              ],
            )
          ],
        ));
  }
}
