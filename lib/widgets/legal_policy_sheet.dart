import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum WorkerLegalDocType { partnerPrivacy, partnerTerms, welfareCharter }

/// Comprehensive legal & cooperative charter sheet for SahaKarya Partners.
class WorkerLegalPolicySheet extends StatelessWidget {
  final WorkerLegalDocType initialDoc;

  const WorkerLegalPolicySheet({
    super.key,
    this.initialDoc = WorkerLegalDocType.welfareCharter,
  });

  static Future<void> show(BuildContext context,
      {WorkerLegalDocType doc = WorkerLegalDocType.welfareCharter}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkerLegalPolicySheet(initialDoc: doc),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: switch (initialDoc) {
        WorkerLegalDocType.welfareCharter => 0,
        WorkerLegalDocType.partnerPrivacy => 1,
        WorkerLegalDocType.partnerTerms => 2,
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.handshake_rounded,
                        color: AppColors.goldDark, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partner Charter & Policies',
                          style: GoogleFonts.sora(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'Labour Cooperative Federation Agreement',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.inkSoft),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tab Bar
            TabBar(
              labelColor: AppColors.goldDark,
              unselectedLabelColor: AppColors.inkSoft,
              indicatorColor: AppColors.goldDark,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: '5% Welfare Fund'),
                Tab(text: 'Data Dignity'),
                Tab(text: 'Partner Terms'),
              ],
            ),
            const Divider(height: 1, color: AppColors.border),

            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  _buildWelfareCharter(),
                  _buildPartnerPrivacy(),
                  _buildPartnerTerms(),
                ],
              ),
            ),

            // Bottom action
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'I Accept the Partner Charter',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelfareCharter() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _section(
          title: '1. The 5% Non-Extractable Rule',
          content:
              'Exactly 5% of every completed booking is routed into the collective Federation Welfare Pool. This money is locked exclusively for member benefits and cannot be extracted for private platform profits.',
        ),
        _section(
          title: '2. Immediate Claims Eligibility',
          content:
              'Members with at least 5 completed jobs or 30 days active membership can submit one-tap claims for emergency medical aid, tool replacement loans (0% interest), and maternity/paternity support.',
        ),
        _section(
          title: '3. Transparent Governance Audit',
          content:
              'Every rupee in the Welfare Fund is audited monthly by the Federation General Body. Live ledger balance is accessible directly from your Welfare tab.',
        ),
      ],
    );
  }

  Widget _buildPartnerPrivacy() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _section(
          title: '1. No Algorithmic Penalties or Deactivations',
          content:
              'You control your own working hours. SahaKarya will never penalize or ban you algorithmically for declining jobs. You are an autonomous cooperative owner, not an employee.',
        ),
        _section(
          title: '2. Transparent Proximity Dispatch',
          content:
              'Job offers are broadcast to the nearest available verified tradesperson using fair distance scoring and cooldown rotation so all partners receive equal opportunity.',
        ),
        _section(
          title: '3. Location Streaming Privacy',
          content:
              'Your GPS location is only streamed when you explicitly toggle "Online". As soon as you toggle "Offline", all background telemetry stops immediately.',
        ),
      ],
    );
  }

  Widget _buildPartnerTerms() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _section(
          title: '1. Cooperative Trade Standards',
          content:
              'Partners agree to deliver high-quality craftsmanship, adhere to basic safety guidelines, and carry genuine trade tools on all accepted jobs.',
        ),
        _section(
          title: '2. Instant Direct Payouts',
          content:
              '95% of job payout is credited directly to your bank account or UPI within 2 hours of customer completion. No hidden commissions or platform withholding.',
        ),
        _section(
          title: '3. Federation Support & Protection',
          content:
              'In case of customer non-payment or unreasonable disputes, the Federation provides full wage guarantee backing.',
        ),
      ],
    );
  }

  Widget _section({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.sora(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.55,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
