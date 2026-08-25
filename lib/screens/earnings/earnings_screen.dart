import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/job.dart';
import '../../providers/earnings_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_box.dart';
import '../../widgets/status_chip.dart';

/// Earnings & analytics — gold identity hero, weekly chart, job ledger.
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(earningsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Earnings',
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
          // ---------------- Week hero ----------------
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppColors.nightGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This week\'s take-home',
                    style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white60)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: earnings.weekTotal),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Text(
                        '₹${v.toStringAsFixed(v % 1 == 0 ? 0 : 2)}',
                        style: GoogleFonts.sora(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Colors.white),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${earnings.completedJobsToday} today',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldLight),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(color: Colors.white.withValues(alpha: .12), height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Today: ₹${earnings.todayTotal.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.goldLight)),
                    Text('Direct bank payout • settled daily',
                        style: GoogleFonts.inter(
                            fontSize: 11.5, color: Colors.white38)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),

          const SizedBox(height: 18),

          // ---------------- Weekly chart ----------------
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withValues(alpha: .7)),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily revenue trend (Mon – Sun)',
                    style: GoogleFonts.sora(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 2800,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.night2,
                          getTooltipItem: (group, _, rod, __) {
                            final day = earnings
                                .weeklyChartData[group.x.toInt()]['day'];
                            return BarTooltipItem(
                              '$day: ₹${rod.toY.round()}',
                              GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            getTitlesWidget: (val, meta) {
                              if (val == 0) return const SizedBox.shrink();
                              return Text(
                                '${(val / 1000).toStringAsFixed(1)}k',
                                style: GoogleFonts.inter(
                                    fontSize: 10, color: AppColors.inkFaint),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final i = val.toInt();
                              if (i >= 0 && i < earnings.weeklyChartData.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    earnings.weeklyChartData[i]['day'],
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.inkSoft),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 800,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: AppColors.surfaceAlt, strokeWidth: 1.4),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: earnings.weeklyChartData.asMap().entries.map((e) {
                        final amount = (e.value['amount'] as num?)?.toDouble() ?? 0;
                        final isMax = amount >= 2400;
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: amount,
                              gradient: isMax ? AppColors.goldGradient : null,
                              color:
                                  isMax ? null : AppColors.gold.withValues(alpha: 0.45),
                              width: 18,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ).animate(delay: 60.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.only(left: 4, top: 16, bottom: 10),
            child: Text('Completed job ledger',
                style: GoogleFonts.sora(fontSize: 15.5, fontWeight: FontWeight.w800)),
          ),

          if (earnings.isLoading && earnings.jobHistory.isEmpty)
            ...const [
              SkeletonCard(height: 84),
              SkeletonCard(height: 84),
              SkeletonCard(height: 84),
            ]
          else if (earnings.jobHistory.isEmpty)
            EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No completed jobs yet',
              subtitle: 'Finish jobs from the Active Job tab to build your ledger.',
            )
          else
            ...earnings.jobHistory.asMap().entries.map((entry) {
              final i = entry.key;
              return _LedgerTile(job: entry.value)
                  .animate(delay: (45 * i).clamp(0, 400).ms)
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.08, end: 0);
            }),
        ],
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  final Job job;
  const _LedgerTile({required this.job});

  @override
  Widget build(BuildContext context) {
    final takeHome = job.price - job.welfareContribution;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: .7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded,
                size: 19, color: AppColors.goldDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.customerName.isEmpty ? 'Service booking' : job.customerName,
                    style: GoogleFonts.sora(
                        fontSize: 13.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${job.serviceType.isEmpty ? "service" : job.serviceType} • ${job.createdAt.day}/${job.createdAt.month}',
                  style: GoogleFonts.inter(
                      fontSize: 11.5, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+₹${takeHome.toStringAsFixed(0)}',
                  style: GoogleFonts.sora(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.success)),
              const SizedBox(height: 4),
              StatusChip.job(job.status),
            ],
          ),
        ],
      ),
    );
  }
}
