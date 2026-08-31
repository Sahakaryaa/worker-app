import 'package:flutter/material.dart';

/// SahaKarya "Luxe" design tokens (DESIGN_SPEC.md).
/// Worker app: same system as customer app but PRIMARY GRADIENT = Amber/Gold
/// for earnings identity; indigo reserved for informational accents.
class AppColors {
  AppColors._();

  // Surfaces & backgrounds
  static const Color bg = Color(0xFFF7FAF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEDF2EE);

  // Ink
  static const Color ink = Color(0xFF101F19);
  static const Color inkSoft = Color(0xFF4E6158);
  static const Color inkFaint = Color(0xFF82968D);
  static const Color border = Color(0xFFDFE7E2);

  // Primary brand — Sahakarya Forest Green
  static const Color primary = Color(0xFF0D5238);
  static const Color primaryDeep = Color(0xFF093F2B);
  static const Color primaryLight = Color(0xFF137A54);
  static const Color teal = primary;

  // Earnings & worker accent — Sahakarya Amber / Gold
  static const Color gold = Color(0xFFF5A623);
  static const Color goldLight = Color(0xFFF8B63B);
  static const Color goldDark = Color(0xFFD98A12);
  static const Color amber = gold;

  // Accent / Informational — Green / Emerald
  static const Color indigo = Color(0xFF0D5238);
  static const Color indigoLight = Color(0xFF137A54);
  static const Color indigoDeep = Color(0xFF093F2B);

  // Semantic feedback
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);

  // Dark hero surfaces
  static const Color night1 = Color(0xFF091612);
  static const Color night2 = Color(0xFF0E1F1A);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5A623), Color(0xFFF8B63B)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF093F2B), Color(0xFF137A54)],
  );

  static const LinearGradient indigoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF093F2B), Color(0xFF137A54)],
  );

  static const LinearGradient nightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF091612), Color(0xFF0E1F1A)],
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
