import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin wrapper over Ollama's local REST API. Ollama has no auth of its own
/// and must only ever be reachable on localhost -- never reverse-proxied or
/// exposed publicly. This client should only ever be pointed at
/// http://localhost:11434 in production.
class OllamaClient {
  final String baseUrl;
  final String model;
  final http.Client _http;

  OllamaClient({required this.baseUrl, required this.model, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  /// Sends [prompt] to Ollama's /api/generate endpoint (non-streamed) and
  /// returns the model's response text.
  Future<String> generate(String prompt) async {
    final uri = Uri.parse('$baseUrl/api/generate');
    final response = await _http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': model,
            'prompt': prompt,
            'stream': false,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw OllamaException('Ollama returned ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['response'] as String?)?.trim() ?? '';
  }

  void close() => _http.close();
}

class OllamaException implements Exception {
  final String message;
  OllamaException(this.message);

  @override
  String toString() => 'OllamaException: $message';
}
