class Item {
  final String id;
  final String name;
  final double price;
  double discountedPrice;
  final double hhPrice;
  final String categoryID;
  final String eanCode;

  // Constructor with optional named parameters and default values
  Item({
    this.id = '',
    this.name = 'Unknown Item',
    this.price = 0.0,
    this.discountedPrice = 0.0,
    this.hhPrice = 0.0,
    this.categoryID = '',
    this.eanCode = '',
  });

  // Factory constructor to create an Item from a map
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['itemId'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown Item',
      price: double.tryParse(map['price'].toString().replaceAll(',', '.')) ?? 0,
      discountedPrice: double.tryParse(
              map['discountedPrice'].toString().replaceAll(',', '.')) ??
          0,
      hhPrice:
          double.tryParse(map['HHprice'].toString().replaceAll(',', '.')) ?? 0,
      categoryID: map['categoryID'] as String? ?? '',
      eanCode: map['eanCode'] as String? ?? '',
    );
  }

  // CopyWith method for creating a modified copy of an Item
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
