import 'dart:convert';
import 'dart:io';

import 'models/product_dto.dart';

/// Holds the synced product catalog in memory, backed by a single JSON file
/// for durability across restarts. No database — a small shop's catalog
/// (hundreds-low thousands of SKUs) is a few hundred KB of JSON, well within
/// what's reasonable to hold in RAM for this POC.
class CatalogStore {
  final File _file;
  List<ProductDto> _products = [];
  DateTime? _lastSyncedAt;

  CatalogStore(String path) : _file = File(path);

  List<ProductDto> get products => List.unmodifiable(_products);
  DateTime? get lastSyncedAt => _lastSyncedAt;
  int get size => _products.length;

  /// Loads the catalog from disk if the file exists. Call once on boot.
  Future<void> load() async {
    if (!await _file.exists()) return;
    final raw = await _file.readAsString();
    if (raw.trim().isEmpty) return;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = (decoded['products'] as List).cast<Map<String, dynamic>>();
    _products = list.map(ProductDto.fromJson).toList();
    final syncedAt = decoded['syncedAt'] as String?;
    _lastSyncedAt = syncedAt != null ? DateTime.tryParse(syncedAt) : null;
  }

  /// Replaces the entire catalog and atomically persists it to disk (write
  /// to a temp file, then rename over the real one, avoiding a torn read if
  /// a query request lands mid-write).
  Future<void> replaceAll(List<ProductDto> products) async {
    _products = products;
    _lastSyncedAt = DateTime.now().toUtc();

    final tmp = File('${_file.path}.tmp');
    final payload = jsonEncode({
      'syncedAt': _lastSyncedAt!.toIso8601String(),
      'products': _products.map((p) => p.toJson()).toList(),
    });
    await tmp.writeAsString(payload);
    await tmp.rename(_file.path);
  }
}
