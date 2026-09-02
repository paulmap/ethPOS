import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../session/session_provider.dart';
import '../storage/models/ai_action.dart';
import '../storage/models/local_product.dart';
import 'device_tier.dart';
import 'llm_runtime.dart';
import 'pos_tools.dart';

enum AskState { idle, thinking, answered, refused, failed }

/// One step shown in the thinking state, so the wait is legible.
class ThinkingStep {
  final String label;
  bool done;
  ThinkingStep(this.label, {this.done = false});
}

class Answer {
  final String question;
  final String prose;
  final List<Map<String, dynamic>> evidence;
  final String query;
  final InferenceSite site;
  final Duration elapsed;
  final String modelName;
  final bool refused;

  const Answer({
    required this.question,
    required this.prose,
    required this.evidence,
    required this.query,
    required this.site,
    required this.elapsed,
    required this.modelName,
    this.refused = false,
  });

  String get siteLabel => switch (site) {
        InferenceSite.onDevice => 'ON-DEVICE',
        InferenceSite.cloud => 'CLOUD',
        InferenceSite.rules => 'ON-DEVICE',
      };
}

/// The spine of the AI experience: routes a question to a tool, runs the query
/// deterministically, then asks the model only to phrase the result.
///
/// Why this shape: on a 4 GB phone the model is small enough to get arithmetic
/// wrong. Letting it choose the tool but never compute the numbers keeps
/// answers correct and gives the supervisor a query string to audit.
class AiProvider extends ChangeNotifier {
  AiProvider({
    required this.tools,
    required this.session,
    required this.actionLog,
    required this.products,
  });

  final PosTools tools;
  final SessionProvider session;
  final Box<AiAction> actionLog;
  final Box<LocalProduct> products;

  LlmRuntime? _runtime;
  ModelSpec _spec = ModelSpec.none;
  int? _ramMb;

  AskState state = AskState.idle;
  Answer? answer;
  List<ThinkingStep> steps = [];
  final List<String> _cloudQueue = [];

  ModelSpec get spec => _spec;
  int? get ramMb => _ramMb;
  bool get modelReady => _runtime?.isReady ?? false;
  List<String> get cloudQueue => List.unmodifiable(_cloudQueue);

  /// Picks and loads a model based on real device RAM. Silent by design: the
  /// only place the tier surfaces is the first-launch screen.
  Future<void> initialise({String? modelDirectory}) async {
    _ramMb = await DeviceTier.totalRamMb();
    _spec = await DeviceTier.recommended();
    notifyListeners();

    if (_spec.tier == ModelTier.none || modelDirectory == null) return;
    try {
      final runtime = OnDeviceRuntime(
        _spec,
        modelPath: '$modelDirectory/${_spec.fileName}',
      );
      await runtime.load();
      _runtime = runtime;
    } catch (_) {
      // No model on disk yet, or the engine refused to load. The till keeps
      // working; questions fall back to the deterministic router below.
      _runtime = null;
    }
    notifyListeners();
  }

  void useCloud({required Uri endpoint, required String apiKey}) {
    _runtime = CloudRuntime(endpoint: endpoint, apiKey: apiKey);
    notifyListeners();
  }

  // ---- Asking --------------------------------------------------------------

  Future<void> ask(String question, {List<String> cartProductIds = const []}) async {
    state = AskState.thinking;
    answer = null;
    steps = [
      ThinkingStep('Reading your sales'),
      ThinkingStep('Checking stock and bins'),
      ThinkingStep('Working out the answer'),
    ];
    notifyListeners();

    final tool = _route(question, cartProductIds: cartProductIds);
    steps[0].done = true;
    steps[1].done = true;
    notifyListeners();

    // Permission gate. An assistant asking a money question is told plainly and
    // offered the unlock, rather than being given a silently wrong answer.
    if (tool.scope == ToolScope.supervisorOnly && !session.canSeeMoney) {
      state = AskState.refused;
      answer = Answer(
        question: question,
        prose:
            "Takings, cost and margin are supervisor-only, so I can't show that here. "
            'A supervisor can unlock it with their PIN. '
            'I can still help with stock, prices, locations and warranties.',
        evidence: const [],
        query: tool.query,
        site: InferenceSite.rules,
        elapsed: Duration.zero,
        modelName: _spec.name,
        refused: true,
      );
      notifyListeners();
      return;
    }

    var prose = _proseFromFacts(tool);
    var site = InferenceSite.rules;
    var elapsed = Duration.zero;

    if (_runtime?.isReady ?? false) {
      try {
        final result = await _runtime!.complete(_prompt(question, tool));
        if (result.text.trim().isNotEmpty) {
          prose = result.text.trim();
          site = result.site;
          elapsed = result.elapsed;
        }
      } catch (_) {
        // Keep the deterministic prose; never fail the answer because the
        // model stumbled.
      }
    }

    steps[2].done = true;
    state = AskState.answered;
    answer = Answer(
      question: question,
      prose: prose,
      evidence: tool.rows,
      query: tool.query,
      site: site,
      elapsed: elapsed,
      modelName: _spec.name,
    );
    notifyListeners();
  }

  void dismiss() {
    state = AskState.idle;
    answer = null;
    steps = [];
    notifyListeners();
  }

  /// Heavy questions can wait for a cloud runtime rather than grinding a 2B
  /// model on the shop floor.
  void queueForCloud(String question) {
    _cloudQueue.add(question);
    notifyListeners();
  }

  // ---- Routing -------------------------------------------------------------

  /// Keyword router. It is deliberately explicit rather than model-driven: on a
  /// small model, tool selection is the least reliable step, and a wrong tool
  /// produces a confidently wrong answer.
  ToolResult _route(String question, {List<String> cartProductIds = const []}) {
    final q = question.toLowerCase();

    final serial = RegExp(r'\b(\d{12,17})\b').firstMatch(q)?.group(1);
    if (serial != null || q.contains('warrant') || q.contains('covered')) {
      return tools.warrantyLookup(serial ?? q.split(' ').last);
    }
    if (q.contains('reorder') || q.contains('run out') || q.contains('order now')) {
      return tools.reorderNow();
    }
    if (q.contains('not selling') ||
        q.contains('dead stock') ||
        q.contains('slow') ||
        q.contains('sitting')) {
      return tools.deadStock();
    }
    if (q.contains('margin') || q.contains('most money') || q.contains('profit')) {
      return tools.marginByProduct();
    }
    if (q.contains('takings') ||
        q.contains('how much have we made') ||
        q.contains('sales today') ||
        q.contains('this week')) {
      final now = DateTime.now();
      final from = q.contains('week')
          ? now.subtract(Duration(days: now.weekday - 1))
          : DateTime(now.year, now.month, now.day);
      return tools.takings(from: from, to: now);
    }
    if (q.contains('bought with') || q.contains('suggest') || q.contains('add on')) {
      return tools.basketSuggestions(cartProductIds);
    }
    final bin = RegExp(r'(display|storeroom|counter)\s*\.?\s*([a-z]?\d+)')
        .firstMatch(q);
    if (bin != null) {
      return tools.whatsInBin(bin.group(1)!, bin.group(2)!);
    }
    // Default: treat it as a stock lookup, stripping the question words.
    final term = q
        .replaceAll(
            RegExp(r'\b(where|is|the|a|an|how|many|do|we|have|find|any|left)\b'),
            ' ')
        .replaceAll('?', '')
        .trim();
    return tools.findProduct(term);
  }

  /// Used verbatim when there is no model, and as the ground truth the model is
  /// told to rephrase when there is one.
  String _proseFromFacts(ToolResult tool) => tool.facts;

  String _prompt(String question, ToolResult tool) => '''
You are the assistant inside a shop's point-of-sale app. Answer in two short
sentences, plainly, as a colleague would. Use only the facts given. Never invent
numbers. Do not repeat the question.

Question: $question

Facts from the shop's own database:
${tool.facts}

Answer:''';

  // ---- Autonomous actions --------------------------------------------------

  /// Recompute reorder points from sales velocity. Permitted without asking;
  /// every change is logged and the most recent one can be undone.
  Future<int> refreshReorderPoints() async {
    var changed = 0;
    for (final product in products.values) {
      final action = tools.proposeReorderPoint(product);
      if (action == null) continue;
      final payload =
          jsonDecode(action.undoPayload!) as Map<String, dynamic>;
      final suggested =
          int.parse(RegExp(r'(\d+)').firstMatch(action.summary)!.group(1)!);
      await products.put(
        product.id,
        product.copyWith(reorderLevel: suggested, lastUpdated: DateTime.now()),
      );
      await actionLog.put(action.id, action);
      changed++;
      assert(payload['productId'] == product.id);
    }
    if (changed > 0) notifyListeners();
    return changed;
  }

  /// Only the most recent action of each kind is undoable.
  List<AiAction> visibleActions() {
    final all = actionLog.values
        .where((a) => session.canSeeMoney || !a.supervisorOnly)
        .toList()
      ..sort((a, b) => b.at.compareTo(a.at));

    final seen = <AiActionKind>{};
    return all.map((a) {
      final isNewest = seen.add(a.kind);
      return isNewest ? a : a.copyWith(undone: a.undone);
    }).toList();
  }

  bool isUndoable(AiAction action) {
    if (!action.canUndo) return false;
    final newest = actionLog.values
        .where((a) => a.kind == action.kind && !a.undone)
        .fold<AiAction?>(null, (best, a) =>
            best == null || a.at.isAfter(best.at) ? a : best);
    return newest?.id == action.id;
  }

  Future<void> undo(AiAction action) async {
    if (!isUndoable(action)) return;
    final payload = jsonDecode(action.undoPayload!) as Map<String, dynamic>;
    switch (action.kind) {
      case AiActionKind.setReorderPoint:
        final product = products.get(payload['productId'] as String);
        if (product != null) {
          await products.put(
            product.id,
            product.copyWith(
              reorderLevel: payload['previousReorderLevel'] as int,
              lastUpdated: DateTime.now(),
            ),
          );
        }
      case AiActionKind.moveStock:
      case AiActionKind.proposeDiscount:
      case AiActionKind.flagPattern:
        // Stock moves are reversed by BinService.move(); proposals and flags
        // changed nothing, so there is nothing to restore.
        break;
    }
    await actionLog.put(action.id, action.copyWith(undone: true));
    notifyListeners();
  }

  /// Cash-up patterns are written here rather than shown to the assistant.
  Future<void> logCashUpPattern(String detail) async {
    final action = AiAction(
      id: 'ai-${DateTime.now().microsecondsSinceEpoch}',
      kind: AiActionKind.flagPattern,
      summary: 'Flagged a cash-up pattern',
      detail: detail,
      at: DateTime.now(),
      supervisorOnly: true,
    );
    await actionLog.put(action.id, action);
    notifyListeners();
  }
}
