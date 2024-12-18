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
    );
  }

  @override
  void write(BinaryWriter writer, Osebje obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.username)
      ..writeByte(1)
      ..write(obj.password)
      ..writeByte(2)
      ..write(obj.sifra);
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
