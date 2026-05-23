import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/onboarding_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  late TextEditingController _referralCodeCtrl;

  String? _shopNameError;
  String? _ownerNameError;
  String? _phoneError;
  String? _addressError;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProvider);
    final details = state.shopDetails;
    final user = FirebaseAuth.instance.currentUser;

    // Pre-fill phone: prefer already-saved details, then the verified OTP phone, then Firebase Auth phone
    String prefilledPhone = details?.phoneNumber ?? '';
    if (prefilledPhone.isEmpty && state.pendingPhone != null) {
      final p = state.pendingPhone!;
      prefilledPhone = p.startsWith('+91') ? p.substring(3) : p;
    }
    if (prefilledPhone.isEmpty && user?.phoneNumber != null) {
      final p = user!.phoneNumber!;
      prefilledPhone = p.startsWith('+91') ? p.substring(3) : p;
    }

    _shopNameCtrl = TextEditingController(text: details?.shopName);
    _ownerNameCtrl = TextEditingController(text: details?.ownerName ?? user?.displayName);
    _phoneCtrl = TextEditingController(text: prefilledPhone);
    _addressCtrl = TextEditingController(text: details?.shopAddress);
    _referralCodeCtrl = TextEditingController(text: details?.referralCode);
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _referralCodeCtrl.dispose();
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
        referralCode: _referralCodeCtrl.text.trim().isEmpty ? null : _referralCodeCtrl.text.trim(),
      );
      FocusScope.of(context).unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) widget.onNext();
      });
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
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE8F5E9), // Extremely soft light mint green
                    Color(0xFFC8E6C9), // Soft mint green
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFA5D6A7),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.card_giftcard_rounded,
                        color: Color(0xFF2E7D32),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Referral Code',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.green[900],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'OPTIONAL',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter a referral code to get future rewards and starter benefits.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _referralCodeCtrl,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF064E3B),
                      letterSpacing: 1.0,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter referral code',
                      hintStyle: TextStyle(
                        color: Colors.green[700]?.withValues(alpha: 0.6),
                        fontSize: 14,
                        letterSpacing: 0.0,
                      ),
                      prefixIcon: const Icon(
                        Icons.confirmation_number_outlined,
                        color: Color(0xFF2E7D32),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
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
