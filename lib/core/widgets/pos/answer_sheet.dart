import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../ai/ai_provider.dart';
import '../../session/session_provider.dart';
import '../../themes/colors.dart';
import 'pos_bits.dart';

/// Prose first, evidence underneath: the answer reads like a colleague
/// explaining, then shows the rows it leaned on so it can be checked.
class AnswerSheetBody extends StatelessWidget {
  const AnswerSheetBody({super.key, required this.onAskAgain});

  final VoidCallback onAskAgain;

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiProvider>();
    if (ai.state == AskState.thinking) return _Thinking(steps: ai.steps, model: ai.spec.name);

    final answer = ai.answer;
    if (answer == null) return const SizedBox.shrink();

    final canAudit = context.watch<SessionProvider>().canSeeMoney;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ANSWER',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.9,
                  color: AppColors.mutedLight,
                ),
              ),
              const Spacer(),
              _SiteChip(answer: answer),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            answer.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.35,
              letterSpacing: -0.24,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 18),
          if (answer.refused)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(Icons.lock_outline, size: 17, color: AppColors.placeholder),
                ),
                const SizedBox(width: 12),
                Expanded(child: _prose(answer.prose)),
              ],
            )
          else
            _prose(answer.prose),
          if (answer.evidence.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Evidence(rows: answer.evidence),
          ],
          if (canAudit && !answer.refused) ...[
            const SizedBox(height: 14),
            _QueryExpander(query: answer.query),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              if (answer.refused)
                ElevatedButton(
                  onPressed: () => _unlock(context),
                  style: _small(),
                  child: const Text('Unlock with PIN'),
                )
              else
                ElevatedButton(
                  onPressed: onAskAgain,
                  style: _small(),
                  child: const Text('Ask a follow-up'),
                ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onAskAgain,
                child: const Text('Ask something else'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static ButtonStyle _small() => ElevatedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      );

  Widget _prose(String text) => Text(
        text,
        style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.inkSoft),
      );

  Future<void> _unlock(BuildContext context) async {
    final pin = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Supervisor PIN'),
          content: TextField(
            controller: controller,
            obscureText: true,
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Unlock'),
            ),
          ],
        );
      },
    );
    if (pin == null || !context.mounted) return;
    final ok = context.read<SessionProvider>().unlockSupervisor(pin);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PIN not recognised')));
    }
  }
}

class _SiteChip extends StatelessWidget {
  const _SiteChip({required this.answer});

  final Answer answer;

  @override
  Widget build(BuildContext context) {
    final elapsed = answer.elapsed.inMilliseconds > 0
        ? ' · ${(answer.elapsed.inMilliseconds / 1000).toStringAsFixed(1)}s'
        : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryTintBorder),
      ),
      child: Text(
        '${answer.siteLabel}$elapsed',
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 0.7,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// The rows the answer used, as tappable evidence.
class _Evidence extends StatelessWidget {
  const _Evidence({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    return StackedList(
      children: [
        for (final row in rows.take(5))
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (row['name'] ?? row['serial'] ?? '—').toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(row),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.placeholder,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (row['daysCover'] != null)
                Text(
                  '${row['daysCover']} days',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: (row['daysCover'] as int) <= 7
                        ? AppColors.warning
                        : AppColors.mutedLight,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  static String _subtitle(Map<String, dynamic> row) {
    final parts = <String>[];
    final bins = row['bins'];
    if (bins is List && bins.isNotEmpty) {
      parts.add(bins
          .map((b) => b is Map ? (b['code'] ?? '').toString() : b.toString())
          .take(2)
          .join(' '));
    }
    if (row['onHand'] != null) parts.add('${row['onHand']} left');
    if (row['qty'] != null) parts.add('× ${row['qty']}');
    if (row['marginPct'] != null) parts.add('${row['marginPct']}% margin');
    if (row['covered'] != null) {
      parts.add(row['covered'] == true ? 'under warranty' : 'out of warranty');
    }
    return parts.join(' · ');
  }
}

class _QueryExpander extends StatefulWidget {
  const _QueryExpander({required this.query});

  final String query;

  @override
  State<_QueryExpander> createState() => _QueryExpanderState();
}

class _QueryExpanderState extends State<_QueryExpander> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _open = !_open),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.hairlineStrong,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Show the query I ran',
                    style: TextStyle(fontSize: 13, color: AppColors.mutedLight),
                  ),
                ),
                Icon(
                  _open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.mutedLight,
                ),
              ],
            ),
            if (_open) ...[
              const SizedBox(height: 10),
              Text(
                widget.query,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The wait, made legible: what it read, what it is working out.
class _Thinking extends StatelessWidget {
  const _Thinking({required this.steps, required this.model});

  final List<ThinkingStep> steps;
  final String model;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
              SizedBox(width: 11),
              Text(
                'Working on device',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final step in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                children: [
                  if (step.done)
                    const Icon(Icons.check, size: 15, color: AppColors.primary)
                  else
                    const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  const SizedBox(width: 11),
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: step.done ? AppColors.muted : AppColors.ink,
                      fontWeight: step.done ? FontWeight.w400 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text(
            model.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.6,
              color: AppColors.placeholder,
            ),
          ),
        ],
      ),
    );
  }
}
