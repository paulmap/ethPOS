// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_customer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalCustomerAdapter extends TypeAdapter<LocalCustomer> {
  @override
  final int typeId = 3;

  @override
  LocalCustomer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalCustomer(
      id: fields[0] as String,
      name: fields[1] as String,
      phoneNumber: fields[2] as String,
      points: fields[3] as int,
      createdAt: fields[4] as DateTime,
      creditLimit: fields[5] as double?,
      birthday: fields[6] as String?,
      totalOutstanding: fields[7] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalCustomer obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phoneNumber)
      ..writeByte(3)
      ..write(obj.points)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.creditLimit)
      ..writeByte(6)
      ..write(obj.birthday)
      ..writeByte(7)
      ..write(obj.totalOutstanding);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalCustomerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
