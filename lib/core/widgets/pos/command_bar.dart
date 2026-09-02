import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../ai/ai_provider.dart';
import '../../themes/colors.dart';
import 'answer_sheet.dart';

/// The spine of the AI experience: a bar pinned to the bottom of every screen
/// that expands into an answer sheet.
///
/// It yields during an active sale — the pay button owns the bottom edge then —
/// so pass `visible: cart.isEmpty` from the scaffold.
class CommandBar extends StatelessWidget {
  const CommandBar({
    super.key,
    this.visible = true,
    this.cartProductIds = const [],
    this.hint = 'Ask anything',
  });

  final bool visible;
  final List<String> cartProductIds;
  final String hint;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: GestureDetector(
          onTap: () => _open(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.hairlineStrong),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F141210),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.placeholder,
                    ),
                  ),
                ),
                const Icon(Icons.mic_none, size: 18, color: AppColors.placeholder),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x6B16161A),
      builder: (_) => ChangeNotifierProvider<AiProvider>.value(
        value: context.read<AiProvider>(),
        child: AskSheet(cartProductIds: cartProductIds),
      ),
    );
  }
}

/// The expanded bar: a text field and nothing else. No starter prompts, by
/// design — they crowded the sheet and taught nothing after the first day.
class AskSheet extends StatefulWidget {
  const AskSheet({super.key, this.cartProductIds = const []});

  final List<String> cartProductIds;

  @override
  State<AskSheet> createState() => _AskSheetState();
}

class _AskSheetState extends State<AskSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairlineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (ai.state == AskState.idle) _field(context) else const SizedBox.shrink(),
            if (ai.state != AskState.idle)
              Flexible(child: AnswerSheetBody(onAskAgain: _reset)),
          ],
        ),
      ),
    );
  }

  void _reset() {
    context.read<AiProvider>().dismiss();
    _controller.clear();
  }

  Widget _field(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.send,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'Ask anything',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (value) {
                if (value.trim().isEmpty) return;
                context
                    .read<AiProvider>()
                    .ask(value, cartProductIds: widget.cartProductIds);
              },
            ),
          ),
          const Icon(Icons.mic_none, size: 18, color: AppColors.placeholder),
        ],
      ),
    );
  }
}
