import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/welfare_provider.dart';
import '../../models/welfare_transaction.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/cooperative_badge.dart';

/// Federation Welfare Fund Screen per 03-worker-app-flutter.md §5 & §8.
/// Prominently showcases worker social security, healthcare, and tool grant claims.
class WelfareFundScreen extends ConsumerWidget {
  const WelfareFundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final welfareState = ref.watch(welfareProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Federation Welfare Fund',
          style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Welfare Passbook Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppColors.darkCardGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_rounded, color: AppColors.gold, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'SahaKarya Social Security',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const CooperativeBadge(isCompact: true),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Available Welfare Balance',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${welfareState.currentBalance.toStringAsFixed(2)}',
                    style: GoogleFonts.sora(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),

                  // Quick Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Accrued',
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
                            ),
                            Text(
                              '₹${welfareState.totalContributed.toStringAsFixed(0)}',
                              style: GoogleFonts.sora(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 28, color: Colors.white24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Claims Disbursed',
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
                            ),
                            Text(
                              '₹${welfareState.totalClaimed.toStringAsFixed(0)}',
                              style: GoogleFonts.sora(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Cooperative Trust Policy Explanation Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '100% Ring-Fenced Member Fund',
                          style: GoogleFonts.sora(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '1% of every completed job is directly routed into your federation welfare ledger. Never utilized as platform revenue.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Submit Claim CTA Button
            PrimaryButton(
              label: 'Request Welfare Claim / Tool Grant',
              icon: Icons.add_circle_outline_rounded,
              backgroundColor: AppColors.orange,
              onPressed: () => _showClaimDialog(context, ref),
            ),
            const SizedBox(height: 24),

            // Transaction History Title
            Text(
              'Welfare Passbook & Claims Ledger',
              style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 12),

            // Transactions list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: welfareState.transactions.length,
              itemBuilder: (context, index) {
                final tx = welfareState.transactions[index];
                final isClaim = tx.type == WelfareTransactionType.claim;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isClaim
                              ? AppColors.gold.withValues(alpha: 0.15)
                              : AppColors.teal.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isClaim ? Icons.medical_services_rounded : Icons.savings_rounded,
                          color: isClaim ? AppColors.goldDark : AppColors.teal,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isClaim
                                  ? 'Claim: ${tx.claimCategory ?? "Medical / Tool"}'
                                  : '1% Job Allocation',
                              style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              tx.description,
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkLight),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('dd MMM yyyy, hh:mm a').format(tx.createdAt),
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isClaim
                                ? '₹${tx.amount.toStringAsFixed(0)}'
                                : '+₹${tx.amount.toStringAsFixed(1)}',
                            style: GoogleFonts.sora(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isClaim ? AppColors.orange : AppColors.teal,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isClaim
                                  ? (tx.status == WelfareClaimStatus.disbursed
                                      ? AppColors.success.withValues(alpha: 0.1)
                                      : AppColors.warning.withValues(alpha: 0.1))
                                  : AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tx.status.name.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isClaim
                                    ? (tx.status == WelfareClaimStatus.disbursed
                                        ? AppColors.success
                                        : AppColors.warning)
                                    : AppColors.success,
                              ),
                            ),
                          ),
                        ],
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

  void _showClaimDialog(BuildContext context, WidgetRef ref) {
    String category = 'Medical';
    final amountController = TextEditingController(text: '1500');
    final descController = TextEditingController(text: 'Protective safety gear & goggles reimbursement');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Request Welfare Claim',
                        style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Claim Category',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Medical', 'Tool Grant', 'Emergency Relief', 'Pension']
                        .map((cat) => ChoiceChip(
                              label: Text(cat),
                              selected: category == cat,
                              selectedColor: AppColors.orange,
                              labelStyle: GoogleFonts.inter(
                                color: category == cat ? Colors.white : AppColors.ink,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (_) => setState(() => category = cat),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Claim Amount (₹)',
                      filled: true,
                      fillColor: AppColors.bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Reason / Item Details',
                      filled: true,
                      fillColor: AppColors.bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Submit Claim to Federation Board',
                    icon: Icons.send_rounded,
                    backgroundColor: AppColors.teal,
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text) ?? 1500.0;
                      await ref.read(welfareProvider.notifier).submitClaim(
                            category: category,
                            amount: amount,
                            description: descController.text,
                          );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Welfare claim submitted! Federation officials notified.'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
