import 'package:biro_pos/controllers/print.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:biro_pos/app_styles.dart';
import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/providers/printednarocilo_provider.dart';

class PregledNarocilScreen extends ConsumerStatefulWidget {
  const PregledNarocilScreen({super.key});

  @override
  ConsumerState<PregledNarocilScreen> createState() =>
      _PregledNarocilScreenState();
}

class _PregledNarocilScreenState extends ConsumerState<PregledNarocilScreen> {
  List<String> naslovPorocila = [];
  List<String> narocila = [];

  @override
  void initState() {
    super.initState();
    _handleData();
  }

  Future<void> _handleData() async {
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

        if (!isPrinted) {
          await Print.printText(context, order, "PrinterName", ref);
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
          return ListView.builder(
            itemCount: narocila.length,
            itemBuilder: (context, index) {
              final order = narocila[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white, // Default background color
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      order,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
