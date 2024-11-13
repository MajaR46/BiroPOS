import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:biro_pos/models/tableItem.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TableNotifier extends Notifier<List<TableItem>> {
  @override
  List<TableItem> build() {
    return [];
  }

  void addToTable(TableItem tableItem) {
    final existingItemIndex =
        state.indexWhere((item) => item.productCode == tableItem.productCode);

    if (existingItemIndex != -1) {
      // If the item already exists, update its quantity and trigger rebuild
      state = [
        ...state.sublist(0, existingItemIndex),
        state[existingItemIndex].copyWith(
          quantity: state[existingItemIndex].quantity + tableItem.quantity,
        ),
        ...state.sublist(existingItemIndex + 1)
      ];
    } else {
      // If the item doesn't exist, add it to the state
      state = [...state, tableItem];
    }
  }

  Future<List<String>> addToExistingTable(
      BuildContext context, String tableNumber) async {
    String? userId = SessionManager().getLoggedInUserSifra();

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user logged in!")),
      );
      return [];
    }

    final chosenItems = ref.watch(narociloNotifierProvider);
    print("Chosen items: $chosenItems"); // Add this line to debug

    List<String> tableItems = chosenItems.map((item) {
      String productCode = item.product.id?.toString() ?? '';
      double quantitiy = item.quantity.toDouble();
      double price =
          double.tryParse(item.product.price.toString().replaceAll(',', '.')) ??
              0.0;

      double itemDiscountedPrice = item.product.discountedPrice > 0
          ? item.product.discountedPrice
          : price;

      num discount =
          (price != 0) ? ((1 - (itemDiscountedPrice / price)) * 100) : 0;

      String opis = item.description;
      String artikelSkupina = item.product.categoryID.toString();

      return '$userId\t$tableNumber\t$productCode\t$quantitiy\t$price\t$discount\t$opis\t$artikelSkupina';
    }).toList();

    List<String> serverResponse =
        await sendRequest(userId, tableItems.join('\r\n'));

    return serverResponse;
  }

  Future<List<String>> transferFromTable(
      BuildContext context, String tableNumber, String newTableNumber) async {
    String? userId = SessionManager().getLoggedInUserSifra();

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user logged in!")),
      );
      return [];
    }

    final chosenItems = ref.watch(narociloNotifierProvider);
    print("Chosen items: $chosenItems"); // Add this line to debug

    List<String> tableItems = chosenItems.map((item) {
      String productCode = item.product.id?.toString() ?? '';
      double quantitiy = item.quantity.toDouble();
      double price =
          double.tryParse(item.product.price.toString().replaceAll(',', '.')) ??
              0.0;

      double itemDiscountedPrice = item.product.discountedPrice > 0
          ? item.product.discountedPrice
          : price;

      num discount =
          (price != 0) ? ((1 - (itemDiscountedPrice / price)) * 100) : 0;

      String opis = item.description;
      String artikelSkupina = item.product.categoryID.toString();

      return '$userId\t$tableNumber#PrenosMedMizami#$newTableNumber\t$productCode\t$quantitiy\t$price\t$discount\t$opis\t$artikelSkupina';
    }).toList();

    List<String> serverResponse =
        await sendRequest(userId, tableItems.join('\r\n'));

    return serverResponse;
  }
}

final tableNotifierProvider =
    NotifierProvider<TableNotifier, List<TableItem>>(TableNotifier.new);
