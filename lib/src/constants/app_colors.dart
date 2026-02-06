import 'package:flutter/material.dart';

class AppColors {
  // Based on "Go Green, Go Solar" branding
  static const Color primary = Color(
    0xFF4CAF50,
  ); // Eco Green (Primary Brand Color)
  static const Color secondary = Color(
    0xFFFF9800,
  ); // Solar Orange (Accent/Buttons)

  // Neutral Colors for UI
  static const Color background = Color(
    0xFFF5F5F5,
  ); // Light Grey (Easy on eyes)
  static const Color surface = Colors.white; // Cards and Sheets
  static const Color textPrimary = Color(
    0xFF212121,
  ); // Dark Grey (Not pure black)
  static const Color textSecondary = Color(0xFF757575); // Lighter Grey

  // Status Colors
  static const Color success = Color(0xFF43A047); // Survey Saved
  static const Color error = Color(0xFFD32F2F); // Network Error
}
