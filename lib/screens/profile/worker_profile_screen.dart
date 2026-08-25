import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/availability_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatting.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/avatar_badge.dart';
import '../../widgets/availability_toggle.dart';
import '../../widgets/cooperative_badge.dart';
import '../../widgets/status_chip.dart';

/// Profile — AvatarBadge header, certification StatusChip, editable
/// availability and logout.
class WorkerProfileScreen extends ConsumerWidget {
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isOnline = ref.watch(availabilityProvider);
    final worker = auth.profile;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Partner Profile',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
        children: [
          // ---------------- Header card ----------------
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppColors.nightGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              children: [
                AvatarBadge(name: worker?.name ?? '', online: isOnline, radius: 34),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        worker?.name.isEmpty ?? true ? 'Partner' : (worker!.name),
                        style: GoogleFonts.sora(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const CooperativeBadge(isCompact: true),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  worker?.phone.isEmpty ?? true
                      ? '—'
                      : '+91 ${worker!.phone}',
                  style:
                      GoogleFonts.inter(fontSize: 13, color: Colors.white60),
                ),
                const SizedBox(height: 10),
                StatusChip.certification(worker?.certification ?? 'pending'),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: .12), height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _metric(
                        icon: Icons.star_rounded,
                        value: worker == null || worker.rating <= 0
                            ? '—'
                            : worker.rating.toStringAsFixed(1),
                        label: 'Rating',
                      ),
                    ),
                    Container(width: 1, height: 30, color: Colors.white24),
                    Expanded(
                      child: _metric(
                        icon: Icons.work_history_rounded,
                        value: '${worker?.totalJobs ?? 0}',
                        label: 'Total jobs',
                      ),
                    ),
                    Container(width: 1, height: 30, color: Colors.white24),
                    Expanded(
                      child: _metric(
                        icon: Icons.handyman_rounded,
                        value: '${worker?.skills.length ?? 0}',
                        label: 'Skills',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),

          const SizedBox(height: 16),

          // Availability editor
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text('Availability',
                style: GoogleFonts.sora(
                    fontSize: 15.5, fontWeight: FontWeight.w800)),
          ),
          const AvailabilityToggle(dark: false),

          const SizedBox(height: 18),

          // Skills card
          if (worker != null && worker.skills.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text('Certified trade skills',
                  style: GoogleFonts.sora(
                      fontSize: 15.5, fontWeight: FontWeight.w800)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: worker.skills
                  .map((skill) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded,
                                size: 13, color: AppColors.goldDark),
                            const SizedBox(width: 5),
                            Text(titleCase(skill),
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.goldDark)),
                          ],
                        ),
                      ))
                  .toList(),
            )
                .animate(delay: 60.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.08, end: 0),
            const SizedBox(height: 20),
          ],

          // Federation info
          if ((worker?.federationId ?? '').isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.indigo.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.indigo.withValues(alpha: 0.22)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_membership_rounded,
                      size: 19, color: AppColors.indigo),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Federation member ID: ${worker!.federationId}',
                      style: GoogleFonts.inter(
                          fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // Actions
          OutlinedButton.icon(
            onPressed: () => context.push('/onboarding'),
            icon: const Icon(Icons.person_add_alt_1_rounded,
                size: 19, color: AppColors.indigo),
            label: Text('Register another partner',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.indigo,
              side: BorderSide(color: AppColors.indigo.withValues(alpha: 0.4)),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Log out',
            isSecondary: true,
            background: AppColors.surface,
            foreground: AppColors.danger,
            icon: Icons.logout_rounded,
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Text('Log out?',
                      style: GoogleFonts.sora(fontWeight: FontWeight.w800)),
                  content: Text(
                    'You will stop receiving dispatch offers until you sign in again.',
                    style: GoogleFonts.inter(color: AppColors.inkSoft),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Log out',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger))),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  AppSnackBar.show(context, 'Logged out.', type: SnackType.info);
                  context.go('/login');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _metric({
    required IconData icon,
    required String value,
    required String label,
  }) =>
      Column(
        children: [
          Icon(icon, size: 17, color: AppColors.goldLight),
          const SizedBox(height: 5),
          Text(value,
              style: GoogleFonts.sora(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white54)),
        ],
      );
}
