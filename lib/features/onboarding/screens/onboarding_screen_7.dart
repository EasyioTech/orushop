import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/onboarding_provider.dart';
import '../widgets/fullscreen_onboarding_page.dart';

class OnboardingScreen7 extends ConsumerStatefulWidget {
  final void Function(String verificationId, String phone) onOtpSent;
  final VoidCallback onBack;

  const OnboardingScreen7({
    super.key,
    required this.onOtpSent,
    required this.onBack,
  });

  @override
  ConsumerState<OnboardingScreen7> createState() => _OnboardingScreen7State();
}

class _OnboardingScreen7State extends ConsumerState<OnboardingScreen7> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  bool get _isValid {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10;
  }

  Future<void> _sendOtp() async {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return;

    setState(() { _isLoading = true; _error = null; });

    final phone = '+91$digits';
    try {
      ref.read(onboardingProvider.notifier).setPendingPhone(phone);
      final verificationId = await ref.read(onboardingProvider.notifier).sendOtp(phone);
      if (mounted) widget.onOtpSent(verificationId, phone);
    } catch (e) {
      if (mounted) {
        setState(() => _error = _friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(Object e) {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return 'Phone verification is not supported on Desktop. Please use an Android/iOS device or Google Sign-In.';
    }
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid-phone-number')) return 'Invalid phone number. Enter a valid 10-digit Indian mobile number.';
    if (msg.contains('too-many-requests')) return 'Too many attempts. Please try again later.';
    if (msg.contains('network')) return 'No internet connection. Check your network and try again.';
    if (msg.contains('app-not-verified')) return 'App verification failed (SafetyNet/App Check). Please check Firebase configuration.';
    return 'Failed to send OTP. Please try again.';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FullscreenOnboardingPage(
      onBack: widget.onBack,
      icon: const Icon(Icons.phone_outlined, color: AppTheme.textSecondary, size: 32),
      title: 'Enter your mobile number',
      subtitle: 'We\'ll send a 6-digit OTP to verify your number. Standard SMS rates may apply.',
      primaryButtonText: _isLoading ? 'Sending OTP…' : 'Send OTP',
      isPrimaryButtonEnabled: _isValid && !_isLoading,
      onPrimaryAction: _sendOtp,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mobile Number',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            onChanged: (_) => setState(() { _error = null; }),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              prefixText: '+91  ',
              prefixStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              hintText: '98765 43210',
              errorText: _error,
              contentPadding: const EdgeInsets.all(16),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.accentColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.errorColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
