import 'package:field_pro/src/features/authentication/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_pro/src/constants/app_colors.dart'; // Import your colors

void main() {
  runApp(const ProviderScope(child: NovoApp()));
}

class NovoApp extends StatelessWidget {
  const NovoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Novo Field Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // This sets the color globally
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          background: AppColors.background,
        ),

        // Style your App Bar automatically
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white, // Text color on AppBar
          elevation: 0,
        ),

        // Style your Floating Action Buttons (FAB)
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
        ),
      ),
      home: const LoginScreen(), // Start with the Login Screen
    );
  }
}
