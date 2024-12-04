import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:biro_pos/models/nacinPlacila.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> apiResponseList =
          (prefs.getStringList('biropos_data') ?? []);
      _kategorizirajNacinePlacila(apiResponseList);

      if (apiResponseList.isEmpty) {
        return;
      }
    } catch (e) {
      print("error loading data $e");
    }
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
    String paymentMethodCode, [
    String? davcnaSt,
  ]) async {
    String? userId = SessionManager().getLoggedInUserSifra();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user logged in!")),
      );
      return [];
    }

    // Get payment methods from the provider
    final paymentMethods = ref.watch(paymentMethodProvider);

    // Check if payment methods are loaded
    if (paymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No payment methods available!")),
      );
      return [];
    }

    final chosenItems = ref.watch(narociloNotifierProvider);

    // Initialize lists to separate table and direct billing items
    List<String> tableOrderItems = [];
    List<String> directOrderItems = [];
    bool hasDirectItems = false; // Flag for new direct items

    for (var item in chosenItems) {
      String productCode = item.product.id.toString();
      double quantity = item.quantity.toDouble();
      String categoryCode = item.product.categoryID.toString();
      double price =
          double.tryParse(item.product.price.toString().replaceAll(',', '.')) ??
              0.0;
      double discountedPrice = item.product.discountedPrice;

      double discount = (discountedPrice > 0 && price > 0)
          ? 100 - ((discountedPrice / price) * 100)
          : 0;

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
        hasDirectItems = true; // Mark that we have new items
        directOrderItems.add(
            '$userId\t$tableNumber\t$productCode\t$quantity\t$price\t$discount\tDIREKTENRACUN;$paymentCode;$taxNumber;${item.description};\t$categoryCode');
      } else {
        // Initially mark table items as RACUN, will switch to ZAPRIMIZO if there are new items
        tableOrderItems.add(
            '$userId\t$tableNumber\t$productCode\t$quantity\t$price\t$discount\tRACUN;$paymentCode;$taxNumber;${item.description};\t$categoryCode');
      }
    }

    // If there are direct items, change all table items from RACUN to ZAPRIMIZO
    if (hasDirectItems) {
      tableOrderItems = tableOrderItems
          .map((item) => item.replaceFirst('RACUN', 'ZAPRIMIZO'))
          .toList();
    }

    // Combine table and direct items
    List<String> allOrderItems = [...tableOrderItems, ...directOrderItems];

    // Send the request to the server
    List<String> serverResponse =
        await sendRequest(userId, allOrderItems.join('\r\n'));

    return serverResponse;
  }

  Future<void> initializePaymentMethods() async {
    await _handleData();
  }
}
