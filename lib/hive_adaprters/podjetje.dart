import 'package:hive/hive.dart';

part 'podjetje.g.dart';

@HiveType(typeId: 2)
class Podjetje {
  @HiveField(0)
  final String davcna;

  @HiveField(1)
  final String ime;

  Podjetje(this.davcna, this.ime);
}
