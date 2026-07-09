// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_sale.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalSaleItemAdapter extends TypeAdapter<LocalSaleItem> {
  @override
  final int typeId = 1;

  @override
  LocalSaleItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalSaleItem(
      productId: fields[0] as String,
      productName: fields[1] as String,
      quantity: fields[2] as int,
      unitPrice: fields[3] as double,
      currency: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalSaleItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.unitPrice)
      ..writeByte(4)
      ..write(obj.currency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalSaleItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocalSaleAdapter extends TypeAdapter<LocalSale> {
  @override
  final int typeId = 2;

  @override
  LocalSale read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalSale(
      id: fields[0] as String,
      items: (fields[1] as List).cast<LocalSaleItem>(),
      totalAmount: fields[2] as double,
      timestamp: fields[3] as DateTime,
      isSynced: fields[4] == null ? false : fields[4] as bool?,
      customerId: fields[5] as String?,
      pointsAwarded: fields[6] as int?,
      pointsRedeemed: fields[7] as int?,
      paymentCurrency: fields[8] as String?,
      tenderedAmount: fields[9] as double?,
      change: fields[10] as double?,
      changeConvertedToPoints: fields[11] as bool?,
      customerPO: fields[12] as String?,
      receiptNumber: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalSale obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.items)
      ..writeByte(2)
      ..write(obj.totalAmount)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.isSynced)
      ..writeByte(5)
      ..write(obj.customerId)
      ..writeByte(6)
      ..write(obj.pointsAwarded)
      ..writeByte(7)
      ..write(obj.pointsRedeemed)
      ..writeByte(8)
      ..write(obj.paymentCurrency)
      ..writeByte(9)
      ..write(obj.tenderedAmount)
      ..writeByte(10)
      ..write(obj.change)
      ..writeByte(11)
      ..write(obj.changeConvertedToPoints)
      ..writeByte(12)
      ..write(obj.customerPO)
      ..writeByte(13)
      ..write(obj.receiptNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalSaleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
