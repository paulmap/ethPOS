import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/models/local_supplier.dart';

class SupplierProvider extends ChangeNotifier {
  final Box<LocalSupplier> _supplierBox = Hive.box<LocalSupplier>('suppliers_box');

  List<LocalSupplier> get suppliers => _supplierBox.values.toList();

  Future<void> addSupplier(LocalSupplier supplier) async {
    await _supplierBox.put(supplier.id, supplier);
    notifyListeners();
  }

  Future<void> updateSupplier(LocalSupplier supplier) async {
    await _supplierBox.put(supplier.id, supplier);
    notifyListeners();
  }

  Future<void> deleteSupplier(String id) async {
    await _supplierBox.delete(id);
    notifyListeners();
  }
}
