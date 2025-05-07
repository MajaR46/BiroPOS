class TableItem {
  final String productCode;
  final String productName;
  final double quantity;
  final double price;
  final String categoryCode;
  final bool disabled;

  TableItem(
      {required this.productCode,
      this.productName = '',
      required this.quantity,
      required this.price,
      required this.categoryCode,
      this.disabled = false});

  TableItem copyWith({double? quantity, bool? disabled}) {
    return TableItem(
        productCode: productCode,
        productName: productName,
        quantity: quantity ?? this.quantity,
        price: price,
        categoryCode: categoryCode,
        disabled: disabled ?? this.disabled);
  }
}
