import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../session/session_provider.dart';
import '../../session/sign_in_page.dart';
import 'home_page.dart';

/// The app's `home`. Nobody reaches the till without signing in, and signing
/// out returns here rather than leaving a half-authorised screen on the glass.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = context.watch<SessionProvider>().isSignedIn;
    return signedIn ? const HomePage() : const SignInPage();
  }
}
