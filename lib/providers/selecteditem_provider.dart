import 'package:BiroPOS/models/narociloitem.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedItemProvider = StateProvider<NarociloItem?>((ref) => null);

void clearSelectedItem(WidgetRef ref) {
  ref.read(selectedItemProvider.notifier).state = null;
}
