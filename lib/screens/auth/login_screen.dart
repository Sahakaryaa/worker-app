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
import '../../widgets/glass_card.dart';
import '../../widgets/app_logo.dart';

/// Login — gold gradient header + frosted glass form card with staggered
/// fields. POST /auth/login {phone, password} -> TokenResponse.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _phoneError;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _phoneValid => isValidPhone(_phone.text);
  bool get _canSubmit =>
      _phoneValid && _password.text.length >= 4;

  Future<void> _submit() async {
    setState(() {
      _phoneError =
          _phoneValid ? null : 'Enter a valid 10-digit mobile number';
    });
    if (!_canSubmit) return;

    final ok = await ref.read(authProvider.notifier).login(
          normalizePhone(_phone.text)!,
          _password.text,
        );
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      AppSnackBar.show(context,
          ref.read(authProvider).error ?? 'Login failed.',
          type: SnackType.error);
    }
  }

  void _demoMode() {
    ref.read(authProvider.notifier).enterDemoMode();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gold gradient header
            Container(
              decoration: const BoxDecoration(gradient: AppColors.goldGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 64),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppLogo(size: 46),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sahakarya',
                                style: GoogleFonts.sora(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'SARATHI WORKER',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  letterSpacing: 1.8,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: auth.isLoading ? null : _demoMode,
                            child: Text(
                              'Explore demo',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'Welcome back,\nPartner.',
                        style: GoogleFonts.sora(
                          fontSize: 28,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to receive dispatches and track earnings.',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Glass form card overlapping the header
            Transform.translate(
              offset: const Offset(0, -36),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Mobile Number'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        maxLength: 13,
                        enabled: !auth.isLoading,
                        onChanged: (_) => setState(() {}),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                        ],
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        decoration: _inputDecoration(
                          hint: '10-digit mobile number',
                          icon: Icons.phone_rounded,
                          errorText: _phoneError,
                        ),
                        autofillHints: const [AutofillHints.telephoneNumber],
                      ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.12, end: 0),
                      const SizedBox(height: 16),
                      _label('Password'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _password,
                        obscureText: _obscure,
                        enabled: !auth.isLoading,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _submit(),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        decoration: _inputDecoration(
                          hint: 'Your password',
                          icon: Icons.lock_rounded,
                          suffix: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 20,
                              color: AppColors.inkFaint,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ).animate(delay: 60.ms).fadeIn(duration: 350.ms).slideY(begin: 0.12, end: 0),
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Sign In',
                        icon: Icons.arrow_forward_rounded,
                        isLoading: auth.isLoading,
                        onPressed: _canSubmit ? _submit : null,
                      ).animate(delay: 120.ms).fadeIn(duration: 350.ms),
                      const SizedBox(height: 14),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('New to the cooperative?',
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: AppColors.inkSoft)),
                            TextButton(
                              onPressed: () => context.push('/onboarding'),
                              style: TextButton.styleFrom(
                                  foregroundColor: AppColors.goldDark,
                                  visualDensity: VisualDensity.compact),
                              child: Text(
                                'Register as Partner',
                                style: GoogleFonts.inter(
                                    fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.inkSoft,
        ),
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? errorText,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      counterText: '',
      errorText: errorText,
      prefixIcon: Icon(icon, size: 20, color: AppColors.goldDark),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.6),
      ),
    );
  }
}
