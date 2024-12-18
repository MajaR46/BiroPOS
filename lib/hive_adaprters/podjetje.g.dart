// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'podjetje.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PodjetjeAdapter extends TypeAdapter<Podjetje> {
  @override
  final int typeId = 2;

  @override
  Podjetje read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Podjetje(
      fields[0] as String,
      fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Podjetje obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.davcna)
      ..writeByte(1)
      ..write(obj.ime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PodjetjeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
