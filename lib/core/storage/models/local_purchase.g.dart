// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_purchase.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalPurchaseItemAdapter extends TypeAdapter<LocalPurchaseItem> {
  @override
  final int typeId = 6;

  @override
  LocalPurchaseItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalPurchaseItem(
      productId: fields[0] as String,
      productName: fields[1] as String,
      quantity: fields[2] as int,
      costPrice: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, LocalPurchaseItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.costPrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalPurchaseItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocalPurchaseAdapter extends TypeAdapter<LocalPurchase> {
  @override
  final int typeId = 7;

  @override
  LocalPurchase read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalPurchase(
      id: fields[0] as String,
      supplierId: fields[1] as String,
      items: (fields[2] as List).cast<LocalPurchaseItem>(),
      totalAmount: fields[3] as double,
      timestamp: fields[4] as DateTime,
      status: fields[5] as String,
      purchaseNumber: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalPurchase obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.supplierId)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.totalAmount)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.purchaseNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalPurchaseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
