// providers/total_sum_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biro_pos/providers/narociloitem_provider.dart';

final totalSumProvider = StateProvider<double>((ref) {
  return ref.watch(narociloNotifierProvider.notifier).totalSum();
});
