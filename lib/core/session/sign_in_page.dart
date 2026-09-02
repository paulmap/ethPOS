import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../themes/colors.dart';
import '../widgets/pos/pos_bits.dart';
import 'session_provider.dart';

/// Sign-in: pick who is at the till, then four digits. Every member of the
/// roster is listed, assistants included — the padlock in the header is for
/// raising privilege mid-shift, not for signing in.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  Staff? _picked;
  String _pin = '';
  bool _wrong = false;

  void _tap(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += digit;
      _wrong = false;
    });
    if (_pin.length == 4) _submit();
  }

  void _back() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _wrong = false;
    });
  }

  void _submit() {
    final staff = _picked;
    if (staff == null) return;
    final ok = context.read<SessionProvider>().signIn(staff.id, _pin);
    if (!ok) {
      HapticFeedback.heavyImpact();
      setState(() {
        _wrong = true;
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.read<SessionProvider>().staff;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 30, 22, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ethPOS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _picked == null
                    ? 'Who is on the till?'
                    : 'Enter ${_picked!.name.split(' ').first}\u2019s PIN',
                style: const TextStyle(fontSize: 13, color: AppColors.mutedLight),
              ),
              const SizedBox(height: 26),
              if (_picked == null)
                Expanded(
                  child: SingleChildScrollView(
                    child: StackedList(
                      children: [
                        for (final person in staff)
                          _StaffRow(
                            staff: person,
                            onTap: () => setState(() {
                              _picked = person;
                              _pin = '';
                              _wrong = false;
                            }),
                          ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(child: _keypad()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _keypad() {
    return Column(
      children: [
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                width: 13,
                height: 13,
                margin: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length
                      ? (_wrong ? AppColors.error : AppColors.ink)
                      : Colors.transparent,
                  border: Border.all(
                    color: _wrong ? AppColors.error : AppColors.hairlineStrong,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          _wrong ? 'PIN not recognised' : ' ',
          style: const TextStyle(fontSize: 12, color: AppColors.error),
        ),
        const Spacer(),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                for (final key in row) ...[
                  Expanded(child: _Key(label: key, onTap: () => _tap(key))),
                  if (key != row.last) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _Key(
                label: 'Back',
                small: true,
                onTap: () => setState(() {
                  _picked = null;
                  _pin = '';
                  _wrong = false;
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _Key(label: '0', onTap: () => _tap('0'))),
            const SizedBox(width: 10),
            Expanded(
              child: _Key(icon: Icons.backspace_outlined, onTap: _back),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({required this.staff, required this.onTap});

  final Staff staff;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final supervisor = staff.role == StaffRole.supervisor;
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              staff.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  supervisor ? 'Supervisor' : 'Sales assistant',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, size: 17, color: AppColors.placeholder),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({this.label, this.icon, required this.onTap, this.small = false});

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 62,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline),
        ),
        child: icon != null
            ? Icon(icon, size: 20, color: AppColors.muted)
            : Text(
                label!,
                style: TextStyle(
                  fontSize: small ? 14 : 23,
                  fontWeight: small ? FontWeight.w500 : FontWeight.w400,
                  color: small ? AppColors.muted : AppColors.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
      ),
    );
  }
}
