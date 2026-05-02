import 'package:flutter/material.dart';
import 'package:orushops/core/theme/app_theme.dart';
import '../widgets/fullscreen_onboarding_page.dart';

class OnboardingScreen11 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingScreen11({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingScreen11> createState() => _OnboardingScreen11State();
}

class _OnboardingScreen11State extends State<OnboardingScreen11> {
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _countryController = TextEditingController();
  bool _isValid = false;

  void _validate() {
    setState(() {
      _isValid = _addressController.text.isNotEmpty &&
          _cityController.text.isNotEmpty &&
          _zipController.text.isNotEmpty &&
          _countryController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FullscreenOnboardingPage(
      onBack: widget.onBack,
      icon: const Icon(Icons.location_on_outlined, color: AppTheme.textSecondary, size: 32),
      title: "Your address",
      subtitle: "It's helpful to provide a good reason for why the address is required.",
      primaryButtonText: 'Continue',
      isPrimaryButtonEnabled: _isValid,
      onPrimaryAction: widget.onNext,
      content: Column(
        children: [
          TextField(
            controller: _addressController,
            onChanged: (_) => _validate(),
            decoration: InputDecoration(
              hintText: 'Address',
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Address line 2',
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cityController,
            onChanged: (_) => _validate(),
            decoration: InputDecoration(
              hintText: 'City',
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _zipController,
            onChanged: (_) => _validate(),
            decoration: InputDecoration(
              hintText: 'Postal code',
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _countryController,
            onChanged: (_) => _validate(),
            decoration: InputDecoration(
              hintText: 'Country',
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
