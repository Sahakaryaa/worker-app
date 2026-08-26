import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

/// Dark gradient hero splash with gold logo reveal.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _routeAfterReveal();
  }

  Future<void> _routeAfterReveal() async {
    // Wait for gold reveal and text animations (2.1s)
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    if (!mounted || _navigated) return;

    final auth = ref.read(authProvider);
    if (auth.isLoading) {
      // Allow bootstrap a short extra moment (up to 1s) to finish reading token/profile
      for (int i = 0; i < 10; i++) {
        if (!ref.read(authProvider).isLoading || !mounted) break;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }

    if (!mounted || _navigated) return;
    _navigated = true;

    final isAuth = ref.read(authProvider).isAuthenticated;
    context.go(isAuth ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (prev, next) {
      // If bootstrap finished and reveal duration has elapsed, navigate immediately
      if (!_navigated && !next.isLoading && prev?.isLoading == true) {
        // Handled naturally by _routeAfterReveal when animation completes
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.nightGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gold logo mark reveal
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppColors.glow(AppColors.gold, alpha: 0.45),
                  ),
                  child:
                      const Icon(Icons.handyman_rounded, color: Colors.white, size: 44),
                )
                    .animate(delay: 150.ms)
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutCubic,
                      duration: 400.ms,
                    )
                    .shimmer(
                      delay: 700.ms,
                      duration: 1100.ms,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                const SizedBox(height: 26),
                Text(
                  'सहकार्य साथी',
                  style: GoogleFonts.sora(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 500.ms).slideY(
                      begin: 0.3,
                      end: 0,
                      curve: Curves.easeOutCubic,
                      duration: 500.ms,
                    ),
                const SizedBox(height: 6),
                Text(
                  'SahaKarya Partner',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldLight,
                    letterSpacing: 2.5,
                  ),
                ).animate().fadeIn(delay: 750.ms, duration: 450.ms),
                const SizedBox(height: 10),
                Text(
                  'Your Cooperative. Your Earnings.\nYour Welfare Fund.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.6,
                    color: Colors.white60,
                  ),
                ).animate().fadeIn(delay: 950.ms, duration: 500.ms),
                const SizedBox(height: 48),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.gold.withValues(alpha: 0.8)),
                  ),
                ).animate().fadeIn(delay: 1200.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
