import 'package:BiroPOS/controllers/klic.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/models/tableItem.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

    final numberFormat = NumberFormat("#,##0.00", "sl_SI"); // Slovenian locale

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user logged in!")),
      );
      return [];
    }

    final chosenItems = ref.watch(narociloNotifierProvider);

    List<String> tableItems = chosenItems.map((item) {
      String productCode = item.product.id.toString();
      String quantity = numberFormat.format(item.quantity); // Use formatter

      String price = numberFormat.format(item.product.price); // Use formatter

      double itemDiscountedPrice = item.product.discountedPrice > 0
          ? item.product.discountedPrice
          : double.tryParse(item.product.price.toString()) ?? 0.0;

      num discountRaw = (itemDiscountedPrice != 0)
          ? ((1 -
                  (itemDiscountedPrice /
                      double.parse(item.product.price.toString()))) *
              100)
          : 0;

      String discount = numberFormat.format(discountRaw);

      String opis = item.description;
      String artikelSkupina = item.product.categoryID.toString();
      print(
          '$userId\t$tableNumber\t$productCode\t$quantity\t$price\t$discount\t$opis\t$artikelSkupina');

      return '$userId\t$tableNumber\t$productCode\t$quantity\t$price\t$discount\t$opis\t$artikelSkupina';
    }).toList();
    print(tableItems);

    List<String> serverResponse =
        await sendRequest(userId, tableItems.join('\r\n'));

    return serverResponse;
  }

  void clearTable() {
    state = [];
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
    final numberFormat = NumberFormat("#,##0.00", "sl_SI"); // Slovenian locale

    final chosenItems = ref.watch(narociloNotifierProvider);

    List<String> tableItems = chosenItems.map((item) {
      String productCode = item.product.id.toString();
      String quantitiy = numberFormat.format(item.quantity); // Use formatter
      String price = numberFormat.format(item.product.price); // Use formatter

      double itemDiscountedPrice = item.product.discountedPrice > 0
          ? item.product.discountedPrice
          : double.tryParse(item.product.price.toString()) ?? 0.0;

      num discountRaw = (itemDiscountedPrice != 0)
          ? ((1 -
                  (itemDiscountedPrice /
                      double.parse(item.product.price.toString()))) *
              100)
          : 0;

      String discount = numberFormat.format(discountRaw);

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
