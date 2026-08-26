import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../session/session_provider.dart';
import '../../themes/colors.dart';
import 'command_bar.dart';

/// Every screen sits in this: paper background, a header line that always says
/// which mode you are in, and the command bar pinned to the bottom unless a
/// sale owns that edge.
class PosScaffold extends StatelessWidget {
  const PosScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.showBack = true,
    this.commandBar = true,
    this.bottom,
    this.cartProductIds = const [],
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final bool showBack;
  final bool commandBar;

  /// Owns the bottom edge instead of the command bar, e.g. a pay button.
  final Widget? bottom;
  final List<String> cartProductIds;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(showBack ? 20 : 22, 8, 20, 14),
              child: Row(
                children: [
                  if (showBack)
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 14),
                        child: Icon(Icons.arrow_back, size: 20),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.34,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subtitle ?? session.modeLine,
                          style: TextStyle(
                            fontSize: 12,
                            color: session.canSeeMoney
                                ? AppColors.primary
                                : AppColors.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            Expanded(child: child),
            if (bottom != null)
              bottom!
            else if (commandBar)
              CommandBar(cartProductIds: cartProductIds),
          ],
        ),
      ),
    );
  }
}

/// The padlock in the header. Tap to unlock supervisor views in place; tap again
/// to lock. Privilege also drops on its own when a new sale starts.
class SupervisorPadlock extends StatelessWidget {
  const SupervisorPadlock({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final unlocked = session.canSeeMoney;

    return GestureDetector(
      onTap: () => unlocked ? session.lock() : _promptPin(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: unlocked ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unlocked ? AppColors.primary : AppColors.hairline,
          ),
        ),
        child: Icon(
          unlocked ? Icons.lock_open : Icons.lock_outline,
          size: 16,
          color: unlocked ? Colors.white : AppColors.mutedLight,
        ),
      ),
    );
  }

  Future<void> _promptPin(BuildContext context) async {
    final controller = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );
    if (pin == null || !context.mounted) return;
    if (!context.read<SessionProvider>().unlockSupervisor(pin)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PIN not recognised')));
    }
  }
}
