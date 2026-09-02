// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShiftRecordAdapter extends TypeAdapter<ShiftRecord> {
  @override
  final int typeId = 23;

  @override
  ShiftRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShiftRecord(
      id: fields[0] as String,
      staffId: fields[1] as String,
      staffName: fields[2] as String,
      openedAt: fields[3] as DateTime,
      openingFloat: fields[4] as double,
      closedAt: fields[5] as DateTime?,
      countedCash: fields[6] as double?,
      countedCashZwl: fields[7] as double?,
      mobileMoneyTotal: fields[8] as double?,
      cardTotal: fields[9] as double?,
      expectedCash: fields[10] as double?,
      closingNote: fields[11] as String?,
      signedOffBy: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ShiftRecord obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.staffId)
      ..writeByte(2)
      ..write(obj.staffName)
      ..writeByte(3)
      ..write(obj.openedAt)
      ..writeByte(4)
      ..write(obj.openingFloat)
      ..writeByte(5)
      ..write(obj.closedAt)
      ..writeByte(6)
      ..write(obj.countedCash)
      ..writeByte(7)
      ..write(obj.countedCashZwl)
      ..writeByte(8)
      ..write(obj.mobileMoneyTotal)
      ..writeByte(9)
      ..write(obj.cardTotal)
      ..writeByte(10)
      ..write(obj.expectedCash)
      ..writeByte(11)
      ..write(obj.closingNote)
      ..writeByte(12)
      ..write(obj.signedOffBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
