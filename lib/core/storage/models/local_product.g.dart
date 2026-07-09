// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalProductAdapter extends TypeAdapter<LocalProduct> {
  @override
  final int typeId = 0;

  @override
  LocalProduct read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalProduct(
      id: fields[0] as String,
      name: fields[1] as String,
      barcode: fields[2] as String?,
      price: fields[3] as double,
      currentStock: fields[4] as int,
      lastUpdated: fields[5] as DateTime,
      productCode: fields[8] as String?,
      sku: fields[9] as String?,
      category: fields[10] as String?,
      description: fields[11] as String?,
      taxCategory: fields[12] as String?,
      minStockHolding: fields[13] as int?,
      reorderLevel: fields[14] as int?,
      costPrice: fields[15] as double?,
      markup: fields[16] as double?,
      currency: fields[6] as String?,
      isDiscontinued: fields[7] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalProduct obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.barcode)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.currentStock)
      ..writeByte(5)
      ..write(obj.lastUpdated)
      ..writeByte(6)
      ..write(obj.currency)
      ..writeByte(7)
      ..write(obj.isDiscontinued)
      ..writeByte(8)
      ..write(obj.productCode)
      ..writeByte(9)
      ..write(obj.sku)
      ..writeByte(10)
      ..write(obj.category)
      ..writeByte(11)
      ..write(obj.description)
      ..writeByte(12)
      ..write(obj.taxCategory)
      ..writeByte(13)
      ..write(obj.minStockHolding)
      ..writeByte(14)
      ..write(obj.reorderLevel)
      ..writeByte(15)
      ..write(obj.costPrice)
      ..writeByte(16)
      ..write(obj.markup);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
