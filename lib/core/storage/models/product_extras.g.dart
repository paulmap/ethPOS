// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_extras.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductExtrasAdapter extends TypeAdapter<ProductExtras> {
  @override
  final int typeId = 22;

  @override
  ProductExtras read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductExtras(
      productId: fields[0] as String,
      serialised: fields[1] as bool,
      warrantyMonths: fields[2] as int,
      isService: fields[3] as bool,
      quickAdd: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ProductExtras obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.serialised)
      ..writeByte(2)
      ..write(obj.warrantyMonths)
      ..writeByte(3)
      ..write(obj.isService)
      ..writeByte(4)
      ..write(obj.quickAdd);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductExtrasAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
