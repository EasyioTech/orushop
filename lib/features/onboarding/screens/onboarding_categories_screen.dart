import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/onboarding_provider.dart';
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
  late List<String> _categories;
  late TextEditingController _newCategoryCtrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProvider);
    _categories = List.from(state.shopDetails?.productCategories ?? []);
    _newCategoryCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _newCategoryCtrl.dispose();
    super.dispose();
  }

  void _addCategory() {
    final newCategory = _newCategoryCtrl.text.trim();

    setState(() {
      _errorMessage = null;

      if (newCategory.isEmpty) {
        _errorMessage = 'Category name cannot be empty';
        return;
      }

      if (_categories.contains(newCategory)) {
        _errorMessage = 'Category already exists';
        return;
      }

      if (newCategory.length > 50) {
        _errorMessage = 'Category name too long (max 50 characters)';
        return;
      }

      _categories.add(newCategory);
      _newCategoryCtrl.clear();
    });
  }

  void _removeCategory(int index) {
    setState(() {
      _categories.removeAt(index);
      _errorMessage = null;
    });
  }

  void _handleNext() {
    if (_categories.isEmpty) {
      setState(() => _errorMessage = 'Add at least one product category');
      return;
    }

    ref.read(onboardingProvider.notifier).updateShopCategories(_categories);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingPage(
      currentStep: 4,
      totalSteps: 4,
      title: 'Product Categories',
      description: 'Add or customize the product categories for your store.',
      showBackButton: true,
      onNext: _handleNext,
      onBack: widget.onBack,
      nextButtonText: 'Continue',
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAddCategorySection(),
            const SizedBox(height: 24),
            _buildCategoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add New Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newCategoryCtrl,
                decoration: InputDecoration(
                  hintText: 'Enter category name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _addCategory(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _addCategory,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: AppTheme.errorColor,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories (${_categories.length})',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (_categories.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No categories added yet. Add your first category above.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _buildCategoryItem(_categories[index], index);
            },
          ),
      ],
    );
  }

  Widget _buildCategoryItem(String category, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: 20,
            color: AppTheme.errorColor,
            onPressed: () => _removeCategory(index),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
