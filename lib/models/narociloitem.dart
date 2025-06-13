import 'package:BiroPOS/models/item.dart';
import 'package:uuid/uuid.dart'; // <-- Dodaj import

var _uuid = const Uuid(); // Instanca generatorja UUID

class NarociloItem {
  final String uniqueId; // <-- Dodaj unikatni ID
  final Item product;
  double quantity;
  double discount;
  String description;
  String davcnaSt;
  String tableNumber;
  final bool isFromTable;

  NarociloItem({
    required this.product,
    this.quantity = 1,
    this.discount = 0.0,
    this.description = '',
    this.davcnaSt = '',
    this.isFromTable = false,
    this.tableNumber = '',
    String? uniqueId, // <-- Opcijski parameter za copyWith
  }) : uniqueId = uniqueId ?? _uuid.v4(); // <-- Generiraj ID, če ni podan

  NarociloItem copyWith({
    Item? product,
    double? quantity,
    double? discount,
    String? description,
    String? davcnaSt,
    bool? isFromTable,
    String? tableNumber,
    double? price,
    String? uniqueId, // Cena se posodablja znotraj product.copyWith
  }) {
    return NarociloItem(
      uniqueId: this.uniqueId, // <-- PRENESI obstoječi ID
      product: product?.copyWith(price: price) ??
          this.product.copyWith(
              price: price ??
                  this.product.price), // Posodobi ceno izdelka, če je podana
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
      description: description ?? this.description,
      davcnaSt: davcnaSt ?? this.davcnaSt,
      isFromTable: isFromTable ?? this.isFromTable,
      tableNumber: tableNumber ?? this.tableNumber,
    );
  }

  // Metoda za primerjavo (lahko koristiš v Notifierju, če je potrebno)
  bool matchesProductAndDescription(NarociloItem other) {
    return product.id == other.product.id &&
        product.price == other.product.price &&
        description == other.description;
  }
}
