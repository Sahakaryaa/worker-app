import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:device_preview/device_preview.dart';
import 'theme/app_colors.dart';
import 'router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    DevicePreview(
      enabled: kIsWeb,
      builder: (context) => const ProviderScope(
        child: SahaKaryaWorkerApp(),
      ),
    ),
  );
}

/// SahaKarya Partner (सहकार्य साथी) — Cooperative Gig Worker App
class SahaKaryaWorkerApp extends StatelessWidget {
  final bool useDevicePreview;

  const SahaKaryaWorkerApp({
    super.key,
    this.useDevicePreview = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool enablePreview = useDevicePreview && kIsWeb;
    final effectiveLocale =
        enablePreview ? DevicePreview.locale(context) : null;
    final effectiveBuilder =
        enablePreview ? DevicePreview.appBuilder : null;

    return MaterialApp.router(
      title: 'SahaKarya Partner (सहकार्य साथी)',
      debugShowCheckedModeBanner: false,
      locale: effectiveLocale,
      builder: effectiveBuilder,
      scrollBehavior: const AppScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.orange,
          primary: AppColors.orange,
          secondary: AppColors.teal,
          surface: AppColors.surface,
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).copyWith(
          headlineLarge: GoogleFonts.sora(fontWeight: FontWeight.w700, color: AppColors.ink),
          headlineMedium: GoogleFonts.sora(fontWeight: FontWeight.w700, color: AppColors.ink),
          titleLarge: GoogleFonts.sora(fontWeight: FontWeight.w600, color: AppColors.ink),
          titleMedium: GoogleFonts.sora(fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.sora(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}

/// Unified Kinetic Scroll Physics for desktop, mobile, and web previews
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
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}
