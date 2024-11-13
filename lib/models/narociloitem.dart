import 'package:biro_pos/models/item.dart';

class NarociloItem {
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
  });

  // The updated copyWith method
  NarociloItem copyWith(
      {Item? product, // Add product as a nullable parameter
      double? quantity,
      double? discount,
      String? description,
      String? davcnaSt,
      bool? isFromTable,
      String? tableNumber}) {
    return NarociloItem(
        product: product ??
            this.product, // Use provided product or fallback to current product
        quantity: quantity ?? this.quantity,
        discount: discount ?? this.discount,
        description: description ?? this.description,
        davcnaSt: davcnaSt ?? this.davcnaSt,
        isFromTable: isFromTable ?? this.isFromTable,
        tableNumber: tableNumber ?? this.tableNumber);
  }
}
