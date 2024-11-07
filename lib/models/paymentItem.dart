import 'package:biro_pos/models/item.dart';
import 'package:biro_pos/models/narociloitem.dart';

class PaymentItem extends NarociloItem {
  String userId;
  String table;
  String racunType;
  String paymentType;
  String davcna;

  PaymentItem({
    required this.userId,
    required this.table,
    required this.racunType,
    required this.paymentType,
    this.davcna = '',
    required Item product,
    double quantity = 1,
    double discount = 0.0,
    String description = '',
  }) : super(
          product: product,
          quantity: quantity,
          discount: discount,
          description: description,
        );
}
