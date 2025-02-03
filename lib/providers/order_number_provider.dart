// Create a provider for order number
import 'package:flutter_riverpod/flutter_riverpod.dart';

final orderNumberProvider = StateProvider<int>((ref) => 1);
