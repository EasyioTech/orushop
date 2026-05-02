import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/onboarding_provider.dart';
import '../widgets/fullscreen_onboarding_page.dart';

class OnboardingScreen3 extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final String currentLanguage;

  const OnboardingScreen3({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.currentLanguage,
  });

  @override
  ConsumerState<OnboardingScreen3> createState() => _OnboardingScreen3State();
}

class _OnboardingScreen3State extends ConsumerState<OnboardingScreen3> {
  late TextEditingController _emailController;
  bool _isValid = false;
  bool _stayUpdated = true;

  @override
  void initState() {
    super.initState();
    final currentEmail = ref.read(onboardingProvider).emailOrPhone ?? '';
    _emailController = TextEditingController(text: currentEmail);
    _validate(currentEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _validate(String value) {
    setState(() {
      _isValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
    });
  }

  void _handleNext() {
    if (_isValid) {
      ref.read(onboardingProvider.notifier).setEmailOrPhone(_emailController.text);
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FullscreenOnboardingPage(
      onBack: widget.onBack,
      icon: const Icon(
        Icons.email_outlined,
        color: AppTheme.textSecondary,
        size: 32,
      ),
      title: "Get going with email",
      subtitle: "Enter your email to get started with OruShops",
      primaryButtonText: 'Continue',
      isPrimaryButtonEnabled: _isValid,
      onPrimaryAction: _handleNext,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _emailController,
            onChanged: _validate,
            autofocus: false,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'email@example.com',
              contentPadding: const EdgeInsets.all(20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _stayUpdated,
                  onChanged: (val) => setState(() => _stayUpdated = val ?? false),
                  activeColor: AppTheme.accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Stay up to date with the latest features and news from OruShops',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
