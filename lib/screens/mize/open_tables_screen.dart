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
  bool _isLoading = true;
  List<Map<String, String>> odprteMize = [];
  int? _selectedCardIndex; // Track selected card index

  @override
  void initState() {
    super.initState();
    _fetchOpenTables();
  }

  Future<void> _fetchOpenTables() async {
    setState(() {
      _isLoading = true;
    });

    String? userId = SessionManager().getLoggedInUserSifra();

    try {
      String txtData = 'VrniOdprteMize\t$userId';
      List<String> apiResponseList = await sendRequest(userId!, txtData);

      List<Map<String, String>> mize = [];

      for (String line in apiResponseList) {
        String imeMize = line.split('|')[1];
        String znesek = line.split('|')[2].replaceAll(',', '.');
        String user = line.split('|')[3];

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
        _isLoading = false;
      });
    }
  }

  void _povecajKolicino() {
    if (_selectedCardIndex != null) {
      final selectedCard = odprteMize[_selectedCardIndex!];
    }
  }

  void _ok() {
    if (_selectedCardIndex != null) {
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
        appBar: AppBar(
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
                                    horizontal: 16, vertical: 2),
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
                                        children: [
                                          Text(
                                            'Miza $oznakaMize',
                                            style: AppStyles.heading3,
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${znesek.toStringAsFixed(2)}€',
                                            style: AppStyles.heading3.copyWith(
                                                fontWeight: FontWeight.normal),
                                          ),
                                          const Spacer(),
                                          Text(
                                            user,
                                            style: AppStyles.paragraph3,
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
