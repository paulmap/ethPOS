import 'package:hive/hive.dart';

part 'local_customer.g.dart';

@HiveType(typeId: 3)
class LocalCustomer extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String phoneNumber;

  @HiveField(3)
  final int points;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final double? creditLimit;

  @HiveField(6)
  final String? birthday;

  @HiveField(7)
  final double? totalOutstanding;

  LocalCustomer({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.points = 0,
    required this.createdAt,
    this.creditLimit,
    this.birthday,
    this.totalOutstanding,
  });

  LocalCustomer copyWith({
    String? name,
    String? phoneNumber,
    int? points,
    double? creditLimit,
    String? birthday,
    double? totalOutstanding,
  }) {
    return LocalCustomer(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      points: points ?? this.points,
      createdAt: createdAt,
      creditLimit: creditLimit ?? this.creditLimit,
      birthday: birthday ?? this.birthday,
      totalOutstanding: totalOutstanding ?? this.totalOutstanding,
    );
  }

  String get maskedPhoneNumber {
    if (phoneNumber.length < 7) return phoneNumber;
    final start = phoneNumber.substring(0, 3);
    final end = phoneNumber.substring(phoneNumber.length - 3);
    return '$start****$end';
  }
}
