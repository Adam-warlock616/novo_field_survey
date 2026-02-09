import 'package:field_pro/src/features/authentication/data/auth_repository.dart';
import 'package:field_pro/src/features/authentication/presentation/login_screen.dart';
import 'package:field_pro/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the Stream (Real-time connection to Firebase)
    final authState = ref.watch(authStateChangesProvider);

    // 2. Decide what to show
    return authState.when(
      data: (user) {
        if (user != null) {
          // User is logged in!
          return const DashboardScreen();
        } else {
          // User is NOT logged in
          return const LoginScreen();
        }
      },
      // If Firebase is loading (rarely seen), show a blank loader
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      // If something breaks, show error
      error: (e, trace) => Scaffold(body: Center(child: Text("Error: $e"))),
    );
  }
}
