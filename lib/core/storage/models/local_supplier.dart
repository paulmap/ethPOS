import 'package:hive/hive.dart';

part 'local_supplier.g.dart';

@HiveType(typeId: 5)
class LocalSupplier extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? contactPerson;
  
  @HiveField(3)
  final String? phoneNumber;
  
  @HiveField(4)
  final String? email;
  
  @HiveField(5)
  final String? address;

  LocalSupplier({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phoneNumber,
    this.email,
    this.address,
  });
}
