import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../catalog_store.dart';
import '../models/product_dto.dart';

Router syncRoutes(CatalogStore catalog) {
  final router = Router();

  router.post('/v1/sync', (Request request) async {
    final body = await request.readAsString();
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response(400, body: jsonEncode({'error': 'Invalid JSON body'}), headers: _jsonHeaders);
    }

    final rawProducts = decoded['products'];
    if (rawProducts is! List) {
      return Response(400, body: jsonEncode({'error': '"products" must be a list'}), headers: _jsonHeaders);
    }

    final products = rawProducts.cast<Map<String, dynamic>>().map(ProductDto.fromJson).toList();
    await catalog.replaceAll(products);

    return Response.ok(
      jsonEncode({'received': products.length, 'syncedAt': catalog.lastSyncedAt!.toIso8601String()}),
      headers: _jsonHeaders,
    );
  });

  return router;
}

const _jsonHeaders = {'Content-Type': 'application/json'};
