import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/storage/models/local_customer.dart';

class LoyaltyProvider extends ChangeNotifier {
  final Box<LocalCustomer> _customerBox = Hive.box<LocalCustomer>('customers_box');
  final _uuid = const Uuid();

  List<LocalCustomer> get customers => _customerBox.values.toList();

  Future<void> addCustomer(
    String name, 
    String phoneNumber, {
    double? creditLimit,
    String? birthday,
    double? totalOutstanding,
  }) async {
    final customer = LocalCustomer(
      id: _uuid.v4(),
      name: name,
      phoneNumber: phoneNumber,
      createdAt: DateTime.now(),
      points: 0,
      creditLimit: creditLimit,
      birthday: birthday,
      totalOutstanding: totalOutstanding,
    );
    await _customerBox.put(customer.id, customer);
    notifyListeners();
  }

  Future<void> updateCustomer(LocalCustomer customer) async {
    await _customerBox.put(customer.id, customer);
    notifyListeners();
  }

  LocalCustomer? findCustomerByPhone(String phone) {
    try {
      return _customerBox.values.firstWhere(
        (c) => c.phoneNumber == phone,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> addPoints(String customerId, int points) async {
    final customer = _customerBox.get(customerId);
    if (customer != null) {
      final updated = customer.copyWith(points: customer.points + points);
      await _customerBox.put(customerId, updated);
      notifyListeners();
    }
  }

  Future<void> redeemPoints(String customerId, int points) async {
    final customer = _customerBox.get(customerId);
    if (customer != null && customer.points >= points) {
      final updated = customer.copyWith(points: customer.points - points);
      await _customerBox.put(customerId, updated);
      notifyListeners();
    }
  }

  List<LocalCustomer> searchCustomers(String query) {
    if (query.isEmpty) return customers;
    return customers.where((c) => 
      c.name.toLowerCase().contains(query.toLowerCase()) || 
      c.phoneNumber.contains(query)
    ).toList();
  }
}
