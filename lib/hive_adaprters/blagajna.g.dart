// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blagajna.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BlagajnaAdapter extends TypeAdapter<Blagajna> {
  @override
  final int typeId = 3;

  @override
  Blagajna read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Blagajna(
      fields[0] as String,
      fields[1] as String,
      fields[2] as String,
      fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Blagajna obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.vprasajZaCeno)
      ..writeByte(1)
      ..write(obj.zakljuciRacunPriEnemRacunu)
      ..writeByte(2)
      ..write(obj.izbirajNacinePlacil)
      ..writeByte(3)
      ..write(obj.tiskajNarocilo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlagajnaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
