// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'narociloitem.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NarociloItemAdapter extends TypeAdapter<NarociloItem> {
  @override
  final int typeId = 10;

  @override
  NarociloItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NarociloItem(
      product: fields[1] as Item,
      quantity: fields[2] as double,
      discount: fields[3] as double,
      description: fields[4] as String,
      davcnaSt: fields[5] as String,
      isFromTable: fields[7] as bool,
      tableNumber: fields[6] as String,
      uniqueId: fields[0] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NarociloItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.uniqueId)
      ..writeByte(1)
      ..write(obj.product)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.discount)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.davcnaSt)
      ..writeByte(6)
      ..write(obj.tableNumber)
      ..writeByte(7)
      ..write(obj.isFromTable);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarociloItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
