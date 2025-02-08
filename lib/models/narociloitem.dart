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
  NarociloItem copyWith({
    Item? product,
    double? quantity,
    double? discount,
    String? description,
    String? davcnaSt,
    bool? isFromTable,
    String? tableNumber,
    double? price, // Adding the price parameter here
  }) {
    return NarociloItem(
      product: product?.copyWith(price: price) ??
          this.product, // Update product's price if passed
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
      description: description ?? this.description,
      davcnaSt: davcnaSt ?? this.davcnaSt,
      isFromTable: isFromTable ?? this.isFromTable,
      tableNumber: tableNumber ?? this.tableNumber,
    );
  }
}
