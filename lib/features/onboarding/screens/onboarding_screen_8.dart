import 'package:flutter/material.dart';
import 'package:orushops/core/theme/app_theme.dart';
import '../widgets/fullscreen_onboarding_page.dart';

class OnboardingScreen8 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingScreen8({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingScreen8> createState() => _OnboardingScreen8State();
}

class _OnboardingScreen8State extends State<OnboardingScreen8> {
  final _codeController = TextEditingController();
  bool _isValid = false;

  void _validate(String value) {
    setState(() {
      _isValid = value.length >= 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FullscreenOnboardingPage(
      onBack: widget.onBack,
      icon: const Icon(Icons.verified_user_outlined, color: AppTheme.textSecondary, size: 32),
      title: "Enter code",
      subtitle: "Your temporary login code was sent to:\n(555) 867-5309",
      primaryButtonText: 'Continue',
      isPrimaryButtonEnabled: _isValid,
      onPrimaryAction: widget.onNext,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Didn't receive a code? "),
          GestureDetector(
            onTap: () {},
            child: const Text(
              "Send again",
              style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: TextField(
        controller: _codeController,
        onChanged: _validate,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Code',
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
          ),
        ),
      ),
    );
  }
}
