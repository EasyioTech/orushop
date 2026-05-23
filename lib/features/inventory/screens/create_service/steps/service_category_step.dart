import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/core/models/service_category_model.dart';
import 'package:orushops/providers/service_categories_provider.dart';
import 'package:orushops/providers/onboarding_provider.dart';
import 'package:orushops/features/inventory/controllers/service_form_notifier.dart';

class ServiceCategoryStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const ServiceCategoryStep({super.key, required this.onNext});

  @override
  ConsumerState<ServiceCategoryStep> createState() => _ServiceCategoryStepState();
}

class _ServiceCategoryStepState extends ConsumerState<ServiceCategoryStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedEmoji = '🛠️';

  final List<String> _emojiList = [
    '🛠️', '💇', '💅', '🩺', '🚗', '🧼', '🚚', '📦', '💻', '📷',
    '🧹', '🔌', '🚰', '🍕', '🍰', '🧵', '📝', '📚', '🎨', '💼',
    '🧘', '🏠', '🔒', '💡', '🏗️', '📞', '🔋', '📱', '🩺', '🛒'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showAddCategorySheet(BuildContext context, String? shopType) {
    _nameController.clear();
    setState(() {
      _selectedEmoji = '🛠️';
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Custom Category',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: AppTheme.premiumDecoration(
                    label: 'Category Name',
                    hint: 'e.g. Premium Hairwash',
                    prefixIcon: const Icon(Icons.category_rounded, color: AppTheme.primaryColor),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a category name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Icon / Emoji',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _emojiList.length,
                    itemBuilder: (context, index) {
                      final emoji = _emojiList[index];
                      final isSelected = _selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setSheetState(() {
                            _selectedEmoji = emoji;
                          });
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                : AppTheme.slate50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        HapticFeedback.mediumImpact();
                        final newCategory = ServiceCategoryModel(
                          name: _nameController.text.trim(),
                          icon: _selectedEmoji,
                          shopType: shopType,
                          isSystem: false,
                          createdAt: DateTime.now(),
                        );

                        final repo = ref.read(serviceCategoryRepositoryProvider);
                        await repo.create(newCategory);
                        ref.invalidate(serviceCategoriesProvider(shopType));

                        if (context.mounted) {
                          ref.read(serviceFormNotifierProvider.notifier).setCategory(newCategory.name);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Category "${newCategory.name}" created and selected!'),
                              backgroundColor: AppTheme.successColor,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          widget.onNext();
                        }
                      }
                    },
                    child: const Text('Create & Select Category'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingProvider);
    final shopType = onboarding.shopDetails?.shopType.name;
    final categoriesAsync = ref.watch(serviceCategoriesProvider(shopType));
    final formState = ref.watch(serviceFormNotifierProvider);
    final formNotifier = ref.read(serviceFormNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Service Category',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Choose a category for this service or create a custom one',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showAddCategorySheet(context, shopType),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add First Category'),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.8,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = formState.serviceCategory == cat.name;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      formNotifier.setCategory(cat.name);
                      widget.onNext();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.accentColor : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppTheme.accentColor : AppTheme.slate200,
                          width: 1.5,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: AppTheme.accentColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          else
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : AppTheme.accentColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              cat.icon ?? '🛠️',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              cat.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading categories: $err')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddCategorySheet(context, shopType),
              icon: const Icon(Icons.add_rounded, color: AppTheme.primaryColor),
              label: const Text('Add Custom Category'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
