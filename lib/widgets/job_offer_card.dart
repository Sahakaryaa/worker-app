import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/job.dart';
import 'primary_button.dart';

/// Job Offer Card with animated 30-second countdown indicator per 03-worker-app-flutter.md §5.
class JobOfferCard extends StatelessWidget {
  final Job job;
  final int secondsRemaining;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const JobOfferCard({
    super.key,
    required this.job,
    required this.secondsRemaining,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (secondsRemaining / 30.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: job.isEmergency ? AppColors.orange : AppColors.teal.withValues(alpha: 0.3),
          width: job.isEmergency ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Emergency tag / Service Type + 30s Countdown Clock
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: job.isEmergency
                          ? AppColors.orange.withValues(alpha: 0.15)
                          : AppColors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      job.isEmergency
                          ? Icons.flash_on_rounded
                          : Icons.handyman_rounded,
                      color: job.isEmergency ? AppColors.orange : AppColors.teal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.serviceType[0].toUpperCase() +
                            job.serviceType.substring(1),
                        style: GoogleFonts.sora(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        job.isEmergency
                            ? '⚡ EMERGENCY DISPATCH'
                            : 'Standard Service Request',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: job.isEmergency
                              ? AppColors.orange
                              : AppColors.teal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Circular Countdown Timer
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3.5,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        secondsRemaining <= 10
                            ? AppColors.error
                            : AppColors.orange,
                      ),
                    ),
                  ),
                  Text(
                    '${secondsRemaining}s',
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: secondsRemaining <= 10
                          ? AppColors.error
                          : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Price & Net Payout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Price',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    Text(
                      '₹${job.price.toStringAsFixed(0)}',
                      style: GoogleFonts.sora(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Welfare Allocation (1%)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '+₹${job.welfareContribution.toStringAsFixed(1)} to Fund',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Location details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded,
                  color: AppColors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.customerAddress,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${job.distanceFormatted} • ${job.customerName}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.inkLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Accept & Decline Action CTAs
          Row(
            children: [
              Expanded(
                flex: 1,
                child: PrimaryButton(
                  label: 'Decline',
                  isOutlined: true,
                  textColor: AppColors.error,
                  onPressed: onDecline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Accept Job (${secondsRemaining}s)',
                  icon: Icons.check_circle_rounded,
                  backgroundColor: AppColors.orange,
                  onPressed: onAccept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
