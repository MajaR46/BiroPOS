import 'package:biro_pos/models/narociloitem.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define a StateProvider to hold the selected product
final selectedItemProvider = StateProvider<NarociloItem?>((ref) => null);
