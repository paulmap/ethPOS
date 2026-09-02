import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Minimal shared-secret bearer-token auth, appropriate for a POC: a single
/// API key shared between the app and this backend, checked via the
/// Authorization header. Known limitations, accepted at this scope: no
/// per-user identity, no key rotation beyond regenerating in Settings, no
/// rate limiting.
Middleware requireBearerToken(String expectedApiKey) {
  return (Handler innerHandler) {
    return (Request request) async {
      final header = request.headers['authorization'];
      if (header == null || !header.startsWith('Bearer ') || header.substring(7) != expectedApiKey) {
        return Response(
          401,
          body: jsonEncode({'error': 'Unauthorized'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      return innerHandler(request);
    };
  };
}
