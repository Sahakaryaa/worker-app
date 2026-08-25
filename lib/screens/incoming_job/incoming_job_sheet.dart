import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/incoming_job_provider.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatting.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snack_bar.dart';

/// Slide-up radius-28 offer panel shown via the ROOT navigator so it appears
/// over ANY tab. Circular 60s countdown ring; auto-decline only at zero.
class IncomingJobSheet extends ConsumerWidget {
  const IncomingJobSheet({super.key});

  /// Show through the root navigator from anywhere in the widget tree.
  static Future<void> show([BuildContext? context]) {
    final navContext = (context != null && Navigator.maybeOf(context) != null)
        ? context
        : rootNavigatorKey.currentContext;
    if (navContext == null) return Future.value();

    return showModalBottomSheet(
      context: navContext,
      useRootNavigator: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.night1.withValues(alpha: 0.55),
      builder: (_) => const IncomingJobSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(incomingJobProvider);
    final job = state.currentOffer;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    if (job == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(left: 14, right: 14, bottom: 18 + bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.25),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gold gradient header strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: const BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.isEmergency
                              ? '⚡ Emergency dispatch nearby'
                              : 'New job offer nearby',
                          style: GoogleFonts.sora(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Respond within ${state.secondsRemaining}s to accept',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CountdownRing(secondsRemaining: state.secondsRemaining),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(
                children: [
                  // Detail chips row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip(Icons.handyman_rounded, titleCase(job.serviceType.isEmpty ? 'Service' : job.serviceType)),
                        const SizedBox(width: 8),
                        _chip(Icons.near_me_rounded, job.distanceFormatted.isEmpty ? '—' : job.distanceFormatted),
                        const SizedBox(width: 8),
                        _chip(Icons.payments_rounded, '₹${job.price.toStringAsFixed(0)} payout',
                            highlight: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 18, color: AppColors.goldDark),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          job.customerAddress.isEmpty
                              ? 'Address will be shared after acceptance'
                              : '${job.customerAddress} • ${job.customerName}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '5% of this job goes to your welfare fund — ₹${job.welfareContribution.toStringAsFixed(1)}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Actions
                  PulsingAcceptButton(onAccept: () => _accept(context, ref)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: TextButton(
                      onPressed: () => _decline(context, ref),
                      style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                      child: Text(
                        'Decline',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _accept(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(incomingJobProvider.notifier);
    final navContext = rootNavigatorKey.currentContext ?? context;
    await notifier.acceptCurrentOffer();
    if (!context.mounted) return;
    final err = ref.read(incomingJobProvider).lastError;
    if (err != null) {
      // Keep the sheet open — countdown resumes for retry.
      notifier.consumeError();
      AppSnackBar.show(context, err, type: SnackType.error);
      return;
    }
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (navContext.mounted) {
      GoRouter.of(navContext).go('/active-job');
    }
  }

  void _decline(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    await ref.read(incomingJobProvider.notifier).declineCurrentOffer();
    if (!context.mounted) return;
    final err = ref.read(incomingJobProvider).lastError;
    if (err != null) {
      ref.read(incomingJobProvider.notifier).consumeError();
      AppSnackBar.show(context, err, type: SnackType.warning);
    }
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  static Widget _chip(IconData icon, String label, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.gold.withValues(alpha: 0.13)
            : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlight
              ? AppColors.gold.withValues(alpha: 0.45)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 15,
              color: highlight ? AppColors.goldDark : AppColors.inkSoft),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: highlight ? AppColors.goldDark : AppColors.inkSoft,
              )),
        ],
      ),
    );
  }
}

/// Circular countdown ring (60s), turns red under 10s.
class CountdownRing extends StatelessWidget {
  final int secondsRemaining;
  static const int total = kOfferCountdownSeconds;

  const CountdownRing({super.key, required this.secondsRemaining});

  @override
  Widget build(BuildContext context) {
    final progress = (secondsRemaining / total).clamp(0.0, 1.0);
    final urgent = secondsRemaining <= 10;
    final color = urgent ? AppColors.danger : Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: progress - 1 / total, end: progress),
      duration: const Duration(milliseconds: 300),
      curve: Curves.linear,
      builder: (context, p, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: p.clamp(0.0, 1.0),
                  color: color,
                  trackColor: Colors.white24,
                ),
              ),
            ),
            Text(
              '$secondsRemaining',
              style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 3;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..shader = AppColors.goldGradient.createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, -2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Big gold CTA that pulses until pressed.
class PulsingAcceptButton extends StatefulWidget {
  final VoidCallback onAccept;
  const PulsingAcceptButton({super.key, required this.onAccept});

  @override
  State<PulsingAcceptButton> createState() => _PulsingAcceptButtonState();
}

class _PulsingAcceptButtonState extends State<PulsingAcceptButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return AppButton(label: 'Accept Job', icon: Icons.check_circle_rounded,
          onPressed: widget.onAccept);
    }
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.03)
          .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: AppButton(
        label: 'Accept Job',
        icon: Icons.check_circle_rounded,
        haptic: true,
        onPressed: widget.onAccept,
      ),
    );
  }
}
