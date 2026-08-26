import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/ai/ai_provider.dart';
import '../../../../core/session/session_provider.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/widgets/pos/pos_bits.dart';
import '../../../../core/widgets/pos/pos_scaffold.dart';

/// Split by method: cash is counted, mobile money and card are confirmed from
/// the system. The assistant sees their own variance — they need to know if
/// they are short — but the cross-shift pattern goes to the supervisor's log
/// instead of on screen, so no takings history leaks.
class CashUpPage extends StatefulWidget {
  const CashUpPage({
    super.key,
    required this.expectedCash,
    required this.mobileMoneyTotal,
    required this.cardTotal,
    this.zwlRate = 26.0,
  });

  final double expectedCash;
  final double mobileMoneyTotal;
  final double cardTotal;
  final double zwlRate;

  @override
  State<CashUpPage> createState() => _CashUpPageState();
}

class _CashUpPageState extends State<CashUpPage> {
  final _cash = TextEditingController();
  final _zwl = TextEditingController();
  bool _mobileConfirmed = false;
  bool _cardConfirmed = false;
  double? _variance;

  @override
  void dispose() {
    _cash.dispose();
    _zwl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final float = session.openShift?.openingFloat ?? 0;
    final ready = (double.tryParse(_cash.text) ?? -1) >= 0 &&
        _mobileConfirmed &&
        _cardConfirmed;

    return PosScaffold(
      title: 'Close your shift',
      subtitle: 'Count the drawer, then confirm the rest',
      commandBar: false,
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: ready ? () => _close(context, float) : null,
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: AppColors.hairlineStrong,
                disabledForegroundColor: AppColors.placeholder,
              ),
              child: const Text('Close shift'),
            ),
            const SizedBox(height: 10),
            const Text(
              'A supervisor signs this off later',
              style: TextStyle(fontSize: 12, color: AppColors.placeholder),
            ),
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
        children: [
          PaperCard(
            radius: 20,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            borderColor: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'CASH COUNTED · USD',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.9,
                          color: AppColors.mutedLight,
                        ),
                      ),
                    ),
                    Text(
                      'float \$${float.toStringAsFixed(2)} in',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _cash,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.9,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  decoration: const InputDecoration(
                    prefixText: '\$',
                    hintText: '0.00',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          PaperCard(
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Column(
              children: [
                _ConfirmRow(
                  label: 'Mobile money',
                  amount: widget.mobileMoneyTotal,
                  confirmed: _mobileConfirmed,
                  onTap: () =>
                      setState(() => _mobileConfirmed = !_mobileConfirmed),
                ),
                const Divider(),
                _ConfirmRow(
                  label: 'Card',
                  amount: widget.cardTotal,
                  confirmed: _cardConfirmed,
                  onTap: () => setState(() => _cardConfirmed = !_cardConfirmed),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'ZWL cash counted',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _zwl,
                          textAlign: TextAlign.right,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            prefixText: 'Z\$',
                            hintText: '0',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_variance != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.inkSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VARIANCE',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.9,
                            color: Colors.white54,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Cash drawer',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_variance! < 0 ? '−' : '+'}\$${_variance!.abs().toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.84,
                      color: Color(0xFFF6F4F1),
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            AiNote(
              text: _variance! == 0
                  ? 'The drawer balances.'
                  : _variance! < 0
                      ? "You're \$${_variance!.abs().toStringAsFixed(2)} short. "
                          'Worth recounting the coins before you close.'
                      : "You're \$${_variance!.toStringAsFixed(2)} over. "
                          'Check whether change was given short on a sale.',
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _close(BuildContext context, double float) async {
    final counted = double.tryParse(_cash.text) ?? 0;
    final session = context.read<SessionProvider>();

    final closed = session.closeShift(
      countedCash: counted,
      countedCashZwl: double.tryParse(_zwl.text),
      expectedCash: widget.expectedCash,
      mobileMoneyTotal: widget.mobileMoneyTotal,
      cardTotal: widget.cardTotal,
    );
    if (closed == null) return;

    setState(() => _variance = closed.variance);

    // The pattern across shifts is supervisor-only.
    if ((closed.variance ?? 0) != 0 && context.mounted) {
      final shortfalls = session.shifts.values
          .where((s) => (s.variance ?? 0) < 0)
          .length;
      if (shortfalls >= 2) {
        await context.read<AiProvider>().logCashUpPattern(
              'Till 1 short on $shortfalls of the last '
              '${session.shifts.length} cash-ups. Not shown to the assistant.',
            );
      }
    }
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({
    required this.label,
    required this.amount,
    required this.confirmed,
    required this.onTap,
  });

  final String label;
  final double amount;
  final bool confirmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
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
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'from the system · tap to confirm',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.placeholder,
                    ),
                  ),
                ],
              ),
            ),
            Money(amount, size: 16),
            const SizedBox(width: 10),
            Icon(
              confirmed ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: confirmed ? AppColors.primary : AppColors.hairlineStrong,
            ),
          ],
        ),
      ),
    );
  }
}

/// Opening float, shown once at the start of a shift.
class ShiftOpenPage extends StatefulWidget {
  const ShiftOpenPage({super.key, this.zwlRate = 26.0});

  final double zwlRate;

  @override
  State<ShiftOpenPage> createState() => _ShiftOpenPageState();
}

class _ShiftOpenPageState extends State<ShiftOpenPage> {
  double _float = 40;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    return PosScaffold(
      title: 'Open your shift',
      subtitle: '${session.signedIn?.name ?? ''} · today',
      showBack: false,
      commandBar: false,
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
        child: ElevatedButton(
          onPressed: () {
            session.openShiftWithFloat(_float);
            Navigator.pushReplacementNamed(context, '/home');
          },
          child: const Text('Open till'),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
        children: [
          PaperCard(
            radius: 20,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OPENING FLOAT · USD',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.9,
                    color: AppColors.mutedLight,
                  ),
                ),
                const SizedBox(height: 10),
                Money(_float, size: 36),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final amount in [20.0, 40.0, 60.0])
                      GestureDetector(
                        onTap: () => setState(() => _float = amount),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: _float == amount
                                  ? AppColors.primary
                                  : AppColors.hairlineStrong,
                            ),
                          ),
                          child: Text(
                            '\$${amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _float == amount
                                  ? AppColors.primary
                                  : AppColors.ink,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PaperCard(
            radius: 20,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'FLOAT · ZWL',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.9,
                      color: AppColors.mutedLight,
                    ),
                  ),
                ),
                Text(
                  'Z\$${(_float * widget.zwlRate).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
