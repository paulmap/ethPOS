import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../catalog_store.dart';
import '../ollama_client.dart';
import '../retrieval.dart';

Router queryRoutes(CatalogStore catalog, OllamaClient ollama) {
  final router = Router();

  router.post('/v1/query', (Request request) async {
    final body = await request.readAsString();
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response(400, body: jsonEncode({'error': 'Invalid JSON body'}), headers: _jsonHeaders);
    }

    final question = decoded['question'] as String?;
    if (question == null || question.trim().isEmpty) {
      return Response(400, body: jsonEncode({'error': '"question" is required'}), headers: _jsonHeaders);
    }

    final candidates = Retrieval.search(question, catalog.products);
    final prompt = _buildPrompt(question, candidates);

    String answer;
    try {
      answer = await ollama.generate(prompt);
    } on OllamaException catch (e) {
      return Response(502, body: jsonEncode({'error': 'AI backend unavailable: $e'}), headers: _jsonHeaders);
    }

    return Response.ok(
      jsonEncode({
        'answer': answer,
        'referencedProducts': candidates
            .map((c) => {
                  'id': c.product.id,
                  'name': c.product.name,
                  'price': c.product.price,
                  'currency': c.product.currency,
                  'currentStock': c.product.currentStock,
                  'locationCode': c.product.locationCode,
                })
            .toList(),
        'candidateCount': candidates.length,
      }),
      headers: _jsonHeaders,
    );
  });

  return router;
}

String _buildPrompt(String question, List<ScoredProduct> candidates) {
  final buffer = StringBuffer();
  buffer.writeln(
    'You are a knowledgeable in-store sales consultant for a small electronics/accessories shop. '
    'Answer the customer\'s question using ONLY the product information below. '
    'Always mention exact stock location codes and whether an item is in stock. '
    'If an exact match is out of stock but a compatible/interchangeable alternative is available, recommend it. '
    'If nothing below is relevant, say so honestly rather than inventing an answer. Be concise.',
  );
  buffer.writeln();

  if (candidates.isEmpty) {
    buffer.writeln('No matching products were found in the catalog for this question.');
  } else {
    buffer.writeln('Available product information:');
    for (final c in candidates) {
      final p = c.product;
      final stockStatus = p.currentStock > 0 ? '${p.currentStock} in stock' : 'out of stock';
      final tags = p.compatibleTags.isNotEmpty ? ', fits: ${p.compatibleTags.join(', ')}' : '';
      buffer.writeln(
        '- ${p.name} | ${p.currency} ${p.price.toStringAsFixed(2)} | $stockStatus | location: ${p.locationCode}$tags',
      );
    }
  }

  buffer.writeln();
  buffer.writeln('Customer question: $question');
  return buffer.toString();
}

const _jsonHeaders = {'Content-Type': 'application/json'};
