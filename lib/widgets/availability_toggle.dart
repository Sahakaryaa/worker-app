import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../providers/availability_provider.dart';

/// Hero Availability Toggle element per 03-worker-app-flutter.md §4.
/// Prominently displays online/offline readiness with AnimatedContainer transition.
class AvailabilityToggle extends ConsumerWidget {
  const AvailabilityToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(availabilityProvider);

    return GestureDetector(
      onTap: () => ref.read(availabilityProvider.notifier).toggle(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isOnline ? AppColors.orange : const Color(0xFFE0DDD5),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isOnline
                  ? AppColors.orange.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isOnline ? 12 : 4,
              offset: const Offset(0, 3),
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
            const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? Colors.white : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
