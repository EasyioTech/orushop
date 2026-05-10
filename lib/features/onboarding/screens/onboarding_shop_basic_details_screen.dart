import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/onboarding_provider.dart';
import '../widgets/onboarding_page.dart';

class OnboardingShopBasicDetailsScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingShopBasicDetailsScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<OnboardingShopBasicDetailsScreen> createState() => _OnboardingShopBasicDetailsScreenState();
}

class _OnboardingShopBasicDetailsScreenState extends ConsumerState<OnboardingShopBasicDetailsScreen> {
  late TextEditingController _shopNameCtrl;
  late TextEditingController _ownerNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;

  String? _shopNameError;
  String? _ownerNameError;
  String? _phoneError;
  String? _addressError;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProvider);
    final details = state.shopDetails;

    // Pre-fill phone: prefer already-saved details, then the verified OTP phone
    // (pendingPhone is in E.164 format like +919876543210 — strip the +91 prefix for display)
    String prefilledPhone = details?.phoneNumber ?? '';
    if (prefilledPhone.isEmpty && state.pendingPhone != null) {
      final p = state.pendingPhone!;
      prefilledPhone = p.startsWith('+91') ? p.substring(3) : p;
    }

    _shopNameCtrl = TextEditingController(text: details?.shopName);
    _ownerNameCtrl = TextEditingController(text: details?.ownerName);
    _phoneCtrl = TextEditingController(text: prefilledPhone);
    _addressCtrl = TextEditingController(text: details?.shopAddress);
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final phone = _phoneCtrl.text.trim();
    final isDigitsOnly = RegExp(r'^\d+$').hasMatch(phone);

    setState(() {
      _shopNameError = _shopNameCtrl.text.trim().isEmpty ? 'Shop name is required' : null;
      _ownerNameError = _ownerNameCtrl.text.trim().isEmpty ? 'Owner name is required' : null;
      _phoneError = phone.isEmpty
          ? 'Phone number is required'
          : !isDigitsOnly
              ? 'Enter digits only (no spaces or dashes)'
              : phone.length != 10
                  ? 'Enter a valid 10-digit mobile number'
                  : null;
      _addressError = _addressCtrl.text.trim().isEmpty ? 'Address is required' : null;
    });

    return _shopNameError == null &&
        _ownerNameError == null &&
        _phoneError == null &&
        _addressError == null;
  }

  void _handleNext() {
    if (_validateForm()) {
      ref.read(onboardingProvider.notifier).updateShopDetails(
        shopName: _shopNameCtrl.text,
        ownerName: _ownerNameCtrl.text,
        phoneNumber: _phoneCtrl.text,
        shopAddress: _addressCtrl.text,
      );
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingPage(
      currentStep: 1,
      totalSteps: 2,
      title: 'Basic Shop Details',
      description: 'Start by telling us the essentials about your business.',
      showBackButton: true,
      onNext: _handleNext,
      onBack: widget.onBack,
      nextButtonText: 'Next',
      content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(
              controller: _shopNameCtrl,
              label: 'Shop Name',
              hint: 'Enter your shop name',
              error: _shopNameError,
              required: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _ownerNameCtrl,
              label: 'Owner Name',
              hint: 'Enter owner name',
              error: _ownerNameError,
              required: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneCtrl,
              label: 'Phone Number',
              hint: '10-digit mobile number',
              error: _phoneError,
              required: true,
              keyboardType: TextInputType.phone,
              digitsOnly: true,
              maxLength: 10,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressCtrl,
              label: 'Shop Address',
              hint: 'Enter complete address',
              error: _addressError,
              required: true,
              maxLines: 3,
            ),
          ],
        ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? error,
    bool required = false,
    int maxLines = 1,
    int? maxLength,
    bool digitsOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: digitsOnly
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: TextStyle(
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
              fontSize: 15,
            ),
            errorText: error,
            filled: true,
            fillColor: const Color(0xFFF2F2F7),
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
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.errorColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
