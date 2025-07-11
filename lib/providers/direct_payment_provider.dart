import 'package:BiroPOS/controllers/klic.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/models/nacinPlacila.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/searchquery_provider.dart';
import 'package:BiroPOS/providers/selecteditem_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

final paymentMethodProvider = StateProvider<List<NacinPlacila>>((ref) => []);

final orderProvider = Provider<OrderService>((ref) {
  return OrderService(ref);
});

class OrderService {
  final Ref ref;
  bool isLoading = true;
  bool hasError = false;

  OrderService(this.ref);

  Future<void> _handleData() async {
    try {
      final box = Hive.box('biroposData');
      List<String> apiResponseList =
          List<String>.from(box.get('biroPosData', defaultValue: []));
      _kategorizirajNacinePlacila(apiResponseList);

      if (apiResponseList.isEmpty) {
        return;
      }
    } catch (e) {}
  }

  void _kategorizirajNacinePlacila(List<String> items) {
    List<NacinPlacila> naciniPlacila2 = [];
    for (String item in items) {
      if (item.startsWith('7')) {
        String kodaNacinaPlacila = item.split('|')[1];
        String nacinPlacila = item.split('|')[2];
        naciniPlacila2.add(NacinPlacila(kodaNacinaPlacila, nacinPlacila));
      }
    }

    ref.read(paymentMethodProvider.notifier).state = naciniPlacila2;
  }

  Future<List<String>> createOrder(
    BuildContext context,
    WidgetRef ref,
    String paymentMethodCode, [
    String? davcnaSt,
  ]) async {
    try {
      String? userId = SessionManager().getLoggedInUserSifra();
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No user logged in!")),
        );
        return [];
      }

      final paymentMethods = ref.watch(paymentMethodProvider);

      if (paymentMethods.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No payment methods available!")),
        );
        return [];
      }

      final chosenItems = ref.watch(narociloNotifierProvider);
      final numberFormat = NumberFormat("#,##0.00", "sl_SI");

      List<String> tableOrderItems = [];
      List<String> directOrderItems = [];
      bool hasDirectItems = false;

      for (var item in chosenItems) {
        String productCode = item.product.id.toString();
        String quantity = numberFormat.format(item.quantity);
        String categoryCode = item.product.categoryID.toString();
        String price = numberFormat.format(item.product.price);

        double discountedPrice = item.product.discountedPrice;

        num discountRaw = (discountedPrice != 0)
            ? ((1 -
                    (discountedPrice /
                        double.parse(item.product.price.toString()))) *
                100)
            : 0;

        String discount = numberFormat.format(discountRaw);
        String paymentCode = '';
        String taxNumber = davcnaSt ?? '';

        // Determine payment code based on the payment method code
        if (paymentMethodCode == "GOT") {
          paymentCode = paymentMethods[0].kodaNacinaPlacila;
        } else if (paymentMethodCode == "KAR") {
          paymentCode = paymentMethods[1].kodaNacinaPlacila;
        } else {
          paymentCode = paymentMethodCode;
        }

        // Set table number
        String tableNumber =
            item.tableNumber.isEmpty ? '#MIZA#' : item.tableNumber;

        // Determine if the item is a direct addition to the bill
        if (!item.isFromTable) {
          hasDirectItems = true;
          directOrderItems.add(
            '$userId\t$tableNumber\t$productCode\t$quantity\t$price\t$discount\tDIREKTENRACUN;$paymentCode;$taxNumber;${item.description};\t$categoryCode',
          );
        } else {
          tableOrderItems.add(
            '$userId\t$tableNumber\t$productCode\t$quantity\t$price\t$discount\tRACUN;$paymentCode;$taxNumber;${item.description};\t$categoryCode',
          );
        }
      }

      if (hasDirectItems) {
        tableOrderItems = tableOrderItems
            .map((item) => item.replaceFirst('RACUN', 'ZAPRIMIZO'))
            .toList();
      }

      List<String> allOrderItems = [...tableOrderItems, ...directOrderItems];

      List<String> serverResponse =
          await sendRequest(userId, allOrderItems.join('\r\n'));

      if (serverResponse.any((line) => line.contains("#NAPAKA#"))) {
        return ["Napaka pri ustvarjanju računa $serverResponse"];
      }
      ref.watch(narociloNotifierProvider.notifier).clearChosenItems();
      clearSelectedItem(ref);
      clearSearchQuery(ref);

      return serverResponse;
    } catch (e, stackTrace) {
      // Izpiši napako v konzolo in prikaži uporabniku obvestilo
      debugPrint('Napaka pri ustvarjanju naročila: $e');
      debugPrint(stackTrace.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Prišlo je do napake pri oddaji naročila.")),
      );
      return [];
    }
  }

  Future<void> initializePaymentMethods() async {
    await _handleData();
  }
}
