import 'package:hive/hive.dart';
part 'blagajna.g.dart'; // Auto-generated file for the adapter

@HiveType(typeId: 3)
class Blagajna {
  @HiveField(0)
  final String vprasajZaCeno;

  @HiveField(1)
  final String zakljuciRacunPriEnemRacunu;

  @HiveField(2)
  final String izbirajNacinePlacil;

  @HiveField(3)
  final String tiskajNarocilo;

  Blagajna(this.vprasajZaCeno, this.zakljuciRacunPriEnemRacunu,
      this.izbirajNacinePlacil, this.tiskajNarocilo);
}
