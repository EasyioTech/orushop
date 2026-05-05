import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/onboarding_provider.dart';
import '../widgets/fullscreen_onboarding_page.dart';

class OnboardingScreen8 extends ConsumerStatefulWidget {
  final String verificationId;
  final String phone;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingScreen8({
    super.key,
    required this.verificationId,
    required this.phone,
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<OnboardingScreen8> createState() => _OnboardingScreen8State();
}

class _OnboardingScreen8State extends ConsumerState<OnboardingScreen8> {
  final _codeController = TextEditingController();
  late String _verificationId;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;

  // Resend cooldown
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startCooldown();
  }

  void _startCooldown() {
    _resendCooldown = 30;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  bool get _isValid => _codeController.text.length == 6;

  Future<void> _verify() async {
    if (!_isValid) return;
    setState(() { _isVerifying = true; _error = null; });
    try {
      final ok = await ref.read(onboardingProvider.notifier).verifyOtp(
        _verificationId,
        _codeController.text,
      );
      if (!mounted) return;
      if (ok) {
        widget.onNext();
      } else {
        setState(() => _error = 'Verification failed. Please try again.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0 || _isResending) return;
    setState(() { _isResending = true; _error = null; });
    try {
      final newId = await ref.read(onboardingProvider.notifier).sendOtp(widget.phone);
      if (!mounted) return;
      _verificationId = newId;
      _codeController.clear();
      _startCooldown();
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('invalid-verification-code')) return 'Incorrect OTP. Please check and try again.';
    if (msg.contains('session-expired')) return 'OTP expired. Please request a new one.';
    if (msg.contains('too-many-requests')) return 'Too many attempts. Please wait before trying again.';
    return 'Something went wrong. Please try again.';
  }

  String get _maskedPhone {
    if (widget.phone.length >= 10) {
      final last4 = widget.phone.substring(widget.phone.length - 4);
      return '+91 XXXXXX$last4';
    }
    return widget.phone;
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FullscreenOnboardingPage(
      onBack: widget.onBack,
      icon: const Icon(Icons.verified_user_outlined, color: AppTheme.textSecondary, size: 32),
      title: 'Enter OTP',
      subtitle: 'A 6-digit code was sent to $_maskedPhone',
      primaryButtonText: _isVerifying ? 'Verifying…' : 'Verify',
      isPrimaryButtonEnabled: _isValid && !_isVerifying,
      onPrimaryAction: _verify,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Didn't receive a code? "),
          GestureDetector(
            onTap: _resendCooldown == 0 && !_isResending ? _resend : null,
            child: Text(
              _isResending
                  ? 'Sending…'
                  : _resendCooldown > 0
                      ? 'Resend in ${_resendCooldown}s'
                      : 'Resend',
              style: TextStyle(
                color: _resendCooldown == 0 && !_isResending
                    ? AppTheme.accentColor
                    : AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification Code',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _codeController,
            onChanged: (_) => setState(() { _error = null; }),
            onSubmitted: (_) => _verify(),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '------',
              hintStyle: TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                color: AppTheme.textSecondary.withValues(alpha: 0.4),
              ),
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
