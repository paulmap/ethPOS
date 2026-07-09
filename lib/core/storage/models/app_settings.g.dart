// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 4;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      baseCurrency: fields[0] as String,
      exchangeRates: (fields[1] as Map).cast<String, double>(),
      businessName: fields[2] == null ? 'Alpha Systems' : fields[2] as String?,
      city: fields[3] == null ? 'Hilte City' : fields[3] as String?,
      country: fields[4] == null ? 'India' : fields[4] as String?,
      email: fields[5] == null ? 'alpha@gmail.com' : fields[5] as String?,
      contactNumber: fields[6] == null ? '+1812993345' : fields[6] as String?,
      receiptPrefix: fields[7] == null ? 'RCPT' : fields[7] as String?,
      receiptStartNumber: fields[8] == null ? 1 : fields[8] as int?,
      invoicePrefix: fields[9] == null ? 'INV' : fields[9] as String?,
      invoiceStartNumber: fields[10] == null ? 1 : fields[10] as int?,
      poPrefix: fields[11] == null ? 'PO' : fields[11] as String?,
      poStartNumber: fields[12] == null ? 1 : fields[12] as int?,
      receiptTagline: fields[13] == null
          ? 'Thank you for your business!'
          : fields[13] as String?,
      taxCategories: (fields[14] as List?)?.cast<String>(),
      adminPin: fields[15] == null ? '1234' : fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.baseCurrency)
      ..writeByte(1)
      ..write(obj.exchangeRates)
      ..writeByte(2)
      ..write(obj.businessName)
      ..writeByte(3)
      ..write(obj.city)
      ..writeByte(4)
      ..write(obj.country)
      ..writeByte(5)
      ..write(obj.email)
      ..writeByte(6)
      ..write(obj.contactNumber)
      ..writeByte(7)
      ..write(obj.receiptPrefix)
      ..writeByte(8)
      ..write(obj.receiptStartNumber)
      ..writeByte(9)
      ..write(obj.invoicePrefix)
      ..writeByte(10)
      ..write(obj.invoiceStartNumber)
      ..writeByte(11)
      ..write(obj.poPrefix)
      ..writeByte(12)
      ..write(obj.poStartNumber)
      ..writeByte(13)
      ..write(obj.receiptTagline)
      ..writeByte(14)
      ..write(obj.taxCategories)
      ..writeByte(15)
      ..write(obj.adminPin);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
