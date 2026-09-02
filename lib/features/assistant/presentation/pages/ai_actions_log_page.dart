import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/ai/ai_provider.dart';
import '../../../../core/storage/models/ai_action.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/widgets/pos/pos_bits.dart';
import '../../../../core/widgets/pos/pos_scaffold.dart';

/// The paper trail for autonomous changes. Only the most recent action of each
/// kind can be undone — enough to correct a mistake, without letting the log
/// become an editable history.
class AiActionsLogPage extends StatelessWidget {
  const AiActionsLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiProvider>();
    final actions = ai.visibleActions();

    return PosScaffold(
      title: 'What the AI did',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 18),
            child: Text(
              'Every change it made on its own. The most recent of each kind '
              'can be undone.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.mutedLight,
              ),
            ),
          ),
          if (actions.isEmpty)
            PaperCard(
              child: const Text(
                'Nothing yet. It has only answered questions.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ),
          for (final action in actions) ...[
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          action.summary,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.15,
                            decoration: action.undone
                                ? TextDecoration.lineThrough
                                : null,
                            color: action.undone
                                ? AppColors.placeholder
                                : AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _time(action.at),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.placeholder,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    action.detail,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.muted,
                    ),
                  ),
                  if (ai.isUndoable(action)) ...[
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => ai.undo(action),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: AppColors.primaryTintBorder,
                              ),
                            ),
                            child: const Text(
                              'Undo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _kindLabel(action.kind),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.placeholder,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  static String _time(DateTime at) {
    final now = DateTime.now();
    final sameDay =
        at.year == now.year && at.month == now.month && at.day == now.day;
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    if (sameDay) return '$hh:$mm';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[at.weekday - 1]} $hh:$mm';
  }

  static String _kindLabel(AiActionKind kind) => switch (kind) {
        AiActionKind.setReorderPoint => 'reorder points',
        AiActionKind.moveStock => 'stock moves',
        AiActionKind.proposeDiscount => 'discounts',
        AiActionKind.flagPattern => 'flags',
      };
}
