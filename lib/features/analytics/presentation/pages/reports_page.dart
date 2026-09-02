import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/ai/ai_provider.dart';
import '../../../../core/session/session_provider.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/widgets/pos/pos_bits.dart';
import '../../../../core/widgets/pos/pos_scaffold.dart';

/// "See the numbers" — the evidence behind the insight cards. Locked to an
/// unlocked supervisor: every figure here is money, so the gate is in this
/// widget rather than in whatever navigated to it.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    if (!session.canSeeMoney) {
      return const PosScaffold(
        title: 'Reports',
        trailing: SupervisorPadlock(),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              'Takings, cost and margin need a supervisor PIN.\n'
              'Tap the padlock to unlock.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.mutedLight,
              ),
            ),
          ),
        ),
      );
    }

    final tools = context.read<AiProvider>().tools;
    final now = DateTime.now();
    final today = tools.takings(
      from: DateTime(now.year, now.month, now.day),
      to: now,
    );
    final week = tools.takings(
      from: now.subtract(const Duration(days: 7)),
      to: now,
    );
    final margin = tools.marginByProduct();
    final reorder = tools.reorderNow();
    final dead = tools.deadStock();

    return PosScaffold(
      title: 'Reports',
      subtitle: session.modeLine,
      trailing: const SupervisorPadlock(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
        children: [
          const Eyebrow('TAKINGS'),
          StackedList(
            children: [
              _Line(
                label: 'Today',
                value: _money(today.rows.first['total'] as double),
                note: '${today.rows.first['sales']} sales',
              ),
              _Line(
                label: 'Last 7 days',
                value: _money(week.rows.first['total'] as double),
                note: 'avg basket ${_money(week.rows.first['average'] as double)}',
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Eyebrow('MARGIN, LAST 7 DAYS'),
          if (margin.rows.isEmpty)
            const _Empty('No sales in the last 7 days.')
          else
            StackedList(
              children: [
                for (final row in margin.rows)
                  _Line(
                    label: row['name'] as String,
                    value: '${row['marginPct']}%',
                    note: '${row['sold']} sold · ${_money(row['revenue'] as double)}',
                  ),
              ],
            ),
          const SizedBox(height: 20),
          const Eyebrow('RUNNING OUT'),
          if (reorder.rows.isEmpty)
            const _Empty('Nothing runs out within a fortnight.')
          else
            StackedList(
              children: [
                for (final row in reorder.rows)
                  _Line(
                    label: row['name'] as String,
                    value: '${row['daysCover']}d',
                    note: '${row['onHand']} on hand · sells ${row['perWeek']}/week',
                  ),
              ],
            ),
          const SizedBox(height: 20),
          const Eyebrow('SITTING STILL'),
          _Query(dead.facts, query: dead.query),
          if (dead.rows.isNotEmpty) ...[
            const SizedBox(height: 10),
            StackedList(
              children: [
                for (final row in dead.rows)
                  _Line(
                    label: row['name'] as String,
                    value: _money(row['tiedUp'] as double),
                    note: '${row['onHand']} on hand',
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static String _money(double v) => '\$${v.toStringAsFixed(2)}';
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.15,
                ),
              ),
              if (note != null) ...[
                const SizedBox(height: 3),
                Text(
                  note!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedLight,
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => PaperCard(
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: AppColors.mutedLight),
        ),
      );
}

/// The facts sentence with the query behind it, same affordance as the answer
/// sheet: a supervisor can always check how a number was reached.
class _Query extends StatelessWidget {
  const _Query(this.facts, {required this.query});

  final String facts;
  final String query;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 17),
          childrenPadding: const EdgeInsets.fromLTRB(17, 0, 17, 15),
          title: Text(
            facts,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                query,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  fontFamily: 'monospace',
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
