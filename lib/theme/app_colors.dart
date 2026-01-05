import 'package:flutter/material.dart';

class AppColors {
  // ===========================================================================
  // 🌑 EXISTING COLORS (Restored to prevent errors)
  // ===========================================================================
  // These are your original dark mode colors. Keeping them static ensures
  // old code doesn't break, but they won't automatically switch to light mode.

  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textTertiary = Color(0xFF838383);

  static final Color border = Colors.grey.shade900;

  // Shared Colors (Brand)
  static const Color primary = Color(0xFF00AE62);
  static const Color accent = Color(0xFF00AE62);
  static const Color like = primary;

  // ===========================================================================
  // ☀️ NEW: LIGHT MODE COLORS
  // ===========================================================================
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Colors.white;

  static const Color textPrimaryLight = Colors.black;
  static const Color textSecondaryLight = Color(0xFF616161);
  static const Color textTertiaryLight = Color(0xFF9E9E9E);

  static final Color borderLight = Colors.grey.shade300;
}