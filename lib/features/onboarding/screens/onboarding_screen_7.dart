import 'package:flutter/material.dart';
import 'package:orushops/core/theme/app_theme.dart';
import '../widgets/fullscreen_onboarding_page.dart';

class OnboardingScreen7 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingScreen7({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingScreen7> createState() => _OnboardingScreen7State();
}

class _OnboardingScreen7State extends State<OnboardingScreen7> {
  final _phoneController = TextEditingController();
  bool _isValid = false;

  void _validate(String value) {
    setState(() {
      _isValid = value.length >= 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FullscreenOnboardingPage(
      onBack: widget.onBack,
      icon: const Icon(Icons.phone_outlined, color: AppTheme.textSecondary, size: 32),
      title: "Your phone number",
      subtitle: "It's helpful to provide a good reason for why the phone number is required.",
      primaryButtonText: 'Continue',
      isPrimaryButtonEnabled: _isValid,
      onPrimaryAction: widget.onNext,
      content: TextField(
        controller: _phoneController,
        onChanged: _validate,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          hintText: '(555) 123-4567',
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
          ),
        ),
      ),
    );
  }
}
