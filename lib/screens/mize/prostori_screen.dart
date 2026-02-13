import 'package:BiroPOS/app_styles.dart';
import 'package:BiroPOS/controllers/klic.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/controllers/test_connection.dart';
import 'package:BiroPOS/providers/status_provider.dart';
import 'package:BiroPOS/screens/blagajna_screen.dart';
import 'package:BiroPOS/screens/mize/add_to_table_screen.dart';
import 'package:BiroPOS/screens/mize/open_tables_screen.dart';
import 'package:BiroPOS/screens/porocila_screen.dart';
import 'package:BiroPOS/utils/error_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProstoriScreen extends ConsumerStatefulWidget {
  final String whereTo;
  final bool popThreeTimes;

  const ProstoriScreen(
      {required this.whereTo, super.key, this.popThreeTimes = false});

  @override
  ConsumerState<ProstoriScreen> createState() => _ProstoriScreenState();
}

class _ProstoriScreenState extends ConsumerState<ProstoriScreen> {
  List<Map<String, String>> tables = [];
  Map<String, List<String>> tableItems = {};
  List<String> uniqueSpacesList = [];

  bool _isOnline = true;
  String userId = SessionManager().getLoggedInUserSifra() ?? '';

  late List<dynamic> chosenItems;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTables();
    /*
    Future.delayed(const Duration(seconds: 4), () {
      checkConnection();
    });
    */
  }

  Future<void> _fetchTables() async {
    setState(() {
      _isLoading = false;
      _errorMessage = '';
    });

    try {
      String? userId = SessionManager().getLoggedInUserSifra();

      String txtData = 'VrniSeznamMiz';
      List<String> apiResponseList = await sendRequest(userId!, txtData);

      List<Map<String, String>> parsedTables = [];

      for (String line in apiResponseList) {
        List<String> splitLine = line.split('|');

        if (splitLine.length >= 4) {
          String prostor = splitLine[0];
          String miza = splitLine[1];
          String cena = splitLine[2].replaceAll(',', '.');

          parsedTables.add({
            'miza': miza,
            'prostor': prostor,
            'cena': cena.isNotEmpty ? cena : '',
          });
        }
      }

      Set<String> uniqueProstori = parsedTables
          .map((table) => table['prostor'] ?? '')
          .where((space) => space.isNotEmpty)
          .toSet();

      setState(() {
        tables = parsedTables;
        uniqueSpacesList = uniqueProstori.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Napaka pri pridobivanju podatkov: $e';
      });

      ErrorDialogs.showBasicDialog("Ni vzpostavljene povezave", context);
    }
  }

  void checkConnection() async {
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
          //onTap: checkConnection,
          child: AppBar(
            backgroundColor: AppStyles.white,
            leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppStyles.black,
                )),
            title: Text(
              "Prostori",
              style: AppStyles.heading3.copyWith(color: AppStyles.black),
            ),
            centerTitle: true,
            /*
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
            */
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
                          itemCount: uniqueSpacesList.length,
                          itemBuilder: (context, index) {
                            final tableData = tables[index];
                            String tableNumber = tableData['miza'] ?? '';
                            String prostor = uniqueSpacesList[index];

                            double tableFinalSum = tableData['cena'] != null
                                ? double.tryParse(
                                        tableData['cena'].toString()) ??
                                    0.0
                                : 0.0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 2),
                              child: GestureDetector(
                                onTap: () {
                                  if (widget.whereTo == "DodajNaMizo") {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                AddToTableScreen(
                                                  prostor: prostor,
                                                  popThreeTimes:
                                                      widget.popThreeTimes,
                                                )));
                                  } else if (widget.whereTo ==
                                      "VrniPrazneMize") {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                OpenTablesScreen(
                                                    prostor: prostor,
                                                    popThreeTimes:
                                                        widget.popThreeTimes)));
                                  }
                                  HapticFeedback.vibrate();
                                },
                                child: Card(
                                  color: AppStyles.silver
                                      .withAlpha((0.1 * 255).round()),
                                  elevation: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 24),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          prostor,
                                          style: AppStyles.heading3,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ))
            ],
          )
        ],
      ),
    );
  }
}
