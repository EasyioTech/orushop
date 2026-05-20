import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/features/inventory/controllers/product_form_notifier.dart';
import 'package:orushops/core/theme/app_theme.dart';

class PricingStep extends ConsumerStatefulWidget {
  const PricingStep({super.key});

  @override
  ConsumerState<PricingStep> createState() => _PricingStepState();
}

class _PricingStepState extends ConsumerState<PricingStep> {
  final FocusNode _costFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _costFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(productFormNotifierProvider.notifier);
    final state = ref.watch(productFormNotifierProvider);
    final priceController = notifier.controllers['price']!;
    final wholesalePriceController = notifier.controllers['wholesalePrice']!;
    final costController = notifier.controllers['costPrice']!;
    final mrpController = notifier.controllers['mrp']!;
    final taxController = notifier.controllers['tax']!;

    ref.listen<bool>(
      productFormNotifierProvider.select((state) => state.showAdvancedPricing),
      (previous, next) {
        if (next && previous != next) {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
            if (mounted) {
              _costFocusNode.requestFocus();
            }
          });
        }
      },
    );

    return SingleChildScrollView(
      controller: _scrollController,
      key: const ValueKey(2),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item Price',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'How much do customers pay? Enter a simple price below. Other options are optional.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Main Price Card (Always visible, simple, easy to understand)
          _buildBigCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'REQUIRED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: AppTheme.premiumDecoration(
                    label: 'Customers Pay This (Price) *',
                    hint: 'Enter selling price, e.g. 50',
                    prefixIcon: const Icon(CupertinoIcons.tag_fill, color: AppTheme.successColor),
                    prefixText: '₹ ',
                    activeColor: AppTheme.successColor,
                  ),
                  onChanged: (value) => notifier.updatePricingField('price', value),
                  onSubmitted: (_) {
                    if (!state.showAdvancedPricing) {
                      notifier.setAdvancedPricing(true);
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted) {
                          _costFocusNode.requestFocus();
                        }
                      });
                    } else {
                      _costFocusNode.requestFocus();
                    }
                  },
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'This is the main price you charge your customer for this item.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // Toggler for advanced options
          GestureDetector(
            onTap: () {
              notifier.setAdvancedPricing(!state.showAdvancedPricing);
              HapticFeedback.lightImpact();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: state.showAdvancedPricing ? AppTheme.accentColor : AppTheme.slate200,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    state.showAdvancedPricing ? CupertinoIcons.chevron_up_circle_fill : CupertinoIcons.plus_circle_fill,
                    color: AppTheme.accentColor,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.showAdvancedPricing 
                          ? 'Hide Extra Options' 
                          : 'Show Extra Options (Buying Cost, MRP, Tax)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    state.showAdvancedPricing ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                    color: AppTheme.slate400,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          // Advanced Options Card (Expandable list)
          if (state.showAdvancedPricing) ...[
            const SizedBox(height: 16),
            _buildBigCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXTRA OPTIONS (OPTIONAL)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppTheme.slate500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Cost Price (Buying Cost)
                  TextField(
                    controller: costController,
                    focusNode: _costFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: AppTheme.premiumDecoration(
                      label: 'What You Paid (Buying Cost)',
                      hint: 'How much you paid to get this item',
                      prefixIcon: const Icon(CupertinoIcons.bag_fill, color: AppTheme.errorColor),
                      prefixText: '₹ ',
                      activeColor: AppTheme.errorColor,
                    ),
                    onChanged: (value) => notifier.updatePricingField('costPrice', value),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4, bottom: 16, left: 4),
                    child: Text(
                      'Optional: Helps you track your profit later.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),

                  // MRP
                  if (!state.isService && (state.selectedCategory?.productFields.hasMrp ?? true)) ...[
                    TextField(
                      controller: mrpController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: AppTheme.premiumDecoration(
                        label: 'Printed Price on Pack (MRP)',
                        hint: 'Highest price printed on packet',
                        prefixIcon: const Icon(CupertinoIcons.shield_fill, color: AppTheme.primaryColor),
                        prefixText: '₹ ',
                      ),
                      onChanged: (value) => notifier.updatePricingField('mrp', value),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 4, bottom: 16, left: 4),
                      child: Text(
                        'Optional: The maximum price printed on the box or packet.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],

                  // Wholesale Price
                  if (state.isLoose) ...[
                    TextField(
                      controller: wholesalePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: AppTheme.premiumDecoration(
                        label: 'Bulk Price (Wholesale)',
                        hint: 'Special lower price for bulk buyers',
                        prefixIcon: const Icon(CupertinoIcons.square_grid_3x2_fill, color: Color(0xFFFF9500)),
                        prefixText: '₹ ',
                        activeColor: const Color(0xFFFF9500),
                      ),
                      onChanged: (value) => notifier.updatePricingField('wholesalePrice', value),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 4, bottom: 16, left: 4),
                      child: Text(
                        'Optional: Lower price per unit if customers buy in bulk.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],

                  // Tax Rate
                  if (state.selectedCategory?.productFields.hasTaxRate ?? false) ...[
                    TextField(
                      controller: taxController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: AppTheme.premiumDecoration(
                        label: 'Tax / GST (%)',
                        hint: 'Enter percentage, e.g. 5, 12, 18',
                        prefixIcon: const Icon(CupertinoIcons.percent, color: AppTheme.primaryColor),
                        suffixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Text('%', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.slate400, fontSize: 16)),
                        ),
                      ),
                      onChanged: (value) => notifier.updatePricingField('tax', value),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        'Optional: GST or government tax rate on this item.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBigCard({required Widget child, Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
