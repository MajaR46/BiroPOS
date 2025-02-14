import 'package:intl/intl.dart';

class Item {
  final String id;
  final String name;
  final double price;
  double discountedPrice;
  final double hhPrice;
  final String categoryID;
  final String eanCode;

  static final numberFormat =
      NumberFormat("#,##0.00", "sl_SI"); // Slovenian format

  Item({
    this.id = '',
    this.name = 'Unknown Item',
    this.price = 0.0,
    this.discountedPrice = 0.0,
    this.hhPrice = 0.0,
    this.categoryID = '',
    this.eanCode = '',
  });

  factory Item.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic value) {
      return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0;
    }

    return Item(
      id: map['itemId'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown Item',
      price: parseDouble(map['price']),
      discountedPrice: parseDouble(map['discountedPrice']),
      hhPrice: parseDouble(map['HHprice']),
      categoryID: map['categoryID'] as String? ?? '',
      eanCode: map['eanCode'] as String? ?? '',
    );
  }

  String formattedPrice() => numberFormat.format(price);
  String formattedDiscountedPrice() => numberFormat.format(discountedPrice);
  String formattedHhPrice() => numberFormat.format(hhPrice);

  Item copyWith({
    String? id,
    String? name,
    double? price,
    double? discountedPrice,
    double? hhprice,
    String? categoryID,
    String? eanCode,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      hhPrice: hhPrice ?? this.hhPrice,
      categoryID: categoryID ?? this.categoryID,
      eanCode: eanCode ?? this.eanCode,
    );
  }
}
