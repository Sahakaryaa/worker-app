import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Metrics summary card displayed on Worker Home Dashboard.
class EarningsSummaryCard extends StatelessWidget {
  final double todayEarnings;
  final int completedJobs;
  final double ratingAvg;
  final double welfareBalance;
  final VoidCallback? onWelfareTap;

  const EarningsSummaryCard({
    super.key,
    required this.todayEarnings,
    required this.completedJobs,
    required this.ratingAvg,
    required this.welfareBalance,
    this.onWelfareTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
          // Main Earnings Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Net Take-Home",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${todayEarnings.toStringAsFixed(0)}',
                        style: GoogleFonts.sora(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+₹680 vs gig apps',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.orange,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // 3 Quick Metrics
          Row(
            children: [
              // Jobs
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.teal,
                  value: '$completedJobs',
                  label: 'Jobs Today',
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              // Rating
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.star_rounded,
                  iconColor: AppColors.gold,
                  value: ratingAvg.toStringAsFixed(1),
                  label: 'Rating (142)',
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              // Welfare Fund
              Expanded(
                child: GestureDetector(
                  onTap: onWelfareTap,
                  child: _buildMetricItem(
                    icon: Icons.shield_rounded,
                    iconColor: AppColors.teal,
                    value: '₹${welfareBalance.toStringAsFixed(0)}',
                    label: 'Welfare Fund',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    );
  }
}
