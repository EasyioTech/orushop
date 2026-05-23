import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orushops/features/inventory/controllers/product_form_notifier.dart';
import 'package:orushops/features/inventory/models/product_form_state.dart';
import 'package:orushops/core/theme/app_theme.dart';

/// Step 1 — Primary Info
/// Contains: category banner, product name, stock+unit chip, selling price,
/// catalog suggestions, product image, live preview.
class InfoStep extends ConsumerStatefulWidget {
  final VoidCallback? onSave;
  const InfoStep({super.key, this.onSave});

  @override
  ConsumerState<InfoStep> createState() => _InfoStepState();
}

class _InfoStepState extends ConsumerState<InfoStep> {
  late final FocusNode _nameFocusNode;
  late final FocusNode _stockFocusNode;
  late final FocusNode _priceFocusNode;

  @override
  void initState() {
    super.initState();
    _nameFocusNode = FocusNode();
    _stockFocusNode = FocusNode();
    _priceFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _stockFocusNode.dispose();
    _priceFocusNode.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(productFormNotifierProvider.notifier);
    final state = ref.watch(productFormNotifierProvider);

    final nameController = notifier.controllers['name']!;
    final initialQtyController = notifier.controllers['initialQty']!;
    final priceController = notifier.controllers['price']!;

    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryBanner(state),

          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRIMARY DETAILS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Product Name
                TextField(
                  controller: nameController,
                  focusNode: _nameFocusNode,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: AppTheme.premiumDecoration(
                    label: 'Product Name',
                    hint: 'e.g. Sugar, Milk, Paracetamol',
                    prefixIcon: const Icon(CupertinoIcons.square_grid_2x2, color: AppTheme.primaryColor),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) {
                    if (!state.isService) {
                      _stockFocusNode.requestFocus();
                    } else {
                      _priceFocusNode.requestFocus();
                    }
                  },
                ),

                // Current Stock
                if (!state.isService) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: initialQtyController,
                          focusNode: _stockFocusNode,
                          keyboardType: TextInputType.numberWithOptions(decimal: state.isLoose),
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          decoration: AppTheme.premiumDecoration(
                            label: 'Current Stock',
                            hint: 'e.g. 10  (blank = zero)',
                            prefixIcon: const Icon(CupertinoIcons.cube_box, color: AppTheme.primaryColor),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  state.selectedUnit,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          onChanged: (value) => notifier.updateInventoryField('initialQty', value),
                          onSubmitted: (_) => _priceFocusNode.requestFocus(),
                        ),
                      ),
                      if (!state.isLoose) ...[
                        const SizedBox(width: 12),
                        _roundBtn(
                          icon: CupertinoIcons.minus,
                          onPressed: () {
                            final val = double.tryParse(initialQtyController.text) ?? 0;
                            if (val > 0) {
                              initialQtyController.text = (val - 1).toStringAsFixed(0);
                              notifier.updateInventoryField('initialQty', initialQtyController.text);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        _roundBtn(
                          icon: CupertinoIcons.plus,
                          onPressed: () {
                            final val = double.tryParse(initialQtyController.text) ?? 0;
                            initialQtyController.text = (val + 1).toStringAsFixed(0);
                            notifier.updateInventoryField('initialQty', initialQtyController.text);
                          },
                        ),
                      ],
                    ],
                  ),
                ],

                // Selling Price
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  focusNode: _priceFocusNode,
                  textInputAction: TextInputAction.done,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: AppTheme.premiumDecoration(
                    label: 'Selling Price',
                    hint: 'e.g. 50',
                    prefixIcon: const Icon(CupertinoIcons.tag_fill, color: AppTheme.successColor),
                    prefixText: '₹ ',
                    activeColor: AppTheme.successColor,
                  ),
                  onChanged: (value) => notifier.updatePricingField('price', value),
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                ),
              ],
            ),
          ),

          // Catalog suggestions
          if (state.catalogSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryDark.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: state.catalogSuggestions.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: AppTheme.slate100),
                itemBuilder: (context, index) {
                  final item = state.catalogSuggestions[index];
                  return ListTile(
                    leading: const Icon(CupertinoIcons.sparkles, color: AppTheme.primaryColor, size: 20),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: item.category != null ? Text(item.category!) : null,
                    onTap: () => notifier.applyCatalogSuggestion(item),
                  );
                },
              ),
            ),
          ],

          // Product Images
          const SizedBox(height: 24),
          const Text(
            'PRODUCT IMAGES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: AppTheme.slate500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  onPressed: () {
                    notifier.pickProductImage(source: ImageSource.camera);
                    HapticFeedback.lightImpact();
                  },
                  icon: CupertinoIcons.camera_fill,
                  label: 'Take Photo',
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionBtn(
                  onPressed: () {
                    notifier.pickProductImage(source: ImageSource.gallery);
                    HapticFeedback.lightImpact();
                  },
                  icon: CupertinoIcons.photo_on_rectangle,
                  label: 'Choose Gallery',
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          if (state.productImage != null) ...[
            const SizedBox(height: 16),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.file(state.productImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: () => notifier.clearProductImage(),
                    child: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ],

          // Live Preview
          const SizedBox(height: 24),
          const Text(
            'LIVE PREVIEW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: AppTheme.slate500,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(state, nameController, priceController),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCategoryBanner(ProductFormState state) {
    final category = state.selectedCategory;
    if (category == null) return const SizedBox.shrink();

    final icon = _getCategoryIcon(category.name);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.15),
            AppTheme.accentColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.selectedSubcategory ?? 'Product details and stock information',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ProductFormState state, TextEditingController nameCtrl, TextEditingController priceCtrl) {
    return _buildCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.slate100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: state.productImage != null
                ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(state.productImage!, fit: BoxFit.cover))
                : const Icon(CupertinoIcons.cube_box, color: AppTheme.slate400),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameCtrl.text.isEmpty ? 'New Item' : nameCtrl.text,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.5),
                ),
                Text(
                  priceCtrl.text.isEmpty ? '₹0.00' : 'Selling at ₹${priceCtrl.text}',
                  style: const TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                if (state.selectedCategory != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    state.selectedCategory!.name,
                    style: const TextStyle(fontSize: 12, color: AppTheme.slate500, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, Color? color}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _roundBtn({required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: AppTheme.slate100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 18, color: AppTheme.textPrimary),
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
