import 'package:field_pro/firebase_options.dart';
import 'package:field_pro/src/constants/app_colors.dart';
import 'package:field_pro/src/features/authentication/presentation/auth_gate.dart';
import 'package:field_pro/src/features/notifications/notification_service.dart';
import 'package:field_pro/src/features/settings/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  // 1. Setup Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Initialize Push Notifications (The Engine)
  await NotificationService().initialize();

  // 4. Run the App
  runApp(const ProviderScope(child: NovoApp()));
}

class NovoApp extends ConsumerWidget {
  const NovoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the Theme Provider for changes
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Novo Field Pro',
      debugShowCheckedModeBanner: false,

      // Connect the Theme Mode
      themeMode: themeMode,

      // --- LIGHT THEME ---
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        cardColor: Colors.white, // Fixes CardThemeData error

        colorScheme:
            ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ).copyWith(
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              surface: AppColors.surface,
            ),

        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
          ),
        ),
      ),

      // --- DARK THEME ---
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900],
        cardColor: Colors.grey[800], // Fixes CardThemeData error

        colorScheme:
            ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.dark,
            ).copyWith(
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              surface: Colors.grey[850],
            ),

        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
          ),
        ),
      ),

      home: const AuthGate(),
    );
  }
}
