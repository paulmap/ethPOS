import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'package:ethpos_assistant_server/src/auth_middleware.dart';
import 'package:ethpos_assistant_server/src/catalog_store.dart';
import 'package:ethpos_assistant_server/src/ollama_client.dart';
import 'package:ethpos_assistant_server/src/routes/health_routes.dart';
import 'package:ethpos_assistant_server/src/routes/query_routes.dart';
import 'package:ethpos_assistant_server/src/routes/sync_routes.dart';

Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final apiKey = Platform.environment['API_KEY'];
  final ollamaUrl = Platform.environment['OLLAMA_URL'] ?? 'http://localhost:11434';
  final model = Platform.environment['MODEL_NAME'] ?? 'qwen2.5:3b-instruct';
  final catalogPath = Platform.environment['CATALOG_PATH'] ?? 'catalog.json';

  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('FATAL: API_KEY environment variable must be set.');
    exit(1);
  }

  final catalog = CatalogStore(catalogPath);
  await catalog.load();
  stdout.writeln('Loaded catalog: ${catalog.size} products (last synced: ${catalog.lastSyncedAt})');

  final ollama = OllamaClient(baseUrl: ollamaUrl, model: model);

  final protectedRouter = Router()
    ..mount('/', syncRoutes(catalog).call)
    ..mount('/', queryRoutes(catalog, ollama).call);

  final protectedHandler = Pipeline().addMiddleware(requireBearerToken(apiKey)).addHandler(protectedRouter.call);

  final app = Router()
    ..mount('/', healthRoutes(catalog, model).call)
    ..mount('/', protectedHandler);

  final handler = Pipeline().addMiddleware(logRequests()).addHandler(app.call);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('ethPOS assistant server listening on port ${server.port} (model: $model)');
}
