import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/job.dart';
import '../models/welfare_transaction.dart';
import '../theme/app_colors.dart';

/// Animated color-morph status pill. Status communicated by chip color +
/// label — never plain text (DESIGN_SPEC feel-checklist #5).
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  /// Booking / job statuses (contract strings).
  factory StatusChip.job(JobStatus status, {bool compact = false}) {
    final (color, label) = switch (status) {
      JobStatus.pending => (AppColors.warning, 'Pending'),
      JobStatus.accepted => (AppColors.indigo, 'Accepted'),
      JobStatus.declined => (AppColors.danger, 'Declined'),
      JobStatus.enRoute => (AppColors.info, 'En Route'),
      JobStatus.arrived => (AppColors.indigoDeep, 'Arrived'),
      JobStatus.started => (AppColors.goldDark, 'Started'),
      JobStatus.completed => (AppColors.success, 'Completed'),
      JobStatus.cancelled => (AppColors.danger, 'Cancelled'),
    };
    return StatusChip(label: label, color: color);
  }

  /// Welfare claim statuses: pending | approved | completed.
  factory StatusChip.welfare(WelfareClaimStatus status) {
    final (color, label) = switch (status) {
      WelfareClaimStatus.pending => (AppColors.warning, 'Pending'),
      WelfareClaimStatus.approved => (AppColors.info, 'Approved'),
      WelfareClaimStatus.completed => (AppColors.success, 'Completed'),
    };
    return StatusChip(label: label, color: color);
  }

  factory StatusChip.certification(String certification) {
    final (color, label) = switch (certification) {
      'verified' => (AppColors.success, 'Certification Verified'),
      'rejected' => (AppColors.danger, 'Certification Rejected'),
      _ => (AppColors.warning, 'Certification Pending'),
    };
    return StatusChip(label: label, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: _onTint(color),
            ),
          ),
        ],
      ),
    );
  }

  static Color _onTint(Color c) =>
      c == AppColors.warning ? AppColors.goldDark : c;
}
