// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'osebje.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OsebjeAdapter extends TypeAdapter<Osebje> {
  @override
  final int typeId = 1;

  @override
  Osebje read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Osebje(
      fields[0] as String,
      fields[1] as String,
      fields[2] as String,
      fields[3] as String?,
      fields[4] as String?,
      fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Osebje obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.username)
      ..writeByte(1)
      ..write(obj.password)
      ..writeByte(2)
      ..write(obj.sifra)
      ..writeByte(3)
      ..write(obj.pravicaPregledPorocil)
      ..writeByte(4)
      ..write(obj.pregledSamoSvojihDokumentov)
      ..writeByte(5)
      ..write(obj.pravicaStornoProdaja);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OsebjeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
