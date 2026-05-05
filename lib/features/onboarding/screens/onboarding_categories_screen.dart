import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/onboarding_provider.dart';
import 'package:orushops/features/onboarding/models/shop_catalog_data.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';
import '../widgets/onboarding_page.dart';

class OnboardingCategoriesScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingCategoriesScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<OnboardingCategoriesScreen> createState() => _OnboardingCategoriesScreenState();
}

class _OnboardingCategoriesScreenState extends ConsumerState<OnboardingCategoriesScreen> {
  List<ShopCategory> _catalogCategories = [];
  Set<String> _selectedCategories = {};
  final Set<String> _expandedCategories = {};
  final TextEditingController _newCategoryCtrl = TextEditingController();
  final List<String> _customCategories = [];
  String? _errorMessage;
  ShopType? _lastShopType;

  @override
  void initState() {
    super.initState();
    _syncToShopType(ref.read(onboardingProvider).shopDetails?.shopType ?? ShopType.other);
  }

  void _syncToShopType(ShopType shopType) {
    if (shopType == _lastShopType) return;
    _lastShopType = shopType;
    _catalogCategories = ShopCatalog.forType(shopType);
    _selectedCategories = _catalogCategories.map((c) => c.name).toSet();
    _customCategories.clear();
    _expandedCategories.clear();
  }

  @override
  void dispose() {
    _newCategoryCtrl.dispose();
    super.dispose();
  }

  void _toggleCategory(String name) {
    setState(() {
      if (_selectedCategories.contains(name)) {
        _selectedCategories.remove(name);
      } else {
        _selectedCategories.add(name);
      }
    });
  }

  void _toggleExpand(String name) {
    setState(() {
      if (_expandedCategories.contains(name)) {
        _expandedCategories.remove(name);
      } else {
        _expandedCategories.add(name);
      }
    });
  }

  void _addCustomCategory() {
    final name = _newCategoryCtrl.text.trim();
    setState(() {
      _errorMessage = null;
      if (name.isEmpty) {
        _errorMessage = 'Category name cannot be empty';
        return;
      }
      final allNames = [..._catalogCategories.map((c) => c.name), ..._customCategories];
      if (allNames.contains(name)) {
        _errorMessage = 'Category already exists';
        return;
      }
      if (name.length > 50) {
        _errorMessage = 'Max 50 characters';
        return;
      }
      _customCategories.add(name);
      _selectedCategories.add(name);
      _newCategoryCtrl.clear();
    });
  }

  void _removeCustomCategory(String name) {
    setState(() {
      _customCategories.remove(name);
      _selectedCategories.remove(name);
    });
  }

  void _handleNext() {
    if (_selectedCategories.isEmpty) {
      setState(() => _errorMessage = 'Select at least one category');
      return;
    }
    // Preserve catalog order, then custom at end
    final ordered = [
      ..._catalogCategories.map((c) => c.name).where(_selectedCategories.contains),
      ..._customCategories.where(_selectedCategories.contains),
    ];
    ref.read(onboardingProvider.notifier).updateShopCategories(ordered);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final shopType = ref.watch(onboardingProvider).shopDetails?.shopType ?? ShopType.other;
    // Sync silently if the user changed shop type upstream and came back
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && shopType != _lastShopType) setState(() => _syncToShopType(shopType));
    });

    return OnboardingPage(
      currentStep: 4,
      totalSteps: 4,
      title: 'Product Categories',
      description: 'Choose which categories apply to your store. Tap a category to expand subcategories.',
      showBackButton: true,
      onNext: _handleNext,
      onBack: widget.onBack,
      nextButtonText: 'Continue',
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSelectionHeader(),
            const SizedBox(height: 12),
            ..._catalogCategories.map(_buildCatalogCategoryTile),
            if (_customCategories.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Custom Categories',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
              ),
              ..._customCategories.map(_buildCustomCategoryTile),
            ],
            const SizedBox(height: 16),
            _buildAddCustomSection(),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: AppTheme.errorColor, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionHeader() {
    final total = _catalogCategories.length + _customCategories.length;
    final selected = _selectedCategories.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$selected of $total selected',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              if (_selectedCategories.length == total) {
                _selectedCategories.clear();
              } else {
                _selectedCategories = {
                  ..._catalogCategories.map((c) => c.name),
                  ..._customCategories,
                };
              }
            });
          },
          child: Text(
            _selectedCategories.length == total ? 'Deselect All' : 'Select All',
            style: TextStyle(fontSize: 12, color: AppTheme.accentColor),
          ),
        ),
      ],
    );
  }

  Widget _buildCatalogCategoryTile(ShopCategory cat) {
    final isSelected = _selectedCategories.contains(cat.name);
    final isExpanded = _expandedCategories.contains(cat.name);
    final hasSubs = cat.subcategories.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? AppTheme.accentColor : Colors.grey.shade300,
          width: isSelected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
        color: isSelected ? AppTheme.accentColor.withValues(alpha: 0.04) : Colors.white,
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _toggleCategory(cat.name),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? AppTheme.accentColor : Colors.grey.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppTheme.accentColor : Colors.black87,
                      ),
                    ),
                  ),
                  if (hasSubs)
                    GestureDetector(
                      onTap: () => _toggleExpand(cat.name),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${cat.subcategories.length} sub',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                            Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              size: 18,
                              color: Colors.grey.shade500,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (hasSubs && isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(42, 0, 12, 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: cat.subcategories
                    .map((sub) => Chip(
                          label: Text(sub, style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: Colors.grey.shade100,
                          side: BorderSide(color: Colors.grey.shade300),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomCategoryTile(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
        color: AppTheme.accentColor.withValues(alpha: 0.04),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppTheme.accentColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: AppTheme.errorColor,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _removeCustomCategory(name),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCustomSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Custom Category',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newCategoryCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Imported Goods',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _addCustomCategory(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addCustomCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ],
    );
  }
}
