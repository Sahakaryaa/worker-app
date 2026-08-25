import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../utils/formatting.dart';

/// Circular avatar with gold gradient ring + online status dot.
class AvatarBadge extends StatelessWidget {
  final String name;
  final double radius;
  final bool online;
  final bool showStatusDot;

  const AvatarBadge({
    super.key,
    required this.name,
    this.radius = 26,
    this.online = false,
    this.showStatusDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final inner = radius * 2 - 6;
    return SizedBox(
      width: radius * 2 + 8,
      height: radius * 2 + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              gradient: AppColors.goldGradient,
              shape: BoxShape.circle,
            ),
            child: Container(
              width: inner,
              height: inner,
              decoration: BoxDecoration(
                color: AppColors.night1,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initialsOf(name),
                style: GoogleFonts.sora(
                  fontSize: radius * 0.62,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (showStatusDot)
            Positioned(
              right: -1,
              bottom: -1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: radius * 0.44 + 4,
                height: radius * 0.44 + 4,
                decoration: BoxDecoration(
                  color: online ? AppColors.success : AppColors.inkFaint,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
