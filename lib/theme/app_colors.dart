import 'package:flutter/material.dart';

/// Centralized design tokens for SahaKarya Partner (सहकार्य साथी).
/// Orange-forward operational palette with cooperative teal institutional accents.
class AppColors {
  // Primary operational & action color
  static const Color orange = Color(0xFFFF6B35);
  static const Color orangeDark = Color(0xFFE85924);
  static const Color orangeLight = Color(0xFFFF8B5E);

  // Cooperative & institutional trust color
  static const Color teal = Color(0xFF1B4B43);
  static const Color tealDark = Color(0xFF133630);
  static const Color tealLight = Color(0xFF26655B);

  // Secondary accent & ratings
  static const Color gold = Color(0xFFFFC145);
  static const Color goldDark = Color(0xFFE5A825);

  // Surface & backgrounds
  static const Color bg = Color(0xFFF7F3E9); // Warm ivory
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEFEBE0);

  // Typography & ink
  static const Color ink = Color(0xFF1A1A1A);
  static const Color inkLight = Color(0xFF4A4A4A);
  static const Color inkMuted = Color(0xFF757575);
  static const Color border = Color(0xFFE2DDD0);

  // Semantic feedback
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFED6C02);
  static const Color info = Color(0xFF0288D1);

  // Gradients
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF8B5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF1B4B43), Color(0xFF26655B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1B4B43), Color(0xFF133630)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
