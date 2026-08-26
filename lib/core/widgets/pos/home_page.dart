import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../ai/ai_provider.dart';
import '../../session/session_provider.dart';
import '../../themes/colors.dart';
import 'pos_bits.dart';
import 'pos_scaffold.dart';

/// One home screen, two faces. The assistant sees a till: a big New sale block
/// and four utilities, and no money totals anywhere — deliberate, so a customer
/// leaning over the counter learns nothing. A supervisor's PIN swaps the same
/// screen for the insight feed.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    return PosScaffold(
      title: 'ethPOS',
      showBack: false,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => context.read<SessionProvider>().signOut(),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.hairline),
              ),
              child: const Icon(Icons.logout, size: 16, color: AppColors.mutedLight),
            ),
          ),
          const SupervisorPadlock(),
        ],
      ),
      child: session.canSeeMoney
          ? const _SupervisorHome()
          : const _AssistantHome(),
    );
  }
}

class _AssistantHome extends StatelessWidget {
  const _AssistantHome();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
      child: Column(
        children: [
          _NewSaleBlock(
            onTap: () {
              // Starting an ordinary sale relocks supervisor views.
              context.read<SessionProvider>().onSaleStarted();
              Navigator.pushNamed(context, '/scan');
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Tile(
                  icon: Icons.search,
                  label: 'Find stock',
                  onTap: () => Navigator.pushNamed(context, '/stock'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Tile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                  onTap: () => Navigator.pushNamed(context, '/inventory'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Tile(
                  icon: Icons.receipt_long_outlined,
                  label: 'Receipts',
                  onTap: () => Navigator.pushNamed(context, '/receipts'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Tile(
                  icon: Icons.point_of_sale_outlined,
                  label: 'Close shift',
                  onTap: () => Navigator.pushNamed(context, '/cash-up'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewSaleBlock extends StatelessWidget {
  const _NewSaleBlock({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.qr_code_scanner, size: 30, color: Colors.white70),
            const SizedBox(height: 38),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'New sale',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.7,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Scan or search to begin',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 28, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      onTap: onTap,
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 19),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// The insight feed. Cards carry the action, so the answer and the doing sit
/// together rather than in a separate reports section.
class _SupervisorHome extends StatelessWidget {
  const _SupervisorHome();

  @override
  Widget build(BuildContext context) {
    final ai = context.read<AiProvider>();

    return FutureBuilder<List<_Insight>>(
      future: _insights(ai),
      builder: (context, snapshot) {
        final insights = snapshot.data ?? const [];
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
          children: [
            _StatRow(ai: ai),
            const SizedBox(height: 16),
            const Eyebrow('WHAT NEEDS YOU TODAY', icon: Icons.auto_awesome),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            for (final insight in insights) ...[
              PaperCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      insight.body,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.muted,
                      ),
                    ),
                    if (insight.actionLabel != null && insight.actionRoute != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              insight.actionRoute!,
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            child: Text(insight.actionLabel!),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/reports',
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                            ),
                            child: const Text('See the numbers'),
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
        );
      },
    );
  }

  Future<List<_Insight>> _insights(AiProvider ai) async {
    final reorder = ai.tools.reorderNow();
    final dead = ai.tools.deadStock();
    return [
      if (reorder.rows.isNotEmpty)
        _Insight(
          title: 'Reorder ${reorder.rows.length} lines',
          body: reorder.facts,
          actionLabel: 'Build order',
          actionRoute: '/purchases',
        ),
      if (dead.rows.isNotEmpty)
        _Insight(title: 'Stock sitting still', body: dead.facts),
    ];
  }
}

class _Insight {
  _Insight({
    required this.title,
    required this.body,
    this.actionLabel,
    this.actionRoute,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final String? actionRoute;
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.ai});

  final AiProvider ai;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = ai.tools
        .takings(from: DateTime(now.year, now.month, now.day), to: now)
        .rows
        .first;
    final margin = ai.tools.marginByProduct().rows;
    final avgMargin = margin.isEmpty
        ? 0
        : margin
                .map((r) => r['marginPct'] as int)
                .reduce((a, b) => a + b) ~/
            margin.length;

    return Row(
      children: [
        Expanded(
          child: _Stat(
            label: 'TAKINGS',
            value: '\$${(today['total'] as double).toStringAsFixed(0)}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _Stat(label: 'MARGIN', value: '$avgMargin%')),
        const SizedBox(width: 10),
        Expanded(
          child: _Stat(label: 'SALES', value: '${today['sales']}'),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              color: AppColors.mutedLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.36,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
