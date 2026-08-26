import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Designed empty state — soft illustration circle + optional CTA.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final Color iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCta,
    this.iconColor = AppColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    // Ambient "breathing" loop is decorative — disabled under the OS
    // remove-animations accessibility setting (motion tier policy).
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final iconCircle = Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 38, color: iconColor),
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reduceMotion)
              iconCircle
            else
              iconCircle
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1, end: 1.05, duration: 1600.ms, curve: Curves.easeInOut),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: AppColors.inkSoft,
              ),
            ),
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: 18),
              FilledButton.tonal(
                onPressed: onCta,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold.withValues(alpha: 0.12),
                  foregroundColor: AppColors.goldDark,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(ctaLabel!,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0);
  }
}
