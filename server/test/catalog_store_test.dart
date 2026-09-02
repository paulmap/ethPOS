import 'dart:io';

import 'package:ethpos_assistant_server/src/catalog_store.dart';
import 'package:ethpos_assistant_server/src/models/product_dto.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String catalogPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('ethpos_catalog_test');
    catalogPath = '${tempDir.path}/catalog.json';
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('load() on a missing file leaves an empty catalog', () async {
    final store = CatalogStore(catalogPath);
    await store.load();
    expect(store.size, 0);
    expect(store.lastSyncedAt, isNull);
  });

  test('replaceAll persists to disk and updates in-memory state', () async {
    final store = CatalogStore(catalogPath);
    final product = ProductDto(
      id: '1',
      name: 'Test Widget',
      price: 5.0,
      currency: 'USD',
      currentStock: 3,
      category: 'Misc',
      description: 'a widget',
      locationCode: 'A-1-B1',
      compatibleTags: const [],
    );

    await store.replaceAll([product]);

    expect(store.size, 1);
    expect(store.lastSyncedAt, isNotNull);
    expect(File(catalogPath).existsSync(), isTrue);
  });

  test('a fresh store loads a previously persisted catalog', () async {
    final store = CatalogStore(catalogPath);
    final product = ProductDto(
      id: '1',
      name: 'Test Widget',
      price: 5.0,
      currency: 'USD',
      currentStock: 3,
      category: 'Misc',
      description: 'a widget',
      locationCode: 'A-1-B1',
      compatibleTags: const ['Tag A'],
    );
    await store.replaceAll([product]);

    final reloaded = CatalogStore(catalogPath);
    await reloaded.load();

    expect(reloaded.size, 1);
    expect(reloaded.products.first.name, 'Test Widget');
    expect(reloaded.products.first.compatibleTags, ['Tag A']);
  });

  test('replaceAll fully replaces, not merges, the catalog', () async {
    final store = CatalogStore(catalogPath);
    await store.replaceAll([
      ProductDto(
        id: '1',
        name: 'First',
        price: 1.0,
        currency: 'USD',
        currentStock: 1,
        category: 'Misc',
        description: '',
        locationCode: 'A-1-B1',
        compatibleTags: const [],
      ),
    ]);
    await store.replaceAll([
      ProductDto(
        id: '2',
        name: 'Second',
        price: 2.0,
        currency: 'USD',
        currentStock: 2,
        category: 'Misc',
        description: '',
        locationCode: 'A-1-B2',
        compatibleTags: const [],
      ),
    ]);

    expect(store.size, 1);
    expect(store.products.first.id, '2');
  });

  test('no leftover .tmp file remains after replaceAll', () async {
    final store = CatalogStore(catalogPath);
    await store.replaceAll([]);
    expect(File('$catalogPath.tmp').existsSync(), isFalse);
  });
}
