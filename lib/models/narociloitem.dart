import 'package:BiroPOS/models/item.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart'; // <-- Dodaj import

part 'narociloitem.g.dart';

var _uuid = const Uuid(); // Instanca generatorja UUID

@HiveType(typeId: 10)
class NarociloItem {
  @HiveField(0)
  final String uniqueId;
  @HiveField(1)
  final Item product;
  @HiveField(02)
  double quantity;
  @HiveField(3)
  double discount;
  @HiveField(4)
  String description;
  @HiveField(5)
  String davcnaSt;
  @HiveField(6)
  String tableNumber;
  @HiveField(7)
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
