import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../catalog_store.dart';

Router healthRoutes(CatalogStore catalog, String model) {
  final router = Router();

  router.get('/health', (Request request) {
    return Response.ok(
      jsonEncode({
        'status': 'ok',
        'model': model,
        'catalogSize': catalog.size,
        'lastSyncedAt': catalog.lastSyncedAt?.toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });

  return router;
}
