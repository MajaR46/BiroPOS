import 'package:BiroPOS/components/narocilo.dart';
import 'package:BiroPOS/controllers/klic.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/controllers/table_controller.dart';
import 'package:BiroPOS/controllers/test_connection.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/selecteditem_provider.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:BiroPOS/providers/status_provider.dart';
import 'package:BiroPOS/providers/tableitem_provider.dart';
import 'package:BiroPOS/screens/blagajna_screen.dart';
import 'package:BiroPOS/screens/mize/new_table_screen.dart';
import 'package:flutter/material.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddToTableScreen extends ConsumerStatefulWidget {
  final String? prostor;
  const AddToTableScreen({super.key, this.prostor});

  static Map<String, double> tableSums = {};

  @override
  ConsumerState<AddToTableScreen> createState() => _AddToTableScreenState();
}

class _AddToTableScreenState extends ConsumerState<AddToTableScreen> {
  List<Map<String, String>> _tables = [];
  Map<String, List<String>> tableItems = {};
  bool _isOnline = true;
  String userId = SessionManager().getLoggedInUserSifra() ?? '';

  late List<dynamic> chosenItems;

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTables();
    Future.delayed(const Duration(seconds: 4), () {
      checkConnection();
    });
  }

  Future<void> _loadTables() async {
    setState(() {
      _isLoading = true;
    });

    List<Map<String, String>> tables = await TableService.fetchTables();
    List<Map<String, String>> filteredTables =
        tables.where((table) => table['prostor'] == widget.prostor).toList();

    setState(() {
      if (widget.prostor != null &&
          widget.prostor != '' &&
          widget.prostor != 'Miza') {
        _tables = filteredTables;
      } else {
        _tables = tables;
      }

      _isLoading = false;
    });
  }

  void addToExistingTable(String tableNumber) async {
    final tableNotifier = ref.read(tableNotifierProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final tiskajNarocilo = settings['isCheckedTiskajNarocilo'] ?? false;

    List<String> serverResponse =
        await tableNotifier.addToExistingTable(context, tableNumber);

    if (tiskajNarocilo == true) {
      await Narocilo.createNarocilo(ref, true, context, tableNumber);
    }
    ref.read(narociloNotifierProvider.notifier).clearChosenItems();
    var narociloBox = Hive.box('narociloBox');
    await narociloBox.clear();

    ref.read(tableNotifierProvider.notifier).state = [];
    clearSelectedItem(ref);
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
            title: Text(
              "Dodaj na mizo",
              style: AppStyles.heading3.copyWith(color: AppStyles.black),
            ),
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
                        itemCount: _tables.length,
                        itemBuilder: (context, index) {
                          final tableData = _tables[index];
                          String tableNumber = tableData['miza'] ?? '';
                          String prostor = tableData['prostor'] ?? '';

                          double tableFinalSum = tableData['cena'] != null
                              ? double.tryParse(tableData['cena'].toString()) ??
                                  0.0
                              : 0.0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 2),
                            child: GestureDetector(
                              onTap: () {
                                addToExistingTable(tableNumber);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const BlagajnaScreen()),
                                );
                                HapticFeedback.vibrate();

                                ;
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
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Miza $tableNumber',
                                            style: AppStyles.heading3,
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${tableFinalSum.toStringAsFixed(2)} €',
                                            style: AppStyles.heading3.copyWith(
                                                fontWeight: FontWeight.normal),
                                          ),
                                        ],
                                      ),
                                      if (prostor.isNotEmpty)
                                        Row(
                                          children: [
                                            if (prostor != "Miza")
                                              Expanded(
                                                  child: Align(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  prostor,
                                                  style: AppStyles.paragraph3,
                                                ),
                                              ))
                                          ],
                                        )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 24, top: 8),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    height: 50,
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () async {
                        String? newTableNumber = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const NewTableScreen(), // Pass items here
                          ),
                        );

                        if (newTableNumber != null &&
                            newTableNumber.isNotEmpty) {
                          addToExistingTable(newTableNumber);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.blue,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                      ),
                      child: Text(
                        "NOVA MIZA",
                        style:
                            AppStyles.button1.copyWith(color: AppStyles.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
