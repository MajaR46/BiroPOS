import 'package:BiroPOS/components/ok_button.dart';
import 'package:BiroPOS/controllers/klic.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/controllers/test_connection.dart';
import 'package:BiroPOS/providers/status_provider.dart';
import 'package:BiroPOS/screens/blagajna_screen.dart';
import 'package:BiroPOS/screens/mize/miza_details_screen.dart';
import 'package:BiroPOS/utils/error_dialog.dart';
import 'package:flutter/material.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpenTablesScreen extends ConsumerStatefulWidget {
  final String? prostor;
  const OpenTablesScreen({super.key, this.prostor});

  @override
  ConsumerState<OpenTablesScreen> createState() => _OpenTablesScreenState();
}

class _OpenTablesScreenState extends ConsumerState<OpenTablesScreen> {
  List<Map<String, String>> odprteMize = [];
  int? _selectedCardIndex; // Track selected card index

  bool _isLoading = true;
  bool _isOnline = true;
  String userId = SessionManager().getLoggedInUserSifra() ?? '';

  @override
  void initState() {
    super.initState();
    _fetchOpenTables();
    Future.delayed(const Duration(seconds: 4), () {
      checkConnection();
    });
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
        String prostor = parts[0];
        String imeMize = parts[1];
        String znesek = parts[2].replaceAll(',', '.');
        String user = parts[3];

        mize.add({
          'prostor': prostor,
          'imeMize': imeMize,
          'znesek': znesek.isNotEmpty ? znesek : '',
          'user': user
        });

        List<Map<String, String>> filteredTables =
            mize.where((table) => table['prostor'] == widget.prostor).toList();

        setState(() {
          if (prostor != '' && prostor != 'Miza') {
            odprteMize = filteredTables;
          } else if (prostor == "Miza") {
            odprteMize = mize;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = true;
      });
      ErrorDialogs.showBasicDialog("Ni vzpostavljene povezave", context);
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

  void checkConnection() async {
    print("izvedeno");
    bool isOnline = await testConnection(userId);
    if (mounted) {
      ref.read(onlineStatusProvider.notifier).state = isOnline;
    }
  }

  @override
  Widget build(BuildContext context) {
    _isOnline = ref.watch(onlineStatusProvider);
    return Scaffold(
        backgroundColor: AppStyles.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: GestureDetector(
            onTap: checkConnection,
            child: AppBar(
              backgroundColor: AppStyles.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppStyles.black),
                onPressed: () {
                  if (widget.prostor?.isEmpty ?? true) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const BlagajnaScreen()));
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
              title: Text("Odprte mize",
                  style: AppStyles.heading3.copyWith(color: AppStyles.black)),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 24.0),
                  child: Text(
                    _isOnline ? "Online" : "Offline",
                    style: AppStyles.paragraph3.copyWith(
                      color: _isOnline ? AppStyles.green : AppStyles.brightRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
          ),
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
                              String prostor = tableData['prostor'] ?? '';
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
                                          HapticFeedback.vibrate();
                                        });
                                      },
                                      child: Card(
                                        color: AppStyles.silver
                                            .withAlpha((0.1 * 255).round()),
                                        elevation: 0,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              // Prva vrstica: Miza (levo) - Znesek (desno)
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Miza $oznakaMize',
                                                    style: AppStyles.heading3,
                                                  ),
                                                  Text(
                                                    '${znesek.toStringAsFixed(2)}€',
                                                    style: AppStyles.heading3
                                                        .copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  // Prva tretjina (User - levo poravnano)
                                                  Expanded(
                                                    child: Text(
                                                      user,
                                                      style:
                                                          AppStyles.paragraph3,
                                                    ),
                                                  ),
                                                  // Druga tretjina (Test - centrirano)
                                                  if (prostor != "Miza")
                                                    Expanded(
                                                      child: Align(
                                                        alignment:
                                                            Alignment.center,
                                                        child: Text(
                                                          prostor,
                                                          style: AppStyles
                                                              .paragraph3,
                                                        ),
                                                      ),
                                                    ),
                                                  // Tretja tretjina (prazna)
                                                  const Expanded(
                                                      child: SizedBox()),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      )));
                            })),
              ],
            )
          ],
        ));
  }
}
