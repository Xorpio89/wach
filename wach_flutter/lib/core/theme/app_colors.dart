import 'package:flutter/material.dart';

/// W.A.C.H. Color Palette
/// Dark Mode optimized for gym use
abstract final class AppColors {
  // Background Colors
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const surfaceVariant = Color(0xFF2C2C2C);

  // Primary - Green (Growth/Wachstum)
  static const primary = Color(0xFF4CAF50);
  static const primaryLight = Color(0xFF81C784);
  static const primaryDark = Color(0xFF388E3C);

  // Secondary - Orange (Activity/Energy)
  static const secondary = Color(0xFFFF9800);
  static const secondaryLight = Color(0xFFFFB74D);
  static const secondaryDark = Color(0xFFF57C00);

  // Accent - For achievements/PR
  static const accent = Color(0xFFFFD700);

  // Text Colors
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0B0);
  static const textDisabled = Color(0xFF666666);

  // Semantic Colors
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFE53935);
  static const info = Color(0xFF2196F3);

  // Timer Colors
  static const timerDefault = textPrimary;
  static const timerBetter = primary; // Beating previous time
  static const timerWorse = error; // Behind previous time

  // Progress Colors
  static const progressBackground = surfaceVariant;
  static const progressFill = primary;
}
