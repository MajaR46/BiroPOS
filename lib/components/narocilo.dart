import 'package:BiroPOS/controllers/print.dart';
import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/order_number_provider.dart';
import 'package:BiroPOS/utils/error_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class Narocilo {
  static int stNarocila = 1;

  static Future<bool> createNarocilo(
      WidgetRef ref, bool isFromTable, BuildContext context,
      [String? tableNumber]) async {
    List<String> narocilo = [];
    DateTime currentDate = DateTime.now();
    String formattedDate = DateFormat("dd.MM.yyyy").format(currentDate);
    String formattedTime = DateFormat("HH:mm").format(currentDate);
    String orderNumberTime = DateFormat("mmss").format(currentDate);
    final narociloItems = ref.read(narociloNotifierProvider);
    int orderNumber = ref.watch(orderNumberProvider);
    String? user = SessionManager().getLoggedInUserName();

    narocilo.add("NAROCILO");
    narocilo.add("Datum: $formattedDate  $formattedTime");

    if (isFromTable == true) {
      narocilo.add("Miza: $tableNumber");
    } else {
      narocilo.add("Stevilka: $orderNumberTime");
    }

    narocilo.add("Streze vas: $user");
    narocilo.add("                                ");

    narocilo.add("Naziv                       Kol.");
    narocilo.add("--------------------------------");

    for (var item in narociloItems) {
      String imeIzdelka = item.product.name;
      String kolicina = item.quantity.toStringAsFixed(2);

      String vrstica = imeIzdelka.padRight(24) + kolicina.padLeft(8);
      narocilo.add(vrstica);
      String opis = item.description;
      if (opis.isNotEmpty) narocilo.add(">> $opis");
      {}
    }

    narocilo.add("--------------------------------");

    ref.read(orderNumberProvider.notifier).setOrderNumber(orderNumber + 1);

    return NarociloPrinter().printajNarocilo(narocilo, context, ref);
  }
}

class NarociloPrinter {
  Future<bool> printajNarocilo(
      List<String> narocilo, BuildContext context, WidgetRef ref) async {
    try {
      print("Naroiclo $narocilo");
      await Print.printText(context, narocilo, ref);
      return true;
    } catch (e) {
      ErrorDialogs.showBasicDialog("Napaka pri tiskanju naročila $e", context);
      return false;
    }
  }
}
