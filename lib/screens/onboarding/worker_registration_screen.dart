import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatting.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/cooperative_badge.dart';
import '../../widgets/legal_policy_sheet.dart';

/// Validated multi-step registration — POST /auth/register {name,phone,password}.
/// No pre-filled identity; hint text only; Next disabled until step valid.
class WorkerRegistrationScreen extends ConsumerStatefulWidget {
  const WorkerRegistrationScreen({super.key});

  @override
  ConsumerState<WorkerRegistrationScreen> createState() =>
      _WorkerRegistrationScreenState();
}

class _WorkerRegistrationScreenState
    extends ConsumerState<WorkerRegistrationScreen> {
  int _step = 0;

  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _experience = TextEditingController();
  final _federationCode = TextEditingController();

  bool _obscure = true;
  bool _agreeToCharter = true;
  String? _phoneError;

  static const List<String> _availableSkills = [
    'electrician',
    'plumber',
    'carpenter',
    'painter',
    'cleaner',
    'caregiver',
    'driver',
    'gardener',
  ];
  final Set<String> _selectedSkills = {};

  @override
  void dispose() {
    for (final c in [_phone, _password, _name, _experience, _federationCode]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _phoneValid => isValidPhone(_phone.text);

  bool get _stepValid {
    switch (_step) {
      case 0:
        return _phoneValid && _password.text.length >= 4;
      case 1:
        return _name.text.trim().length >= 2;
      case 2:
        return _selectedSkills.isNotEmpty;
      case 3:
        return _agreeToCharter;
      default:
        return true;
    }
  }

  String? get _stepHint {
    switch (_step) {
      case 0:
        if (_phone.text.isEmpty) return null;
        if (!_phoneValid) return 'Mobile number must be exactly 10 digits';
        if (_password.text.length < 4) return 'Password needs at least 4 characters';
        return null;
      default:
        return null;
    }
  }

  Future<void> _next() async {
    if (!_stepValid) return;

    if (_step == 3) {
      final ok = await ref.read(authProvider.notifier).registerWorker(
            name: _name.text.trim(),
            phoneDigits: normalizePhone(_phone.text)!,
            password: _password.text,
            skills: _selectedSkills.toList(),
          );
      if (!mounted) return;
      if (ok) {
        context.go('/home');
      } else {
        AppSnackBar.show(
          context,
          ref.read(authProvider).error ?? 'Registration failed.',
          type: SnackType.error,
        );
      }
      return;
    }
    setState(() => _step += 1);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Gradient header
          Container(
            decoration: const BoxDecoration(gradient: AppColors.goldGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_step > 0) {
                          setState(() => _step -= 1);
                        } else {
                          context.pop();
                        }
                      },
                      icon:
                          const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Join the Cooperative',
                        style: GoogleFonts.sora(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const CooperativeBadge(isCompact: true),
                  ],
                ),
              ),
            ),
          ),

          // Stepper progress
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Row(
              children: List.generate(4, (i) {
                final active = i <= _step;
                return Expanded(
                  child: Container(
                    height: 5,
                    margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.gold
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                key: ValueKey(_step), // re-run stagger animations per step
                children: [
                  if (_step == 0) _buildPhoneStep(),
                  if (_step == 1) _buildNameStep(),
                  if (_step == 2) _buildSkillStep(),
                  if (_step == 3) _buildFederationStep(),
                ],
              ),
            ),
          ),

          // Bottom CTA
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.7))),
            ),
            child: SafeArea(
              top: false,
              child: AppButton(
                label: _step == 3 ? 'Complete Registration' : 'Continue',
                icon: _step == 3 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                isLoading: auth.isLoading,
                onPressed: _stepValid ? _next : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.sora(
                  fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: GoogleFonts.inter(fontSize: 13.5, height: 1.5, color: AppColors.inkSoft)),
          const SizedBox(height: 24),
        ],
      );

  InputDecoration _deco({
    required String hint,
    required IconData icon,
    String? errorText,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.goldDark),
        suffixIcon: suffix,
        errorText: errorText,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.6),
        ),
      );

  Widget _buildPhoneStep() {
    final hint = _stepHint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Create your account', 'Use your mobile number and set a password to join the federation network.'),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          maxLength: 13,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'\d'))],
          decoration: _deco(
            hint: 'e.g. 98765 43210',
            icon: Icons.phone_rounded,
            errorText: _phoneError ?? ((hint != null && hint.contains('digits')) ? hint : null),
          ),
        ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.12, end: 0),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: _obscure,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          decoration: _deco(
            hint: 'Create a password (min 4 chars)',
            icon: Icons.lock_outline_rounded,
            suffix: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 20, color: AppColors.inkFaint),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ).animate(delay: 60.ms).fadeIn(duration: 350.ms).slideY(begin: 0.12, end: 0),
        if (hint != null && !hint.contains('digits')) ...[
          const SizedBox(height: 10),
          Text(hint, style: GoogleFonts.inter(fontSize: 12, color: AppColors.warning)),
        ],
        const SizedBox(height: 16),
        Row(children: [
          const Icon(Icons.shield_moon_rounded, size: 15, color: AppColors.indigo),
          const SizedBox(width: 6),
          Expanded(
            child: Text('Your number is verified by OTP at first dispatch.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft)),
          ),
        ]),
      ],
    );
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Your details', 'This appears on your verified partner badge shown to customers.'),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          decoration: _deco(hint: 'Full name', icon: Icons.person_rounded),
        ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.12, end: 0),
        const SizedBox(height: 16),
        TextField(
          controller: _experience,
          keyboardType: TextInputType.number,
          maxLength: 2,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          decoration: const InputDecoration(counterText: '').copyWith(
            hintText: 'Years of experience (optional)',
            prefixIcon: const Icon(Icons.work_history_rounded,
                size: 20, color: AppColors.goldDark),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.gold, width: 1.6),
            ),
          ),
        ).animate(delay: 60.ms).fadeIn(duration: 350.ms).slideY(begin: 0.12, end: 0),
      ],
    );
  }

  Widget _buildSkillStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Trade skills', 'Pick every service you are certified to provide through the federation.'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _availableSkills.map((skill) {
            final selected = _selectedSkills.contains(skill);
            return FilterChip(
              label: Text(titleCase(skill)),
              selected: selected,
              onSelected: (_) => setState(() {
                if (selected) {
                  _selectedSkills.remove(skill);
                } else {
                  _selectedSkills.add(skill);
                }
              }),
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.ink,
              ),
              checkmarkColor: Colors.white,
              selectedColor: AppColors.gold,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                  color: selected ? AppColors.gold : AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            );
          }).toList(),
        )
            .animate()
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.12, end: 0),
      ],
    );
  }

  Widget _buildFederationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Federation code', 'Enter your cooperative member code if you have one. You can also add this later.'),
        TextField(
          controller: _federationCode,
          textCapitalization: TextCapitalization.characters,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          decoration:
              _deco(hint: 'e.g. DEL-NCCT-2024', icon: Icons.badge_rounded),
        ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.12, end: 0),
        const SizedBox(height: 16),
        // Partner Charter & Policy Agreement
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _agreeToCharter,
                activeColor: AppColors.goldDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                onChanged: (val) =>
                    setState(() => _agreeToCharter = val ?? false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Wrap(
                children: [
                  Text(
                    'I agree to the ',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => WorkerLegalPolicySheet.show(context,
                        doc: WorkerLegalDocType.welfareCharter),
                    child: Text(
                      '5% Welfare Fund Charter',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldDark,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(
                    ', ',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => WorkerLegalPolicySheet.show(context,
                        doc: WorkerLegalDocType.partnerPrivacy),
                    child: Text(
                      'Data Dignity Policy',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldDark,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(
                    ' & ',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => WorkerLegalPolicySheet.show(context,
                        doc: WorkerLegalDocType.partnerTerms),
                    child: Text(
                      'Partner Terms',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldDark,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ).animate(delay: 120.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }
}

class SoftInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const SoftInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.indigo.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.indigo.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.indigo.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.indigo, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body,
                    style: GoogleFonts.inter(
                        fontSize: 12, height: 1.45, color: AppColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
