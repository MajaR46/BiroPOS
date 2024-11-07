class TableItem {
  final String productCode;
  final String productName;
  final double quantity;
  final double price;
  final String categoryCode;

  TableItem({
    required this.productCode,
    this.productName = '',
    required this.quantity,
    required this.price,
    required this.categoryCode,
  });

  TableItem copyWith({double? quantity}) {
    return TableItem(
      productCode: productCode,
      productName: productName,
      quantity: quantity ?? this.quantity,
      price: price,
      categoryCode: categoryCode,
    );
  }
}
