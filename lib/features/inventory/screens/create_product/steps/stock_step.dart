import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:orushops/features/inventory/controllers/product_form_notifier.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';
import 'package:orushops/providers/shop_provider.dart';
import 'package:orushops/core/theme/app_theme.dart';

part 'stock_step/stock_step_helpers.dart';
class StockStep extends ConsumerWidget {
  const StockStep({super.key});

  static const Map<String, Color> _presetColors = {
    'Black': Color(0xFF1C1C1E),
    'White': Color(0xFFFFFFFF),
    'Grey': Color(0xFF8E8E93),
    'Red': Color(0xFFFF3B30),
    'Blue': Color(0xFF007AFF),
    'Green': Color(0xFF34C759),
    'Yellow': Color(0xFFFFCC00),
    'Orange': Color(0xFFFF9500),
    'Pink': Color(0xFFFF2D55),
    'Purple': Color(0xFFAF52DE),
    'Navy': Color(0xFF000080),
    'Brown': Color(0xFF8B4513),
  };

  static const List<String> _presetSizes = [
    'S', 'M', 'L', 'XL', 'XXL', 'XXXL',
    '28', '30', '32', '34', '36', '38', '40', '42'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(productFormNotifierProvider.notifier);
    final state = ref.watch(productFormNotifierProvider);
    final shopType = ref.watch(shopTypeProvider);
    final config = ShopTypeConfig.getConfig(shopType);
    final showToggles = !config.minimalFieldsMode;
    // Variant-matrix products define size/color as a grid in the Variants step,
    // so the single-value pickers here are only for non-matrix categories that
    // explicitly opt into a size/color attribute.
    final fields = state.selectedCategory?.productFields;
    final isVariantMatrix = fields?.template == ProductTemplate.variantMatrix;
    final showSize = (fields?.hasSizeVariant ?? false) && !isVariantMatrix;
    final showColor = (fields?.hasColorVariant ?? false) && !isVariantMatrix;

    final initialQtyController = notifier.controllers['initialQty']!;
    final serviceDurationController = notifier.controllers['serviceDuration']!;
    final staffCommissionController = notifier.controllers['staffCommission']!;
    final batchNumberController = notifier.controllers['batchNumber']!;
    final serialNumberController = notifier.controllers['serialNumber']!;
    final imeiController = notifier.controllers['imei']!;
    final warrantyController = notifier.controllers['warranty']!;
    final scheduleController = notifier.controllers['schedule']!;
    final isbnController = notifier.controllers['isbn']!;
    final recipeController = notifier.controllers['recipe']!;
    final nameController = notifier.controllers['name']!;
    final priceController = notifier.controllers['price']!;
    final packagingUnitController = notifier.controllers['packagingUnit']!;
    final conversionFactorController = notifier.controllers['conversionFactor']!;

    // Pack/wholesale unit applies only to physical stock items whose category
    // opts into it (e.g. a pharmacy strip of tablets, a carton of bottles).
    final showPackaging = (fields?.hasPackagingUnit ?? false) && !state.isService;

    return SingleChildScrollView(
      key: const ValueKey(3),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
                    'Stock & Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Configure service timing or set starting stock and custom attributes',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.isService) ...[
            _buildBigCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SERVICE CONFIG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppTheme.slate500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: serviceDurationController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: AppTheme.premiumDecoration(
                      label: 'Service Duration',
                      hint: 'e.g. 30',
                      prefixIcon: const Icon(CupertinoIcons.timer, color: AppTheme.primaryColor),
                      suffixIcon: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('mins', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.slate400, fontSize: 14)),
                      ),
                    ),
                    onChanged: (value) => notifier.updateInventoryField('serviceDuration', value),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: staffCommissionController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: AppTheme.premiumDecoration(
                      label: 'Staff Commission (Optional)',
                      hint: 'e.g. 10',
                      prefixIcon: const Icon(CupertinoIcons.percent, color: AppTheme.primaryColor),
                      suffixIcon: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('%', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.slate400, fontSize: 14)),
                      ),
                    ),
                    onChanged: (value) => notifier.updateInventoryField('staffCommission', value),
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildBigCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STOCK QUANTITY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppTheme.slate500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!state.isLoose)
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
                      const SizedBox(width: 16),
                      Container(
                        width: state.isLoose ? 160 : 100,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.slate50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.slate200, width: 1.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: TextField(
                          controller: initialQtyController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.numberWithOptions(decimal: state.isLoose),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                          decoration: const InputDecoration(border: InputBorder.none),
                          onChanged: (value) => notifier.updateInventoryField('initialQty', value),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (!state.isLoose)
                        _roundBtn(
                          icon: CupertinoIcons.plus,
                          onPressed: () {
                            final val = double.tryParse(initialQtyController.text) ?? 0;
                            initialQtyController.text = (val + 1).toStringAsFixed(0);
                            notifier.updateInventoryField('initialQty', initialQtyController.text);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Unit: ${state.selectedUnit}',
                      style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            if (showPackaging) ...[
              const SizedBox(height: 16),
              _buildBigCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PACK / WHOLESALE UNIT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: AppTheme.slate500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Define the bigger pack you buy/sell in — e.g. a Strip of tablets, a Box of bottles. Set how many ${state.selectedUnit} are inside one pack.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.slate500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: packagingUnitController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: AppTheme.premiumDecoration(
                        label: 'Pack Name',
                        hint: 'e.g. Strip, Box, Carton',
                        prefixIcon: const Icon(CupertinoIcons.cube_box, color: AppTheme.primaryColor),
                      ),
                      onChanged: (value) => notifier.updateInventoryField('packagingUnit', value),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: conversionFactorController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: AppTheme.premiumDecoration(
                        label: 'Units per Pack',
                        hint: 'e.g. 10',
                        prefixIcon: const Icon(CupertinoIcons.number, color: AppTheme.primaryColor),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            state.selectedUnit,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.slate400, fontSize: 14),
                          ),
                        ),
                      ),
                      onChanged: (value) => notifier.updateInventoryField('conversionFactor', value),
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (_) {
                        final factor = double.tryParse(conversionFactorController.text) ?? 0;
                        final packName = packagingUnitController.text.trim().isEmpty
                            ? 'pack'
                            : packagingUnitController.text.trim();
                        if (factor <= 0) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '1 $packName = ${factor.toStringAsFixed(factor.truncateToDouble() == factor ? 0 : 2)} ${state.selectedUnit}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            if (showColor) ...[
              const SizedBox(height: 16),
              _buildBigCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRODUCT COLOR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: AppTheme.slate500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap a color below to select it instantly, or type a custom one:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.slate500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _presetColors.entries.map((entry) {
                        final colorName = entry.key;
                        final colorVal = entry.value;
                        final isSelected = state.color?.toLowerCase() == colorName.toLowerCase();
                        
                        return GestureDetector(
                          onTap: () {
                            notifier.updateInfoField('color', colorName);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colorVal,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected 
                                    ? AppTheme.accentColor 
                                    : (colorVal == Colors.white ? AppTheme.slate300 : Colors.transparent),
                                width: isSelected ? 3 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isSelected ? 0.15 : 0.05),
                                  blurRadius: isSelected ? 8 : 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: colorVal == Colors.white || colorName == 'Yellow'
                                        ? Colors.black
                                        : Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notifier.controllers['color']!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: AppTheme.premiumDecoration(
                        label: 'Custom Color',
                        hint: 'e.g. Royal Blue, Striped Red',
                        prefixIcon: const Icon(CupertinoIcons.color_filter, color: AppTheme.primaryColor),
                      ),
                      onChanged: (value) => notifier.updateInfoField('color', value),
                    ),
                  ],
                ),
              ),
            ],
            if (showSize) ...[
              const SizedBox(height: 16),
              _buildBigCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRODUCT SIZE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: AppTheme.slate500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap a standard size pill or type your own custom size below:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.slate500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presetSizes.map((sizeName) {
                        final isSelected = state.size?.toLowerCase() == sizeName.toLowerCase();
                        
                        return GestureDetector(
                          onTap: () {
                            notifier.updateInfoField('size', sizeName);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.accentColor : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.accentColor : AppTheme.slate200,
                                width: 1.5,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: AppTheme.accentColor.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                              ],
                            ),
                            child: Text(
                              sizeName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notifier.controllers['size']!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: AppTheme.premiumDecoration(
                        label: 'Custom Size',
                        hint: 'e.g. Free Size, 32 Waist, 12 Years',
                        prefixIcon: const Icon(CupertinoIcons.resize, color: AppTheme.primaryColor),
                      ),
                      onChanged: (value) => notifier.updateInfoField('size', value),
                    ),
                  ],
                ),
              ),
            ],
            if ((state.selectedCategory?.productFields.hasExpiryDate ?? false)) ...[
              const SizedBox(height: 24),
              _buildBigCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: state.expiryDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      notifier.setExpiryDate(picked);
                    }
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.calendar, color: AppTheme.errorColor),
                  ),
                  title: const Text('Expiry Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text(
                    state.expiryDate == null ? 'Not set (Optional)' : DateFormat('dd MMM yyyy').format(state.expiryDate!),
                    style: TextStyle(
                      color: state.expiryDate == null ? AppTheme.slate400 : AppTheme.errorColor,
                      fontWeight: state.expiryDate == null ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: AppTheme.slate400),
                ),
              ),
            ],
            if ((state.selectedCategory?.productFields.hasBatchNumber ?? false)) ...[
              const SizedBox(height: 16),
              _buildBigCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BATCH INFO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.slate500)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: batchNumberController,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: AppTheme.premiumDecoration(
                        label: 'Batch Number',
                        hint: 'e.g. BT2024-001',
                        prefixIcon: const Icon(CupertinoIcons.number, color: AppTheme.primaryColor),
                      ),
                      onChanged: (value) => notifier.updateInfoField('batchNumber', value),
                    ),
                  ],
                ),
              ),
            ],
            if ((state.selectedCategory?.productFields.hasSerialNumber ?? false)) ...[
              const SizedBox(height: 16),
              _buildBigCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SERIAL INFO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.slate500)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: serialNumberController,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: AppTheme.premiumDecoration(
                        label: 'Serial Number',
                        hint: 'e.g. SN123456789',
                        prefixIcon: const Icon(CupertinoIcons.tag, color: AppTheme.primaryColor),
                      ),
                      onChanged: (value) => notifier.updateInfoField('serialNumber', value),
                    ),
                  ],
                ),
              ),
            ],
            if ((state.selectedCategory?.productFields.hasImei ?? false)) ...[
              const SizedBox(height: 16),
              _buildBigCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DEVICE IMEI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.slate500)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: imeiController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: AppTheme.premiumDecoration(
                        label: 'IMEI Number (15 digits)',
                        hint: 'Enter device IMEI',
                        prefixIcon: const Icon(CupertinoIcons.device_phone_portrait, color: AppTheme.primaryColor),
                      ),
                      onChanged: (value) => notifier.updateInfoField('imei', value),
                    ),
                  ],
                ),
              ),
            ],
            if ((state.selectedCategory?.productFields.hasWarranty ?? false)) ...[
              const SizedBox(height: 16),
              _buildBigCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('WARRANTY DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.slate500)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: warrantyController,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: AppTheme.premiumDecoration(
                        label: 'Warranty Period',
                        hint: 'e.g. 1 Year, 6 Months',
                        prefixIcon: const Icon(CupertinoIcons.shield, color: AppTheme.primaryColor),
                      ),
                      onChanged: (value) => notifier.updateInfoField('warranty', value),
                    ),
                  ],
                ),
              ),
            ],
            if ((state.selectedCategory?.productFields.hasSchedule ?? false)) ...[
              const SizedBox(height: 16),
              _buildBigCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DRUG SCHEDULE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.slate500)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: scheduleController.text.isEmpty ? null : scheduleController.text,
                      decoration: AppTheme.premiumDecoration(
                        label: 'Drug Schedule',
                        hint: 'Not scheduled (OTC)',
                        prefixIcon: const Icon(CupertinoIcons.exclamationmark_triangle, color: AppTheme.primaryColor),
                      ),
                      hint: const Text('Not scheduled (OTC)', style: TextStyle(fontSize: 14, color: AppTheme.slate500)),
                      items: const [
                        DropdownMenuItem(value: 'H', child: Text('Schedule H — Prescription Only', style: TextStyle(fontSize: 14))),
                        DropdownMenuItem(value: 'H1', child: Text('Schedule H1 — Dangerous Drug', style: TextStyle(fontSize: 14))),
                        DropdownMenuItem(value: 'X', child: Text('Schedule X — Narcotic/Psychotropic', style: TextStyle(fontSize: 14))),
                      ],
                      onChanged: (v) {
                        scheduleController.text = v ?? '';
                        notifier.updateInfoField('schedule', v ?? '');
                      },
                    ),
                  ],
                ),
              ),
            ],
            if ((state.selectedCategory?.productFields.hasIsbn ?? false)) ...[
              const SizedBox(height: 16),
              _buildBigCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BOOK ISBN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.slate500)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: isbnController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: AppTheme.premiumDecoration(
                        label: 'Book Code (ISBN)',
                        hint: '13-digit ISBN',
                        prefixIcon: const Icon(CupertinoIcons.book, color: AppTheme.primaryColor),
                      ),
                      onChanged: (value) => notifier.updateInfoField('isbn', value),
                    ),
                  ],
                ),
              ),
            ],
            if ((state.selectedCategory?.productFields.hasRecipe ?? false)) ...[
              const SizedBox(height: 16),
              _buildBigCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('INGREDIENTS / RECIPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.slate500)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: recipeController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: AppTheme.premiumDecoration(
                        label: 'Recipe or Ingredients',
                        hint: 'e.g. Wheat, Sugar, Salt...',
                        prefixIcon: const Icon(CupertinoIcons.list_bullet, color: AppTheme.primaryColor),
                      ),
                      onChanged: (value) => notifier.updateInfoField('recipe', value),
                    ),
                  ],
                ),
              ),
            ],
          ],
          if (showToggles && (!state.isService || !state.isLoose)) ...[
            const SizedBox(height: 32),
          ],
          if (showToggles && !state.isService) ...[
            _toggleTile(
              title: 'Service (No Stock)',
              subtitle: 'Turn ON for repairs, haircut, labor — stock will not go down on sale',
              value: state.isService,
              onChanged: (v) => notifier.setIsService(v),
              icon: Icons.design_services_outlined,
            ),
            const SizedBox(height: 12),
          ],
          if (showToggles && !state.isLoose) ...[
            _toggleTile(
              title: 'Sell by Weight / Measure',
              subtitle: 'Turn ON if you sell in grams, kg, ml, litre — e.g. rice, oil, cloth',
              value: state.isLoose,
              onChanged: (v) => notifier.setIsLoose(v),
              icon: Icons.scale_outlined,
            ),
          ],
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('SUMMARY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppTheme.textSecondary, letterSpacing: 1.5)),
          ),
          const SizedBox(height: 12),
          _buildBigCard(
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
                      Text(nameController.text.isEmpty ? 'New Item' : nameController.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.5)),
                      Text('Selling at ₹${priceController.text}', style: const TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.w800, fontSize: 16)),
                      if ((state.size != null && state.size!.isNotEmpty) || (state.color != null && state.color!.isNotEmpty)) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (state.size != null && state.size!.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.slate100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('Size: ${state.size}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate600)),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (state.color != null && state.color!.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.slate100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('Color: ${state.color}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate600)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
