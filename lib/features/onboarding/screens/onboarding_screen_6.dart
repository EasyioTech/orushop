import 'package:flutter/material.dart';
import 'package:orushops/core/theme/app_theme.dart';
import '../widgets/fullscreen_onboarding_page.dart';

class OnboardingScreen6 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingScreen6({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingScreen6> createState() => _OnboardingScreen6State();
}

class _OnboardingScreen6State extends State<OnboardingScreen6> {
  final _emailController = TextEditingController();
  bool _isValid = false;

  void _validate(String value) {
    setState(() {
      _isValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FullscreenOnboardingPage(
      onBack: widget.onBack,
      icon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textSecondary, size: 32),
      title: "Forgot your password?",
      subtitle: "Enter the email associated with your account.",
      primaryButtonText: 'Reset password',
      isPrimaryButtonEnabled: _isValid,
      onPrimaryAction: widget.onNext,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Remember your password? "),
          GestureDetector(
            onTap: widget.onBack,
            child: const Text(
              "Sign in.",
              style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: TextField(
        controller: _emailController,
        onChanged: _validate,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: 'Email address',
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
          ),
        ),
      ),
    );
  }
}
