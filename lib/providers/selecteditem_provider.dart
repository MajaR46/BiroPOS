import 'package:BiroPOS/models/narociloitem.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final selectedItemProvider = StateProvider<NarociloItem?>((ref) => null);

void clearSelectedItem(WidgetRef ref) async {
  ref.read(selectedItemProvider.notifier).state = null;
}
