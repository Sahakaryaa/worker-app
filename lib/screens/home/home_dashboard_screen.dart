import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/job.dart';
import '../../providers/active_job_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/earnings_provider.dart';
import '../../providers/incoming_job_provider.dart';
import '../../providers/welfare_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_badge.dart';
import '../../widgets/availability_toggle.dart';
import '../../widgets/cooperative_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_box.dart';
import '../../widgets/status_chip.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final earnings = ref.watch(earningsProvider);
    final welfare = ref.watch(welfareProvider);
    final activeJobState = ref.watch(activeJobProvider);
    final worker = auth.profile;
    final activeJob = activeJobState.job;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.goldDark,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.read(earningsProvider.notifier).loadEarnings();
          ref.read(welfareProvider.notifier).loadWelfare();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ---------------- Dark hero header ----------------
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.nightGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AvatarBadge(name: worker?.name ?? '', online: true, radius: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Namaste, ${_firstName(worker?.name)}',
                                    style: GoogleFonts.sora(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _skillsLine(worker?.skills),
                                    style: GoogleFonts.inter(
                                        fontSize: 12, color: Colors.white60),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const CooperativeBadge(isCompact: true),
                          ],
                        ),
                        const SizedBox(height: 18),
                        AvailabilityToggle(dark: true),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.04, end: 0),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (activeJob != null)
                      _ActiveJobBanner(job: activeJob)
                          .animate()
                          .fadeIn(duration: 350.ms)
                          .slideY(begin: 0.08, end: 0),

                    // ---------------- EARNINGS HERO CARD ----------------
                    EarningsHeroCard(
                      todayTotal: earnings.todayTotal,
                      weekTotal: earnings.weekTotal,
                      sparklineData: earnings.weeklyChartData,
                      isLoading: earnings.isLoading && earnings.todayTotal == 0,
                    ).animate(delay: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),

                    const SizedBox(height: 14),

                    // ---------------- Stats row ----------------
                    if (earnings.isLoading && earnings.jobHistory.isEmpty)
                      const SkeletonCard(height: 84)
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.check_circle_rounded,
                              value: '${earnings.completedJobsToday}',
                              label: 'Jobs today',
                              color: AppColors.success,
                              onTap: () => context.go('/earnings'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.star_rounded,
                              value:
                                  (worker == null || worker.rating <= 0) ? '—' : worker.rating.toStringAsFixed(1),
                              label: 'Rating',
                              color: AppColors.goldDark,
                              onTap: () => context.go('/profile'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.volunteer_activism_rounded,
                              value: welfare.currentBalance >= 1000
                                  ? '₹${(welfare.currentBalance / 1000).toStringAsFixed(1)}k'
                                  : '₹${welfare.currentBalance.toStringAsFixed(0)}',
                              label: 'Welfare fund',
                              color: AppColors.indigo,
                              onTap: () => context.go('/welfare'),
                            ),
                          ),
                        ],
                      ).animate(delay: 140.ms).fadeIn(duration: 400.ms),

                    // Demo triggers (presentation aid, subtle)
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(incomingJobProvider.notifier)
                                  .triggerDemoOffer(isEmergency: false);
                            },
                            icon: const Icon(Icons.notifications_active_rounded, size: 17),
                            label: const Text('Simulate offer'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.indigo,
                              side: BorderSide(
                                  color: AppColors.indigo.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              textStyle: GoogleFonts.inter(
                                  fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(incomingJobProvider.notifier)
                                  .triggerDemoOffer(isEmergency: true);
                            },
                            icon: const Icon(Icons.flash_on_rounded, size: 17),
                            label: const Text('Emergency offer'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.goldDark,
                              side: BorderSide(
                                  color: AppColors.gold.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              textStyle: GoogleFonts.inter(
                                  fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            SliverToBoxAdapter(
              child: Text(
                '  Recent jobs',
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 2.4,
                ),
              ),
            ),

            // Recent jobs list / skeleton / empty
            if (earnings.isLoading && earnings.jobHistory.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: const [
                      SkeletonCard(height: 76),
                      SkeletonCard(height: 76),
                      SkeletonCard(height: 76),
                    ],
                  ),
                ),
              )
            else if (earnings.jobHistory.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.work_outline_rounded,
                  title: 'No jobs yet',
                  subtitle:
                      'Go online from the switch above — nearby dispatches will appear here instantly.',
                  ctaLabel: 'Open Active Job',
                  onCta: () => context.go('/active-job'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                sliver: SliverList.separated(
                  itemCount: earnings.jobHistory.length.clamp(0, 5),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final job = earnings.jobHistory[index];
                    return _RecentJobTile(job: job)
                        .animate(delay: (60 * index).ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.1, end: 0);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _firstName(String? name) {
    final n = name?.trim() ?? '';
    if (n.isEmpty) return 'Partner';
    return n.split(' ').first;
  }

  static String _skillsLine(List<String>? skills) {
    if (skills == null || skills.isEmpty) return 'Cooperative partner';
    return skills.take(2).join(' • ');
  }
}

// ---------------------------------------------------------------- widgets

class _ActiveJobBanner extends StatelessWidget {
  final Job job;
  const _ActiveJobBanner({required this.job});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () => context.go('/active-job'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.glow(AppColors.gold),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.navigation_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Job in progress',
                        style: GoogleFonts.sora(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(
                      '${job.status.label} — tap to continue',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white.withValues(alpha: .9)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class EarningsHeroCard extends StatelessWidget {
  final double todayTotal;
  final double weekTotal;
  final List<Map<String, dynamic>> sparklineData;
  final bool isLoading;

  const EarningsHeroCard({
    super.key,
    required this.todayTotal,
    required this.weekTotal,
    required this.sparklineData,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.nightGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's take-home",
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white60)),
                  const SizedBox(height: 6),
                  if (isLoading)
                    const SizedBox(
                      width: 170,
                      child: LinearProgressIndicator(minHeight: 4),
                    )
                  else
                    _GoldCountUp(value: todayTotal, fontSize: 32),
                ],
              ),
              SizedBox(
                width: 110,
                height: 44,
                child: sparklineData.isEmpty
                    ? const SizedBox.shrink()
                    : LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: 6,
                          minY: 0,
                          maxY: 2600,
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineTouchData:
                              const LineTouchData(enabled: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: sparklineData.asMap().entries.map((e) {
                                final amount =
                                    (e.value['amount'] as num?)?.toDouble() ?? 0;
                                return FlSpot(e.key.toDouble(), amount);
                              }).toList(),
                              isCurved: true,
                              barWidth: 3,
                              color: AppColors.goldLight,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.gold.withValues(alpha: 0.35),
                                    AppColors.gold.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  text: 'This week  ',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: _GoldCountUp(value: weekTotal, fontSize: 15),
                    ),
                  ],
                ),
              ),
              Text('After 5% welfare contribution',
                  style: GoogleFonts.inter(
                      fontSize: 10.5, color: Colors.white38)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoldCountUp extends StatelessWidget {
  final double value;
  final double fontSize;
  const _GoldCountUp({required this.value, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '₹${v.toStringAsFixed(v % 1 == 0 ? 0 : 2)}',
        style: GoogleFonts.sora(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: AppColors.goldLight,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(height: 5),
              Text(value,
                  style: GoogleFonts.sora(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 10.5, color: AppColors.inkSoft)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentJobTile extends StatelessWidget {
  final Job job;
  const _RecentJobTile({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.handyman_rounded,
                color: AppColors.goldDark, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.customerName.isEmpty ? 'Service booking' : job.customerName,
                  style: GoogleFonts.sora(
                      fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${job.serviceType.isEmpty ? 'Service' : job.serviceType} • ${job.createdAt.day}/${job.createdAt.month}',
                  style: GoogleFonts.inter(
                      fontSize: 11.5, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${job.price.toStringAsFixed(0)}',
                  style: GoogleFonts.sora(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3)),
              const SizedBox(height: 4),
              StatusChip.job(job.status),
            ],
          ),
        ],
      ),
    );
  }
}
