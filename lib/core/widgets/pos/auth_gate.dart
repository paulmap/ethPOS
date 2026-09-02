import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../session/session_provider.dart';
import '../../session/sign_in_page.dart';
import '../../../features/sales/presentation/pages/cash_up_page.dart';
import 'home_page.dart';

/// The app's `home`. Nobody reaches the till without signing in, opening a shift,
/// and signing out returns here rather than leaving a half-authorised screen on the glass.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    // Check signin state first
    if (!session.isSignedIn) {
      return const SignInPage();
    }

    // Check if a shift is open
    if (session.openShift == null) {
      return const ShiftOpenPage();
    }

    // All good: signed in and shift is open
    return const HomePage();
  }
}
