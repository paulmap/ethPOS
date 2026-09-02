// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serial_unit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SerialUnitAdapter extends TypeAdapter<SerialUnit> {
  @override
  final int typeId = 21;

  @override
  SerialUnit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SerialUnit(
      id: fields[0] as String,
      productId: fields[1] as String,
      serial: fields[2] as String,
      soldAt: fields[3] as DateTime?,
      saleId: fields[4] as String?,
      customerId: fields[5] as String?,
      warrantyEnds: fields[6] as DateTime?,
      binId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SerialUnit obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.serial)
      ..writeByte(3)
      ..write(obj.soldAt)
      ..writeByte(4)
      ..write(obj.saleId)
      ..writeByte(5)
      ..write(obj.customerId)
      ..writeByte(6)
      ..write(obj.warrantyEnds)
      ..writeByte(7)
      ..write(obj.binId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SerialUnitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
