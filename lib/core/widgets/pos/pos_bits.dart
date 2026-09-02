import 'package:flutter/material.dart';

import '../../themes/colors.dart';

/// Small shared pieces so every screen reads the same. Kept in one file
/// deliberately: they are presentation-only and always used together.

/// The eyebrow label above a group, e.g. "WHAT NEEDS YOU TODAY".
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: AppColors.primary),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 0.9,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paper card with a hairline border. No shadows anywhere except the command bar.
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(17),
    this.borderColor = AppColors.hairline,
    this.background = AppColors.surface,
    this.radius = 18,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color borderColor;
  final Color background;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
    if (onTap == null) return body;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: body,
    );
  }
}

/// The blue-tinted block used for every AI aside.
class AiNote extends StatelessWidget {
  const AiNote({super.key, required this.text, this.title, this.actions});

  final String text;
  final String? title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryTintBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.auto_awesome, size: 15, color: AppColors.primary),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) ...[
                      Text(
                        title!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF183A6B),
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.primaryTintInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (actions != null) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: actions!),
          ],
        ],
      ),
    );
  }
}

/// A bin chip: location code plus the quantity sitting in it.
class BinChip extends StatelessWidget {
  const BinChip({super.key, required this.code, required this.quantity});

  final String code;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: code),
            const TextSpan(text: '  '),
            TextSpan(
              text: '$quantity',
              style: const TextStyle(color: AppColors.mutedLight),
            ),
          ],
        ),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Money, always tabular so columns never jitter.
class Money extends StatelessWidget {
  const Money(
    this.amount, {
    super.key,
    this.size = 17,
    this.weight = FontWeight.w600,
    this.color,
    this.symbol = '\$',
  });

  final double amount;
  final double size;
  final FontWeight weight;
  final Color? color;
  final String symbol;

  @override
  Widget build(BuildContext context) => Text(
        '$symbol${amount.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: size,
          fontWeight: weight,
          letterSpacing: -0.4,
          color: color ?? AppColors.ink,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
}

/// Rounded stack of rows, the pattern used for lists throughout.
class StackedList extends StatelessWidget {
  const StackedList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 1),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.hairline),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(i == 0 ? 14 : 4),
                bottom: Radius.circular(i == children.length - 1 ? 14 : 4),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: children[i],
          ),
        ],
      ],
    );
  }
}
