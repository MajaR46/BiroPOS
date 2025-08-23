// Provider for managing davcna (tax number)
import 'package:flutter_riverpod/flutter_riverpod.dart';

final taxNumberProvider = StateProvider<String?>((ref) => null);

final davcnaPodatkiProvider = StateProvider<Map<String, String>>((ref) => {});

// Function to set the tax number
void setTaxNumber(WidgetRef ref, String taxNumber) {
  ref.read(taxNumberProvider.notifier).state = taxNumber;
}

// Clear davcna using the taxNumberProvider
void clearDavcna(WidgetRef ref) {
  ref.read(taxNumberProvider.notifier).state = '';
}
