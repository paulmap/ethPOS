import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'device_tier.dart';

/// Where inference happened, shown as the on-device chip on the answer sheet.
enum InferenceSite { onDevice, cloud, rules }

class LlmResult {
  final String text;
  final InferenceSite site;
  final Duration elapsed;
  final String modelName;

  const LlmResult({
    required this.text,
    required this.site,
    required this.elapsed,
    required this.modelName,
  });
}

/// One interface, three implementations: local model, cloud server (phase 2),
/// and a deterministic fallback so the till is never blocked by the model.
abstract class LlmRuntime {
  String get modelName;
  bool get isReady;
  InferenceSite get site;

  Future<void> load();
  Future<LlmResult> complete(String prompt, {int maxTokens = 512});
  Future<void> dispose();
}

/// Local inference. Bind this to whichever plugin you ship — flutter_gemma,
/// fllama or your own llama.cpp FFI binding. The only contract the rest of the
/// app depends on is [complete].
class OnDeviceRuntime implements LlmRuntime {
  OnDeviceRuntime(this.spec, {required this.modelPath});

  final ModelSpec spec;
  final String modelPath;

  bool _ready = false;

  @override
  String get modelName => spec.name;

  @override
  bool get isReady => _ready;

  @override
  InferenceSite get site => InferenceSite.onDevice;

  @override
  Future<void> load() async {
    if (!await File(modelPath).exists()) {
      throw StateError('Model not downloaded: $modelPath');
    }
    // TODO(plugin): initialise the inference engine here, e.g.
    //   _engine = await FlutterGemmaPlugin.instance.createModel(
    //     modelPath: modelPath, maxTokens: 1024);
    _ready = true;
  }

  @override
  Future<LlmResult> complete(String prompt, {int maxTokens = 512}) async {
    if (!_ready) throw StateError('Model not loaded');
    final sw = Stopwatch()..start();
    // TODO(plugin): final text = await _engine.generateResponse(prompt);
    const text = '';
    sw.stop();
    return LlmResult(
      text: text,
      site: InferenceSite.onDevice,
      elapsed: sw.elapsed,
      modelName: spec.name,
    );
  }

  @override
  Future<void> dispose() async => _ready = false;
}

/// Phase 2: same prompt, same tool protocol, executed on a cloud VM alongside
/// the mirrored database. Heavy questions can be queued for this.
class CloudRuntime implements LlmRuntime {
  CloudRuntime({required this.endpoint, required this.apiKey, this.model = 'cloud'});

  final Uri endpoint;
  final String apiKey;
  final String model;

  @override
  String get modelName => model;

  @override
  bool get isReady => true;

  @override
  InferenceSite get site => InferenceSite.cloud;

  @override
  Future<void> load() async {}

  @override
  Future<LlmResult> complete(String prompt, {int maxTokens = 512}) async {
    final sw = Stopwatch()..start();
    final client = HttpClient();
    try {
      final req = await client.postUrl(endpoint);
      req.headers.contentType = ContentType.json;
      req.headers.set('authorization', 'Bearer $apiKey');
      req.write(jsonEncode({
        'model': model,
        'prompt': prompt,
        'max_tokens': maxTokens,
      }));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      sw.stop();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return LlmResult(
        text: (decoded['completion'] ?? decoded['text'] ?? '') as String,
        site: InferenceSite.cloud,
        elapsed: sw.elapsed,
        modelName: model,
      );
    } finally {
      client.close();
    }
  }

  @override
  Future<void> dispose() async {}
}
