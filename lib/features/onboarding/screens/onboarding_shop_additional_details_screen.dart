import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/onboarding_provider.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';
import '../widgets/onboarding_page.dart';

class OnboardingShopAdditionalDetailsScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingShopAdditionalDetailsScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<OnboardingShopAdditionalDetailsScreen> createState() => _OnboardingShopAdditionalDetailsScreenState();
}

class _OnboardingShopAdditionalDetailsScreenState extends ConsumerState<OnboardingShopAdditionalDetailsScreen> {
  late TextEditingController _gstCtrl;
  late TextEditingController _notesCtrl;
  late ShopType _selectedShopType;

  @override
  void initState() {
    super.initState();
    final details = ref.read(onboardingProvider).shopDetails;
    _gstCtrl = TextEditingController(text: details?.gstNumber);
    _notesCtrl = TextEditingController(text: details?.otherDetails);
    _selectedShopType = details?.shopType ?? ShopType.medical;
  }

  @override
  void dispose() {
    _gstCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _handleNext() {
    ref.read(onboardingProvider.notifier).updateShopDetails(
      shopType: _selectedShopType,
      gstNumber: _gstCtrl.text.isEmpty ? null : _gstCtrl.text,
      otherDetails: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
    );
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingPage(
      currentStep: 2,
      totalSteps: 2,
      title: 'Advanced Shop Details',
      description: 'Configure your shop type and other technical information.',
      showBackButton: true,
      onNext: _handleNext,
      onBack: widget.onBack,
      nextButtonText: 'Continue',
      content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDropdown(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _gstCtrl,
              label: 'GST Number',
              hint: 'Optional: Enter your GST number',
              required: false,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _notesCtrl,
              label: 'Other Details / Notes',
              hint: 'Optional: Any additional information',
              required: false,
              maxLines: 4,
            ),
          ],
        ),
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Shop Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ShopType>(
              value: _selectedShopType,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              onChanged: (ShopType? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedShopType = newValue;
                  });
                }
              },
              items: ShopType.values.map((ShopType type) {
                return DropdownMenuItem<ShopType>(
                  value: type,
                  child: Text(ShopTypeConfig.getConfig(type).displayName),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'This helps us customize the features for your shop.',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? error,
    bool required = false,
    int maxLines = 1,
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
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
