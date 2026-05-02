import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/onboarding_provider.dart';
import '../widgets/fullscreen_onboarding_page.dart';

class OnboardingScreen5 extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingScreen5({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<OnboardingScreen5> createState() => _OnboardingScreen5State();
}

class _OnboardingScreen5State extends ConsumerState<OnboardingScreen5> {
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  bool _hasMinLength = false;
  bool _hasLowercase = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _validatePassword(String value) {
    setState(() {
      _hasMinLength = value.length >= 8 && value.length <= 32;
      _hasLowercase = value.contains(RegExp(r'[a-z]'));
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasSpecial = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  bool get _isAllValid =>
      _hasMinLength && _hasLowercase && _hasUppercase && _hasNumber && _hasSpecial;

  void _handleNext() {
    if (_isAllValid) {
      ref.read(onboardingProvider.notifier).setPassword(_passwordController.text);
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FullscreenOnboardingPage(
      onBack: widget.onBack,
      icon: const Icon(
        Icons.lock_outline_rounded,
        color: AppTheme.textSecondary,
        size: 32,
      ),
      title: "Create password",
      primaryButtonText: 'Continue',
      isPrimaryButtonEnabled: _isAllValid,
      onPrimaryAction: _handleNext,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _passwordController,
            onChanged: _validatePassword,
            obscureText: !_isPasswordVisible,
            autofocus: false,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: '••••••••',
              contentPadding: const EdgeInsets.all(20),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppTheme.accentColor,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
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
          Text(
            'Your password must include:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          _buildRequirementRow('8-32 characters long', _hasMinLength),
          _buildRequirementRow('1 lowercase character (a-z)', _hasLowercase),
          _buildRequirementRow('1 uppercase character (A-Z)', _hasUppercase),
          _buildRequirementRow('1 number', _hasNumber),
          _buildRequirementRow('1 special character e.g. ! @ # \$ %', _hasSpecial),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.check_rounded,
            size: 18,
            color: isValid ? AppTheme.accentColor : AppTheme.borderColor,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isValid ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
