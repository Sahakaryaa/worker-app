import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'incoming_offer_host.dart';
import 'router.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SahaKaryaWorkerApp()));
}

/// SahaKarya Partner (सहकार्य साथी) — Cooperative Gig Worker App.
class SahaKaryaWorkerApp extends ConsumerWidget {
  const SahaKaryaWorkerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SahaKarya Partner',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: _buildTheme(context),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) =>
          IncomingOfferHost(child: child ?? const SizedBox.shrink()),
    );
  }

  ThemeData _buildTheme(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.gold,
        primary: AppColors.goldDark,
        secondary: AppColors.indigo,
        error: AppColors.danger,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSurface: AppColors.ink,
      ),
    );

    return base.copyWith(
      textTheme:
          GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.sora(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.ink),
        displayMedium: GoogleFonts.sora(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.ink),
        headlineLarge: GoogleFonts.sora(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.ink),
        headlineMedium: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
        headlineSmall: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
        titleLarge: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
        titleMedium: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
        bodyMedium: GoogleFonts.inter(fontSize: 15, height: 1.45, color: AppColors.ink),
        bodySmall: GoogleFonts.inter(fontSize: 12, height: 1.4, color: AppColors.inkSoft),
        labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.sora(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface,
        contentTextStyle: GoogleFonts.inter(
            fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.goldDark,
        linearTrackColor: AppColors.surfaceAlt,
      ),
    );
  }
}

/// Unified kinetic scroll physics for touch/desktop/web.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
