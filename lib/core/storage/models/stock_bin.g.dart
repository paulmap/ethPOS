// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_bin.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockBinAdapter extends TypeAdapter<StockBin> {
  @override
  final int typeId = 20;

  @override
  StockBin read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockBin(
      id: fields[0] as String,
      productId: fields[1] as String,
      area: fields[2] as String,
      bin: fields[3] as String,
      quantity: fields[4] as int,
      lastUpdated: fields[6] as DateTime,
      pickOrder: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, StockBin obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.area)
      ..writeByte(3)
      ..write(obj.bin)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.pickOrder)
      ..writeByte(6)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockBinAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
