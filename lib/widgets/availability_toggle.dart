import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/availability_provider.dart';
import '../theme/app_colors.dart';

/// Large animated availability switch with online/offline color morph
/// and pulsing live radar when online.
class AvailabilityToggle extends ConsumerStatefulWidget {
  final bool dark; // placed on dark hero backgrounds

  const AvailabilityToggle({super.key, this.dark = true});

  @override
  ConsumerState<AvailabilityToggle> createState() => _AvailabilityToggleState();
}

class _AvailabilityToggleState extends ConsumerState<AvailabilityToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
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
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: isOnline ? AppColors.goldGradient : null,
          color: isOnline
              ? null
              : (widget.dark ? Colors.white.withValues(alpha: 0.08) : AppColors.surfaceAlt),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: !widget.dark || !isOnline
                ? AppColors.border.withValues(alpha: widget.dark ? 0.2 : 1)
                : Colors.transparent,
          ),
          boxShadow: isOnline
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isOnline ? Icons.wifi_tethering_rounded : Icons.wifi_off_rounded,
                      key: ValueKey(isOnline),
                      size: 22,
                      color: isOnline
                          ? Colors.white
                          : (widget.dark ? Colors.white60 : AppColors.inkSoft),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isOnline ? 'Online — receiving jobs' : 'Offline — tap to go online',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: isOnline
                            ? Colors.white
                            : (widget.dark ? Colors.white70 : AppColors.inkSoft),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Switch pill
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                return Container(
                  width: 58,
                  height: 30,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? Colors.white.withValues(alpha: 0.25)
                        : (widget.dark
                            ? Colors.white.withValues(alpha: 0.06)
                            : AppColors.border.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment:
                      isOnline ? Alignment.centerRight : Alignment.centerLeft,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (isOnline &&
                          !(MediaQuery.maybeOf(context)?.disableAnimations ?? false))
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              width: 24 + 14 * _pulse.value,
                              height: 24 + 14 * _pulse.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white
                                    .withValues(alpha: (1 - _pulse.value) * 0.35),
                              ),
                            ),
                          ),
                        ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.white : AppColors.surface,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Color(0x33101828), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: isOnline
                            ? const Icon(Icons.bolt_rounded,
                                size: 15, color: AppColors.goldDark)
                            : Icon(Icons.nightlight_round,
                                size: 13, color: AppColors.inkFaint),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
