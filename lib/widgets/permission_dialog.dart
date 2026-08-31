import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Interactive permission explainer modal for SahaKarya Partner location access.
class WorkerLocationPermissionDialog extends StatelessWidget {
  final bool isPermanentlyDenied;

  const WorkerLocationPermissionDialog({
    super.key,
    this.isPermanentlyDenied = false,
  });

  static Future<bool> show(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return true;
    }

    if (!context.mounted) return false;

    final isPermanentlyDenied = permission == LocationPermission.deniedForever;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkerLocationPermissionDialog(
        isPermanentlyDenied: isPermanentlyDenied,
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 24),

          // Illustration icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.near_me_rounded,
                size: 42,
                color: AppColors.goldDark,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Location Needed for Job Dispatch',
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),

          // Body
          Text(
            'To receive high-paying nearby jobs in your area and share real-time arrival with customers, SahaKarya Partner requires location access while you are Online.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 24),

          // Privacy promise pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Zero background tracking when Offline',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                if (isPermanentlyDenied) {
                  await Geolocator.openAppSettings();
                  if (context.mounted) Navigator.of(context).pop(false);
                } else {
                  final p = await Geolocator.requestPermission();
                  final granted = p == LocationPermission.whileInUse ||
                      p == LocationPermission.always;
                  if (context.mounted) Navigator.of(context).pop(granted);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                isPermanentlyDenied ? 'Open App Settings' : 'Allow Location & Go Online',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Secondary Dismiss
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Stay Offline for Now',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
