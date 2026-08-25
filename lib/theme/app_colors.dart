import 'package:flutter/material.dart';

/// SahaKarya "Luxe" design tokens (DESIGN_SPEC.md).
/// Worker app: same system as customer app but PRIMARY GRADIENT = Amber/Gold
/// for earnings identity; indigo reserved for informational accents.
class AppColors {
  AppColors._();

  // Surfaces & backgrounds
  static const Color bg = Color(0xFFF6F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEEF0F7);

  // Ink
  static const Color ink = Color(0xFF101828);
  static const Color inkSoft = Color(0xFF667085);
  static const Color inkFaint = Color(0xFF98A2B3);
  static const Color border = Color(0xFFE4E7EF);

  // Primary — worker-app gold (earnings identity)
  static const Color gold = Color(0xFFF59E0B);
  static const Color goldLight = Color(0xFFFBBF24);
  static const Color goldDark = Color(0xFFD97706);

  // Informational accent — indigo (never default Material blue)
  static const Color indigo = Color(0xFF5B5FE9);
  static const Color indigoLight = Color(0xFF8E7CF0);
  static const Color indigoDeep = Color(0xFF6A5AE0);

  // Semantic feedback
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);

  // Dark hero surfaces
  static const Color night1 = Color(0xFF0B1220);
  static const Color night2 = Color(0xFF111A2C);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );

  static const LinearGradient indigoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6A5AE0), Color(0xFF8E7CF0)],
  );

  static const LinearGradient nightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B1220), Color(0xFF111A2C)],
  );

  /// Soft shadow per spec: rgba(16,24,40,0.08), blur 24, offset (0,8).
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x14101828),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glow(Color color, {double alpha = 0.35}) => [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
}
