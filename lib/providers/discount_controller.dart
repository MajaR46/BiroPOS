import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final totalDiscountProvider = Provider<double>((ref) {
  final items = ref.watch(narociloNotifierProvider);

  double total = 0.0;

  for (final item in items) {
    final double originalPrice = item.product.price;
    final double discountedPrice = item.product.discountedPrice;

    if (discountedPrice > 0 && originalPrice > 0) {
      total += (originalPrice - discountedPrice) * item.quantity;
    }
  }

  return total;
});
