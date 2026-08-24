import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/cooperative_badge.dart';

/// Worker Profile, Certifications, and Customer Reviews Screen per 03-worker-app-flutter.md §5.
class WorkerProfileScreen extends ConsumerWidget {
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final worker = authState.profile;

    final demoReviews = [
      {
        'customer': 'Ananya Sharma',
        'rating': 5.0,
        'date': 'Yesterday',
        'comment':
            'Ramesh was punctual and solved the short circuit issue in 20 minutes! Very respectful.',
      },
      {
        'customer': 'Vikram Mehta',
        'rating': 5.0,
        'date': '3 days ago',
        'comment':
            'Excellent wiring repair. Highly recommend federation verified workers.',
      },
      {
        'customer': 'Pooja Iyer',
        'rating': 4.5,
        'date': 'Last week',
        'comment':
            'Fair pricing and transparent breakdown. Glad to support cooperative workers.',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Partner Profile & Reviews',
          style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.orange,
                        child: Text(
                          worker?.name
                                  .split(' ')
                                  .map((e) => e[0])
                                  .take(2)
                                  .join() ??
                              'RK',
                          style: GoogleFonts.sora(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  worker?.name ?? 'Ramesh Kumar',
                                  style: GoogleFonts.sora(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const CooperativeBadge(isCompact: true),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              worker?.phone ?? '+91 98111 00001',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.inkLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              worker?.federationName ??
                                  'Delhi Central Labour Cooperative Federation',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.teal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // 3 Rating & Credential Metrics
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppColors.gold, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  (worker?.ratingAvg ?? 4.85).toStringAsFixed(2),
                                  style: GoogleFonts.sora(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            Text('142 Reviews',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: AppColors.inkMuted)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: AppColors.border),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '8 Years',
                              style: GoogleFonts.sora(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.teal,
                              ),
                            ),
                            Text('Experience',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: AppColors.inkMuted)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: AppColors.border),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '840+',
                              style: GoogleFonts.sora(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.orange,
                              ),
                            ),
                            Text('Completed',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: AppColors.inkMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Certified Skills & Credentials
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Certified Trade Skills',
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (worker?.skills ?? ['electrician', 'plumber'])
                        .map(
                          (skill) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.orange.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded,
                                    size: 14, color: AppColors.orange),
                                const SizedBox(width: 6),
                                Text(
                                  skill[0].toUpperCase() + skill.substring(1),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.orangeDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.card_membership_rounded,
                          color: AppColors.teal, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'NCCT Labour Cooperative Membership ID: #DEL-8821',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Customer Reviews List
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Customer Reviews',
                        style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '100% Verified',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...demoReviews.map(
                    (rev) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                rev['customer'] as String,
                                style: GoogleFonts.sora(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 14, color: AppColors.gold),
                                  Text(
                                    (rev['rating'] as double).toStringAsFixed(1),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rev['comment'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.inkLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Logout & Register Other Member
            OutlinedButton.icon(
              onPressed: () {
                context.push('/onboarding');
              },
              icon: const Icon(Icons.person_add_rounded, color: AppColors.teal),
              label: const Text('Register New Partner / Switch Account'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                side: const BorderSide(color: AppColors.teal),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
