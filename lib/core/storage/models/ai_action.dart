import 'package:hive/hive.dart';

part 'ai_action.g.dart';

/// What the model is permitted to change without being asked each time.
@HiveType(typeId: 24)
enum AiActionKind {
  @HiveField(0)
  setReorderPoint,
  @HiveField(1)
  moveStock,
  @HiveField(2)
  proposeDiscount,
  @HiveField(3)
  flagPattern,
}

/// Audit trail for autonomous AI changes. Only the most recent action of each
/// kind is undoable, per the agreed policy.
@HiveType(typeId: 25)
class AiAction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final AiActionKind kind;

  @HiveField(2)
  final String summary;

  @HiveField(3)
  final String detail;

  @HiveField(4)
  final DateTime at;

  /// JSON blob holding the previous values, so an undo can restore them.
  @HiveField(5)
  final String? undoPayload;

  @HiveField(6)
  final bool undone;

  /// Patterns the assistant must not see stay supervisor-only.
  @HiveField(7)
  final bool supervisorOnly;

  @HiveField(8)
  final String? approvedBy;

  AiAction({
    required this.id,
    required this.kind,
    required this.summary,
    required this.detail,
    required this.at,
    this.undoPayload,
    this.undone = false,
    this.supervisorOnly = false,
    this.approvedBy,
  });

  bool get canUndo => !undone && undoPayload != null;

  AiAction copyWith({bool? undone}) => AiAction(
        id: id,
        kind: kind,
        summary: summary,
        detail: detail,
        at: at,
        undoPayload: undoPayload,
        undone: undone ?? this.undone,
        supervisorOnly: supervisorOnly,
        approvedBy: approvedBy,
      );
}
