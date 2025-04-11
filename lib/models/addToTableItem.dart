import 'package:BiroPOS/models/tableItem.dart';

class AddToTableItem extends TableItem {
  final String userID;
  final String tableNumber;
  final double discount;
  final String description;

  AddToTableItem({
    required String productCode,
    required double quantity,
    required double price,
    required String categoryCode,
    required this.userID,
    required this.tableNumber,
    required this.discount,
    required this.description,
  }) : super(
          productCode: productCode,
          quantity: quantity,
          price: price,
          categoryCode: categoryCode,
        );
}
