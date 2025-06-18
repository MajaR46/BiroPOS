// Provider, ki hrani faktor za množenje, ko čakamo na vnos ID/EAN kode.
import 'package:flutter_riverpod/flutter_riverpod.dart';

final multiplyFactorProvider = StateProvider<double?>((ref) => null);
