import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:biro_pos/models/nacinPlacila.dart';
import 'package:biro_pos/models/narociloitem.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final paymentMethodProvider = StateProvider<List<NacinPlacila>>((ref) => []);

final orderProvider = Provider<OrderService>((ref) {
  return OrderService(ref);
});

class OrderService {
  final Ref ref;

  OrderService(this.ref);

  // Method to handle data, calling API and categorizing payment methods
  Future<void> _handleData() async {
    List<String> apiResponseList = await sendRequest("1", "Biropos.txt");
    _kategorizirajNacinePlacila(apiResponseList);
  }

  // Method to categorize payment methods
  void _kategorizirajNacinePlacila(List<String> items) {
    List<NacinPlacila> naciniPlacila2 = [];
    for (String item in items) {
      if (item.startsWith('7')) {
        String kodaNacinaPlacila = item.split('|')[1];
        String nacinPlacila = item.split('|')[2];
        naciniPlacila2.add(NacinPlacila(kodaNacinaPlacila, nacinPlacila));
      }
    }
    // Update the provider with the new payment methods
    ref.read(paymentMethodProvider.notifier).state = naciniPlacila2;
  }

  Future<List<String>> createOrder(
    BuildContext context,
    String paymentMethodCode,
    String tableNumber,
    String orderType,
  ) async {
    // Get the logged-in user
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
    List<String> orderItems = chosenItems.map((item) {
      String productCode = item.product.id?.toString() ?? '';
      double quantity = item.quantity.toDouble();
      String categoryCode = item.product.categoryID.toString();

      double price =
          double.tryParse(item.product.price.toString().replaceAll(',', '.')) ??
              0.0;
      double discountedPrice = item.product.discountedPrice ?? price;

      double discount = (discountedPrice > 0 && price > 0)
          ? 100 - ((discountedPrice / price) * 100)
          : 0;

      String paymentCode = '';

      if (paymentMethodCode == "GOT") {
        paymentCode = paymentMethods[0].kodaNacinaPlacila;
      } else if (paymentMethodCode == "KAR") {
        paymentCode = paymentMethods[1].kodaNacinaPlacila;
      } else {
        paymentCode = paymentMethodCode;
      }

      return '$userId\t$tableNumber\t$productCode\t$quantity\t$price\t$discount\t$orderType;$paymentCode;;${item.description ?? ''};\t$categoryCode';
    }).toList();

    List<String> serverResponse =
        await sendRequest("1", orderItems.join('\r\n'));

    return serverResponse;
  }

  Future<void> initializePaymentMethods() async {
    await _handleData();
  }
}
