import 'package:hive/hive.dart';

part 'osebje.g.dart'; // Auto-generated file for the adapter

@HiveType(typeId: 4)
class Osebje {
  @HiveField(0)
  final String username;

  @HiveField(1)
  final String password;

  @HiveField(2)
  final String sifra;
  @HiveField(3)
  final String? pravicaPregledPorocil;
  @HiveField(4)
  final String? pregledSamoSvojihDokumentov;
  @HiveField(5)
  final String? pravicaStornoProdaja;

  Osebje(this.username, this.password, this.sifra, this.pravicaPregledPorocil,
      this.pregledSamoSvojihDokumentov, this.pravicaStornoProdaja);
}
