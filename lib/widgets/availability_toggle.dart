import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../providers/availability_provider.dart';

/// Hero Availability Toggle element per 03-worker-app-flutter.md §4 & 08-flutter-immersive-ui-skill.md §4.6.
/// Prominently displays online/offline readiness with spring motion, haptic pulse, and live radar wave.
class AvailabilityToggle extends ConsumerStatefulWidget {
  const AvailabilityToggle({super.key});

  @override
  ConsumerState<AvailabilityToggle> createState() => _AvailabilityToggleState();
}

class _AvailabilityToggleState extends ConsumerState<AvailabilityToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(availabilityProvider);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        ref.read(availabilityProvider.notifier).toggle();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.elasticOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isOnline ? AppColors.orange : const Color(0xFFE0DDD5),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isOnline
                  ? AppColors.orange.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isOnline ? 16 : 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                key: ValueKey<bool>(isOnline),
                color: isOnline ? Colors.white : AppColors.inkLight,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isOnline ? 'Online — Ready for Jobs' : 'Offline — Tap to go Online',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isOnline ? Colors.white : AppColors.ink,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 10),

            // Live status dot with pulse radar when online
            if (isOnline)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 10 + (12 * _pulseController.value),
                        height: 10 + (12 * _pulseController.value),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(
                            alpha: (1.0 - _pulseController.value) * 0.7,
                          ),
                        ),
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              )
            else
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
