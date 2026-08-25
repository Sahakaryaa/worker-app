import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/welfare_transaction.dart';
import '../../providers/welfare_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_box.dart';
import '../../widgets/status_chip.dart';

/// Welfare ledger — dark balance hero with CountUpText, typed transactions
/// (contribution ↓ green / claim ↑ amber), StatusChips and a validated
/// claim submission sheet.
class WelfareFundScreen extends ConsumerWidget {
  const WelfareFundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final welfare = ref.watch(welfareProvider);

    // Surface load errors once per stamp.
    ref.listen(welfareProvider, (prev, next) {
      if (prev?.error != next.error && next.error != null && context.mounted) {
        AppSnackBar.show(context, next.error!, type: SnackType.error);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Welfare Fund',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.goldDark,
        onRefresh: () => ref.read(welfareProvider.notifier).loadWelfare(),
        child: ListView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
          children: [
            // ---------------- Balance hero ----------------
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
                  Row(
                    children: [
                      const Icon(Icons.volunteer_activism_rounded,
                          color: AppColors.goldLight, size: 20),
                      const SizedBox(width: 8),
                      Text('SahaKarya Social Security',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Available balance',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white60)),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: welfare.currentBalance),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Text(
                      '₹${v.toStringAsFixed(v % 1 == 0 ? 0 : 2)}',
                      style: GoogleFonts.sora(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.goldLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Divider(color: Colors.white.withValues(alpha: .12), height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _heroStat(
                          'Total contributed',
                          '₹${welfare.totalContributed.toStringAsFixed(0)}',
                        ),
                      ),
                      Container(width: 1, height: 30, color: Colors.white24),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _heroStat(
                            'Claims paid out',
                            '₹${welfare.totalClaimedApproved.toStringAsFixed(0)}',
                            alignRight: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),

            const SizedBox(height: 14),

            // Policy note
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
                  const Icon(Icons.info_outline_rounded,
                      size: 19, color: AppColors.indigo),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Exactly 5% of every completed job is ring-fenced into your cooperative fund — never platform revenue.',
                      style: GoogleFonts.inter(
                          fontSize: 12, height: 1.5, color: AppColors.inkSoft),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 80.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: 18),

            AppButton(
              label: 'Request a Claim',
              icon: Icons.add_circle_outline_rounded,
              isLoading: welfare.submittingClaim,
              onPressed: () => _showClaimSheet(context, ref),
            ),

            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text('Passbook & claims ledger',
                  style: GoogleFonts.sora(
                      fontSize: 15.5, fontWeight: FontWeight.w800)),
            ),

            if (welfare.isLoading)
              ...const [
                SkeletonCard(height: 84),
                SkeletonCard(height: 84),
                SkeletonCard(height: 84),
              ]
            else if (welfare.transactions.isEmpty)
              EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No transactions yet',
                subtitle:
                    'Your 5% contributions from completed jobs will appear here.',
              )
            else
              ...welfare.transactions.asMap().entries.map((entry) {
                final i = entry.key;
                return _TransactionTile(tx: entry.value)
                    .animate(delay: (50 * i).clamp(0, 400).ms)
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: 0.08, end: 0);
              }),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String label, String value, {bool alignRight = false}) =>
      Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white54)),
          const SizedBox(height: 3),
          Text(value,
              style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: Colors.white)),
        ],
      );

  // ------------------------------------------------------------ claim modal

  void _showClaimSheet(BuildContext context, WidgetRef ref) {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final balance = ref.read(welfareProvider).currentBalance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Consumer(builder: (context, sheetRef, _) {
        final submitting = sheetRef.watch(welfareProvider).submittingClaim;
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                final validAmount = amount > 0 && amount <= balance;
                final validReason = reasonCtrl.text.trim().length >= 3;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Request Welfare Claim',
                            style: GoogleFonts.sora(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Amount display — keypad-styled
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: amount > balance
                              ? AppColors.danger.withValues(alpha: 0.6)
                              : validAmount
                                  ? AppColors.success.withValues(alpha: 0.45)
                                  : Colors.transparent,
                          width: 1.6,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text('CLAIM AMOUNT',
                              style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: AppColors.inkFaint)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('₹',
                                  style: GoogleFonts.sora(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.goldDark)),
                              Text(
                                amountCtrl.text.isEmpty ? '0' : amountCtrl.text,
                                style: GoogleFonts.sora(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            amount > balance
                                ? 'Exceeds your ₹${balance.toStringAsFixed(0)} balance'
                                : 'Available: ₹${balance.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: amount > balance
                                    ? AppColors.danger
                                    : AppColors.inkSoft),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: ['500', '1000', '2500', '5000'].map((v) {
                        final over =
                            (double.tryParse(v) ?? 0) > balance;
                        return ActionChip(
                          label: Text('₹$v',
                              style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: over
                                      ? AppColors.inkFaint
                                      : AppColors.goldDark)),
                          backgroundColor: over
                              ? AppColors.surfaceAlt.withValues(alpha: 0.5)
                              : AppColors.gold.withValues(alpha: 0.1),
                          side: BorderSide(
                              color: over
                                  ? AppColors.border
                                  : AppColors.gold.withValues(alpha: 0.35)),
                          onPressed: over
                              ? null
                              : () => setSheetState(() => amountCtrl.text = v),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: reasonCtrl,
                      maxLines: 2,
                      maxLength: 160,
                      onChanged: (_) => setSheetState(() {}),
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Reason — min 3 characters',
                        counterText: '',
                        prefixIcon: const Icon(Icons.edit_note_rounded,
                            size: 21, color: AppColors.indigo),
                        filled: true,
                        fillColor: AppColors.surfaceAlt,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Colors.transparent)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.gold)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    AppButton(
                      label: validReason && validAmount
                          ? 'Submit Claim'
                          : 'Enter amount & reason to submit',
                      icon: Icons.send_rounded,
                      isLoading: submitting,
                      onPressed: (!validAmount || !validReason || submitting)
                          ? null
                          : () async {
                              FocusScope.of(sheetContext).unfocus();
                              HapticFeedback.mediumImpact();
                              final ok = await sheetRef
                                  .read(welfareProvider.notifier)
                                  .submitClaim(
                                    amount: amount,
                                    reason: reasonCtrl.text,
                                  );
                              if (!sheetContext.mounted) return;
                              if (ok) {
                                Navigator.pop(sheetContext);
                                AppSnackBar.show(context,
                                    'Claim submitted for federation review.',
                                    type: SnackType.success);
                              } else {
                                AppSnackBar.show(
                                    context,
                                    sheetRef.read(welfareProvider).error ??
                                        'Claim failed.',
                                    type: SnackType.error);
                              }
                            },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------- tiles

class _TransactionTile extends StatelessWidget {
  final WelfareTransaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isClaim = tx.type == WelfareTransactionType.claim;
    final accent = isClaim ? AppColors.warning : AppColors.success;
    final dateLabel =
        '${tx.createdAt.day}/${tx.createdAt.month} • ${tx.createdAt.hour}:${tx.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
              color: accent.withValues(alpha: 0.11),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isClaim
                  ? Icons.north_east_rounded // claim ↑ amber
                  : Icons.south_west_rounded, // contribution ↓ green
              size: 18,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isClaim ? 'Claim' : 'Contribution',
                  style: GoogleFonts.sora(
                      fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  tx.reason.isEmpty ? '—' : tx.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      fontSize: 11.5, height: 1.4, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 3),
                Text(dateLabel,
                    style: GoogleFonts.inter(
                        fontSize: 10.5, color: AppColors.inkFaint)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isClaim ? "−" : "+"}₹${tx.amount.toStringAsFixed(tx.amount % 1 == 0 ? 0 : 1)}',
                style: GoogleFonts.sora(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isClaim ? AppColors.goldDark : AppColors.success),
              ),
              const SizedBox(height: 4),
              StatusChip.welfare(tx.status),
            ],
          ),
        ],
      ),
    );
  }
}
