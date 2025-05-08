import 'dart:async';

import 'package:BiroPOS/components/ok_button.dart';
import 'package:BiroPOS/controllers/print.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:BiroPOS/app_styles.dart';
import 'package:BiroPOS/controllers/klic.dart';
import 'package:BiroPOS/providers/printednarocilo_provider.dart';

class PregledNarocilScreen extends ConsumerStatefulWidget {
  const PregledNarocilScreen({super.key});

  @override
  ConsumerState<PregledNarocilScreen> createState() =>
      _PregledNarocilScreenState();
}

class _PregledNarocilScreenState extends ConsumerState<PregledNarocilScreen> {
  List<String> naslovPorocila = [];
  List<String> narocila = [];
  late Timer _timer;
  int stMinut = 1;
  late String textSize = '';

  @override
  void initState() {
    super.initState();
    _refreshPage();
    _getPreferences();
  }

  Future<void> _getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      textSize = prefs.getString('velikostNarocila') ?? '';
    });
  }

  Future<void> _refreshPage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String osveziStMinut = prefs.getString('refreshInterval') ?? '';
    int parsedStMinut = int.tryParse(osveziStMinut) ?? 1;

    setState(() {
      stMinut = parsedStMinut;
    });
    _startTimer();
  }

  void _startTimer() {
    Duration duration = Duration(minutes: stMinut);
    _timer = Timer.periodic(duration, (Timer t) {
      if (mounted) {
        _handleData();
      } else {
        t.cancel();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      _handleData();
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> _handleData() async {
    if (!mounted) return; // Ensure widget is still active before proceeding
    final settings = ref.watch(settingsProvider);
    final prikazuNarocilTiskalnik =
        settings['isCheckedPregledNarocilTiskalnik'] ?? false;

    try {
      String? userId = SessionManager().getLoggedInUserSifra() ?? '';

      List<String> apiResponseList =
          await sendRequest(userId, "VrniOdprtaNarocila");

      String apiResponse = apiResponseList.join('\n');
      const String delimiter = '================================';

      List<String> splitOrders = apiResponse.split(delimiter);

      List<String> parts = splitOrders
          .where((order) => order.trim().isNotEmpty)
          .map((order) => "$delimiter\n${order.trim()}\n$delimiter")
          .toList();

      setState(() {
        narocila = parts;
      });

      final notifier = ref.read(printedNarocilaProvider.notifier);
      for (var order in parts) {
        final isPrinted = notifier.isPrinted(order);

        if (!isPrinted && prikazuNarocilTiskalnik) {
          await Print.printText(context, [order], ref);
          notifier.sprintanaNarocila(order);
        }
      }
    } catch (e, stackTrace) {
      debugPrint("Error fetching orders: $e\n$stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final narociloTextSize = double.tryParse(textSize) ?? 16.0;
    return Scaffold(
      backgroundColor: AppStyles.white,
      appBar: AppBar(
        backgroundColor: AppStyles.white,
        title: Text(
          "Naročila",
          style: AppStyles.heading3.copyWith(color: AppStyles.black),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppStyles.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          return Column(
            children: [
              Expanded(
                // Ensures ListView takes up available space
                child: ListView.builder(
                  itemCount: narocila.length,
                  itemBuilder: (context, index) {
                    final order = narocila[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            order,
                            style: TextStyle(
                                fontSize: narociloTextSize,
                                fontFamily: 'FiraMono'),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 32),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: OKButton(
                    onPressed: _handleData,
                    text: 'Osveži',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
