import 'package:hive/hive.dart';

part 'osebje.g.dart'; // Auto-generated file for the adapter

@HiveType(typeId: 1)
class Osebje {
  @HiveField(0)
  final String username;

  @HiveField(1)
  final String password;

  @HiveField(2)
  final String sifra;

  Osebje(this.username, this.password, this.sifra);
}
