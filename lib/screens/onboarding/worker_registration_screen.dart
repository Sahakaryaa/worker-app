import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/cooperative_badge.dart';

/// Multi-step Worker Onboarding & Federation Registration per 03-worker-app-flutter.md §5.
class WorkerRegistrationScreen extends ConsumerStatefulWidget {
  const WorkerRegistrationScreen({super.key});

  @override
  ConsumerState<WorkerRegistrationScreen> createState() =>
      _WorkerRegistrationScreenState();
}

class _WorkerRegistrationScreenState
    extends ConsumerState<WorkerRegistrationScreen> {
  int _currentStep = 0;

  // Form controllers
  final _phoneController = TextEditingController(text: '+91 98111 00001');
  final _otpController = TextEditingController(text: '1234');
  final _nameController = TextEditingController(text: 'Ramesh Kumar');
  final _experienceController = TextEditingController(text: '8');
  final _federationCodeController = TextEditingController(text: 'DEL-NCCT-2024');

  final List<String> _availableSkills = [
    'electrician',
    'plumber',
    'carpenter',
    'painter',
    'cleaner',
    'caregiver',
    'driver',
    'gardener',
  ];
  final Set<String> _selectedSkills = {'electrician', 'plumber'};

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _experienceController.dispose();
    _federationCodeController.dispose();
    super.dispose();
  }

  void _nextStep() async {
    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_nameController.text.isEmpty) return;
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_selectedSkills.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one trade skill')),
        );
        return;
      }
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      await ref.read(authProvider.notifier).registerWorker(
            name: _nameController.text,
            phone: _phoneController.text,
            skills: _selectedSkills.toList(),
            federationCode: _federationCodeController.text,
          );
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'SahaKarya Partner Onboarding',
          style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Stepper
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: AppColors.surface,
              child: Row(
                children: List.generate(4, (index) {
                  final isActive = index <= _currentStep;
                  return Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? AppColors.orange : Colors.grey.shade300,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        if (index < 3)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: index < _currentStep
                                  ? AppColors.orange
                                  : Colors.grey.shade300,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            // Step Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentStep == 0) _buildPhoneStep(),
                    if (_currentStep == 1) _buildPersonalDetailsStep(),
                    if (_currentStep == 2) _buildSkillSelectionStep(),
                    if (_currentStep == 3) _buildFederationVerificationStep(),
                  ],
                ),
              ),
            ),

            // Bottom CTA bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: PrimaryButton(
                        label: 'Back',
                        isOutlined: true,
                        onPressed: () => setState(() => _currentStep -= 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: PrimaryButton(
                      label: _currentStep == 3
                          ? 'Complete Registration'
                          : 'Continue',
                      isLoading: authState.isLoading,
                      onPressed: _nextStep,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Join the Cooperative Federation',
          style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your mobile number to receive an OTP verification code.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.inkLight),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Mobile Number',
            prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.orange),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Enter OTP (Default: 1234)',
            prefixIcon: const Icon(Icons.lock_clock_rounded, color: AppColors.orange),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal & Contact Details',
          style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        Text(
          'These details will appear on your verified partner badge.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.inkLight),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            prefixIcon: const Icon(Icons.person_rounded, color: AppColors.orange),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _experienceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Years of Experience',
            prefixIcon: const Icon(Icons.work_history_rounded, color: AppColors.orange),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Your Trade Skills',
          style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        Text(
          'Select the services you are certified to provide through the federation.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.inkLight),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _availableSkills.map((skill) {
            final isSelected = _selectedSkills.contains(skill);
            return FilterChip(
              label: Text(
                skill[0].toUpperCase() + skill.substring(1),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.ink,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.orange,
              backgroundColor: AppColors.surface,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.orange : AppColors.border,
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSkills.add(skill);
                  } else {
                    _selectedSkills.remove(skill);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFederationVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Federation Verification',
              style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(width: 8),
            const CooperativeBadge(isCompact: true),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your Labour Cooperative Federation affiliation code and trade certificate.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.inkLight),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _federationCodeController,
          decoration: InputDecoration(
            labelText: 'Federation Member Code',
            prefixIcon: const Icon(Icons.badge_rounded, color: AppColors.teal),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 20),

        // Document upload preview card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.verified_user_rounded, color: AppColors.teal, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NCCT Electrician Certificate',
                      style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Verified by Federation Board',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
            ],
          ),
        ),
      ],
    );
  }
}
