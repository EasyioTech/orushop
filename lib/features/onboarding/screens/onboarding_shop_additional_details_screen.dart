import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  ShopType? _selectedShopType;
  String? _shopTypeError;
  final MenuController _menuController = MenuController();

  @override
  void initState() {
    super.initState();
    final onboardingState = ref.read(onboardingProvider);
    final details = onboardingState.shopDetails;
    _gstCtrl = TextEditingController(text: details?.gstNumber);
    _notesCtrl = TextEditingController(text: details?.otherDetails);
    
    // Remember explicitly selected shop type, otherwise start as unselected (null)
    if (onboardingState.hasSelectedShopType) {
      _selectedShopType = details?.shopType;
    } else {
      _selectedShopType = null;
    }
  }

  @override
  void dispose() {
    _gstCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_selectedShopType == null) {
      setState(() {
        _shopTypeError = 'Please select a shop type to continue';
      });
      _menuController.open();
      HapticFeedback.heavyImpact();
      return;
    }

    ref.read(onboardingProvider.notifier).updateShopDetails(
      shopType: _selectedShopType,
      gstNumber: _gstCtrl.text.isEmpty ? null : _gstCtrl.text,
      otherDetails: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
      hasSelectedShopType: true,
    );
    widget.onNext();
  }

  IconData _getShopIcon(ShopType type) {
    switch (type) {
      case ShopType.medical:
        return Icons.medical_services_rounded;
      case ShopType.grocery:
        return Icons.local_grocery_store_rounded;
      case ShopType.electronics:
        return Icons.electric_bolt_rounded;
      case ShopType.clothing:
        return Icons.checkroom_rounded;
      case ShopType.bakery:
        return Icons.cake_rounded;
      case ShopType.stationery:
        return Icons.menu_book_rounded;
      case ShopType.hardware:
        return Icons.build_rounded;
      case ShopType.cosmetics:
        return Icons.face_retouching_natural_rounded;
      case ShopType.mobile:
        return Icons.phone_android_rounded;
      case ShopType.restaurant:
        return Icons.restaurant_rounded;
      case ShopType.other:
        return Icons.storefront_rounded;
    }
  }

  Color _getShopColor(ShopType type) {
    switch (type) {
      case ShopType.medical:
        return const Color(0xFF007AFF); // Blue
      case ShopType.grocery:
        return const Color(0xFF34C759); // Green
      case ShopType.electronics:
        return const Color(0xFFFF9500); // Orange
      case ShopType.clothing:
        return const Color(0xFFAF52DE); // Purple
      case ShopType.bakery:
        return const Color(0xFFFF2D55); // Pink
      case ShopType.stationery:
        return const Color(0xFF5856D6); // Deep Indigo
      case ShopType.hardware:
        return const Color(0xFF8E8E93); // Grey
      case ShopType.cosmetics:
        return const Color(0xFFFF3B30); // Red
      case ShopType.mobile:
        return const Color(0xFF5AC8FA); // Teal/Cyan
      case ShopType.restaurant:
        return const Color(0xFFFFCC00); // Yellow
      case ShopType.other:
        return const Color(0xFF8E8E93); // Slate
    }
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
    final double dropdownWidth = MediaQuery.of(context).size.width - 48;
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
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        MenuAnchor(
          controller: _menuController,
          style: MenuStyle(
            backgroundColor: WidgetStateProperty.all(Colors.white),
            elevation: WidgetStateProperty.all(8),
            padding: WidgetStateProperty.all(EdgeInsets.zero),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE5E5EA), width: 1),
              ),
            ),
            fixedSize: WidgetStateProperty.all(Size.fromWidth(dropdownWidth)),
          ),
          alignmentOffset: const Offset(0, 4),
          menuChildren: ShopType.values.map((ShopType type) {
            final config = ShopTypeConfig.getConfig(type);
            final icon = _getShopIcon(type);
            final color = _getShopColor(type);
            final isSelected = _selectedShopType == type;

            return MenuItemButton(
              onPressed: () {
                setState(() {
                  _selectedShopType = type;
                  _shopTypeError = null;
                });
              },
              style: MenuItemButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: isSelected ? color.withValues(alpha: 0.05) : Colors.transparent,
              ),
              child: SizedBox(
                width: dropdownWidth - 32,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        config.displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.successColor,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
          builder: (BuildContext context, MenuController controller, Widget? child) {
            return GestureDetector(
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _shopTypeError != null
                        ? AppTheme.errorColor
                        : Colors.black12,
                    width: _shopTypeError != null ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _shopTypeError != null
                          ? AppTheme.errorColor.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedShopType != null
                            ? _getShopColor(_selectedShopType!).withValues(alpha: 0.1)
                            : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _selectedShopType != null
                            ? _getShopIcon(_selectedShopType!)
                            : Icons.storefront_rounded,
                        color: _selectedShopType != null
                            ? _getShopColor(_selectedShopType!)
                            : AppTheme.textSecondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shop Type',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary.withValues(alpha: 0.8),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedShopType != null
                                ? ShopTypeConfig.getConfig(_selectedShopType!).displayName
                                : 'Select business category...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: _selectedShopType != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: _selectedShopType != null
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: controller.isOpen ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textSecondary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (_shopTypeError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.errorColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _shopTypeError!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'This helps us customize the features for your shop.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
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
                color: AppTheme.textPrimary,
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
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
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
