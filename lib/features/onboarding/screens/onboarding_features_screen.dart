import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';
import 'package:orushops/providers/onboarding_provider.dart';
import '../widgets/onboarding_page.dart';

class OnboardingFeaturesScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingFeaturesScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<OnboardingFeaturesScreen> createState() => _OnboardingFeaturesScreenState();
}

class _OnboardingFeaturesScreenState extends ConsumerState<OnboardingFeaturesScreen> {
  late ShopFeatures _features;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProvider);
    _features = state.shopDetails?.features.copy() ?? ShopFeatures(
      expiryDateTracking: false,
      batchNumber: false,
      serialNumberTracking: false,
      gstTaxInvoicing: true,
      sizeVariant: false,
      recipeIngredients: false,
      lowStockAlerts: true,
      prescriptionRequired: false,
    );
  }

  void _handleNext() {
    ref.read(onboardingProvider.notifier).updateShopFeatures(_features);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final shopType = state.shopDetails?.shopType;
    final config = shopType != null ? ShopTypeConfig.getConfig(shopType) : null;

    return OnboardingPage(
      currentStep: 3,
      totalSteps: 4,
      title: "Features for Your Store",
      description: "Customize features based on your shop type. Toggle to enable/disable.",
      showBackButton: true,
      onNext: _handleNext,
      onBack: widget.onBack,
      nextButtonText: 'Continue',
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (config != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'For ${config.displayName}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
              ),
            _buildFeatureToggle(
              title: 'Expiry Date Tracking',
              description: 'Track and manage product expiry dates',
              value: _features.expiryDateTracking,
              onChanged: (value) {
                setState(() => _features.expiryDateTracking = value);
              },
            ),
            const SizedBox(height: 12),
            _buildFeatureToggle(
              title: 'Batch Number',
              description: 'Track products by batch number',
              value: _features.batchNumber,
              onChanged: (value) {
                setState(() => _features.batchNumber = value);
              },
            ),
            const SizedBox(height: 12),
            _buildFeatureToggle(
              title: 'Serial Number Tracking',
              description: 'Track individual serial numbers for electronics',
              value: _features.serialNumberTracking,
              onChanged: (value) {
                setState(() => _features.serialNumberTracking = value);
              },
            ),
            const SizedBox(height: 12),
            _buildFeatureToggle(
              title: 'GST / Tax Invoicing',
              description: 'Generate GST-compliant invoices',
              value: _features.gstTaxInvoicing,
              onChanged: (value) {
                setState(() => _features.gstTaxInvoicing = value);
              },
            ),
            const SizedBox(height: 12),
            _buildFeatureToggle(
              title: 'Size / Variant (S/M/L)',
              description: 'Manage size and variant options',
              value: _features.sizeVariant,
              onChanged: (value) {
                setState(() => _features.sizeVariant = value);
              },
            ),
            const SizedBox(height: 12),
            _buildFeatureToggle(
              title: 'Recipe / Ingredients',
              description: 'Track recipes and ingredient usage',
              value: _features.recipeIngredients,
              onChanged: (value) {
                setState(() => _features.recipeIngredients = value);
              },
            ),
            const SizedBox(height: 12),
            _buildFeatureToggle(
              title: 'Low Stock Alerts',
              description: 'Get notified when stock runs low',
              value: _features.lowStockAlerts,
              onChanged: (value) {
                setState(() => _features.lowStockAlerts = value);
              },
            ),
            const SizedBox(height: 12),
            _buildFeatureToggle(
              title: 'Prescription Required',
              description: 'Mark products that require prescriptions',
              value: _features.prescriptionRequired,
              onChanged: (value) {
                setState(() => _features.prescriptionRequired = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureToggle({
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.accentColor,
          ),
        ],
      ),
    );
  }
}
