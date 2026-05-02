import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orushops/core/theme/app_theme.dart';
import '../widgets/fullscreen_onboarding_page.dart';

class OnboardingScreen10 extends StatefulWidget {
  final Function(String firstName, String lastName) onNext;
  final VoidCallback onBack;

  const OnboardingScreen10({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingScreen10> createState() => _OnboardingScreen10State();
}

class _OnboardingScreen10State extends State<OnboardingScreen10> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthdayController = TextEditingController();
  bool _isValid = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _isValid =
          _firstNameController.text.isNotEmpty &&
          _lastNameController.text.isNotEmpty &&
          _birthdayController.text.length >= 10;
    });
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppTheme.textSecondary.withValues(alpha: 0.6),
        fontSize: 15,
      ),
      prefixIcon: Icon(icon, size: 20, color: AppTheme.textSecondary),
      filled: true,
      fillColor: const Color(0xFFF2F2F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FullscreenOnboardingPage(
      onBack: widget.onBack,
      icon: const Icon(
        Icons.badge_outlined,
        color: AppTheme.textSecondary,
        size: 32,
      ),
      title: 'Your details',
      subtitle: 'Please enter your legal name and date of birth.',
      primaryButtonText: 'Continue',
      isPrimaryButtonEnabled: _isValid,
      onPrimaryAction: () =>
          widget.onNext(_firstNameController.text, _lastNameController.text),
      content: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── First name ──────────────────────────────────
              _FieldLabel(text: 'First Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _firstNameController,
                onChanged: (_) => _validate(),
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _fieldDecoration(
                  hint: 'e.g. Your Name',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(height: 20),

              // ── Last name ───────────────────────────────────
              _FieldLabel(text: 'Last Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _lastNameController,
                onChanged: (_) => _validate(),
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _fieldDecoration(
                  hint: 'Your Last Name',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(height: 20),

              // ── Birthday ────────────────────────────────────
              _FieldLabel(text: 'Date of Birth'),
              const SizedBox(height: 8),
              TextField(
                controller: _birthdayController,
                onChanged: (_) => _validate(),
                keyboardType: TextInputType.datetime,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d/]')),
                  LengthLimitingTextInputFormatter(10),
                  _DateInputFormatter(),
                ],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _fieldDecoration(
                  hint: 'mm/dd/yyyy',
                  icon: Icons.cake_outlined,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Used to personalise your experience. Not shared publicly.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary.withValues(alpha: 0.65),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small label rendered above each input field
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1C1C1E),
        letterSpacing: 0.1,
      ),
    );
  }
}

/// Auto-inserts slashes as the user types a date: mm/dd/yyyy
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i == 1 || i == 3) && i < text.length - 1) {
        buffer.write('/');
      }
    }
    final result = buffer.toString();
    return newValue.copyWith(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
