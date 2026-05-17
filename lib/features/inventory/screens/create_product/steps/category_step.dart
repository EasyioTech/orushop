import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/features/onboarding/models/shop_catalog_data.dart';
import 'package:orushops/features/inventory/controllers/product_form_notifier.dart';
import 'package:orushops/providers/shop_provider.dart';
import 'package:orushops/core/theme/app_theme.dart';

class CategoryStep extends ConsumerWidget {
  const CategoryStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(productFormNotifierProvider.notifier);
    final state = ref.watch(productFormNotifierProvider);

    final shopType = ref.watch(shopTypeProvider);
    final categories = ShopCatalog.forType(shopType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Item Category',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Choose a category to automatically configure specialized inventory fields',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            key: const ValueKey(0),
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.1,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = state.selectedCategory == cat;
              return GestureDetector(
                onTap: () {
                  notifier.onCategoryChanged(cat);
                  HapticFeedback.mediumImpact();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        child: Icon(
                          _getCategoryIcon(cat.name),
                          size: 20,
                          color: isSelected ? Colors.white : AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('tablet') || n.contains('medicine')) return CupertinoIcons.capsule_fill;
    if (n.contains('grocery') || n.contains('rice') || n.contains('atta')) return CupertinoIcons.cart_fill;
    if (n.contains('electric') || n.contains('tv')) return CupertinoIcons.tv_fill;
    if (n.contains('cloth') || n.contains('men')) return CupertinoIcons.tag_fill;
    if (n.contains('bakery') || n.contains('cake')) return CupertinoIcons.bag_fill;
    if (n.contains('stationery') || n.contains('pen')) return CupertinoIcons.pencil;
    if (n.contains('hardware') || n.contains('tool')) return CupertinoIcons.hammer_fill;
    if (n.contains('beauty') || n.contains('skin')) return CupertinoIcons.sparkles;
    if (n.contains('mobile') || n.contains('phone')) return CupertinoIcons.phone_fill;
    return CupertinoIcons.cube_box_fill;
  }
}
