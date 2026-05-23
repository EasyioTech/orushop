import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:orushops/features/inventory/controllers/product_form_notifier.dart';
import 'package:orushops/features/inventory/models/product_form_state.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/features/inventory/screens/create_product/components/product_creation_scanner_modal.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';
import 'package:orushops/providers/shop_provider.dart';

/// Step 2 — Product Details & Specifications
/// Contains: cost price, SKU/barcode, MRP/wholesale/tax, category specs,
/// isLoose toggle, unit selector, packaging unit.
class DetailsStep extends ConsumerStatefulWidget {
  final VoidCallback? onSave;
  const DetailsStep({super.key, this.onSave});

  @override
  ConsumerState<DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends ConsumerState<DetailsStep> {
  late final FocusNode _costFocusNode;
  late final FocusNode _skuFocusNode;
  late final FocusNode _batchFocusNode;
  late final FocusNode _warrantyFocusNode;
  late final FocusNode _imeiFocusNode;
  late final FocusNode _recipeFocusNode;
  late final FocusNode _isbnFocusNode;
  late final FocusNode _weightFocusNode;
  late final FocusNode _sizeFocusNode;
  late final FocusNode _colorFocusNode;
  late final FocusNode _wholesaleFocusNode;
  late final FocusNode _taxFocusNode;
  late final FocusNode _packagingFocusNode;
  late final FocusNode _conversionFocusNode;
  late final FocusNode _mrpFocusNode;

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
  void initState() {
    super.initState();
    _costFocusNode = FocusNode();
    _skuFocusNode = FocusNode();
    _batchFocusNode = FocusNode();
    _warrantyFocusNode = FocusNode();
    _imeiFocusNode = FocusNode();
    _recipeFocusNode = FocusNode();
    _isbnFocusNode = FocusNode();
    _weightFocusNode = FocusNode();
    _sizeFocusNode = FocusNode();
    _colorFocusNode = FocusNode();
    _wholesaleFocusNode = FocusNode();
    _taxFocusNode = FocusNode();
    _packagingFocusNode = FocusNode();
    _conversionFocusNode = FocusNode();
    _mrpFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _costFocusNode.dispose();
    _skuFocusNode.dispose();
    _batchFocusNode.dispose();
    _warrantyFocusNode.dispose();
    _imeiFocusNode.dispose();
    _recipeFocusNode.dispose();
    _isbnFocusNode.dispose();
    _weightFocusNode.dispose();
    _sizeFocusNode.dispose();
    _colorFocusNode.dispose();
    _wholesaleFocusNode.dispose();
    _taxFocusNode.dispose();
    _packagingFocusNode.dispose();
    _conversionFocusNode.dispose();
    _mrpFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(productFormNotifierProvider.notifier);
    final state = ref.watch(productFormNotifierProvider);

    final costController = notifier.controllers['costPrice']!;
    final skuController = notifier.controllers['sku']!;
    final fields = state.selectedCategory?.productFields;
    final showPackaging = (fields?.hasPackagingUnit ?? false) && !state.isService;

    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buying cost + SKU
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('BUYING DETAILS', AppTheme.errorColor),
                const SizedBox(height: 16),

                TextField(
                  controller: costController,
                  focusNode: _costFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  style: _inputStyle,
                  decoration: AppTheme.premiumDecoration(
                    label: 'Buying Cost (optional)',
                    hint: 'How much you paid to get this item',
                    prefixIcon: const Icon(CupertinoIcons.bag_fill, color: AppTheme.errorColor),
                    prefixText: '₹ ',
                    activeColor: AppTheme.errorColor,
                  ),
                  onChanged: (v) => notifier.updatePricingField('costPrice', v),
                  onSubmitted: (_) => state.isService ? null : _skuFocusNode.requestFocus(),
                ),

                if (!state.isService) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: skuController,
                    focusNode: _skuFocusNode,
                    style: _inputStyle,
                    decoration: AppTheme.premiumDecoration(
                      label: 'Barcode / SKU (optional)',
                      hint: 'Enter manual barcode or scan',
                      prefixIcon: const Icon(CupertinoIcons.barcode, color: AppTheme.primaryColor),
                      suffixIcon: IconButton(
                        icon: const Icon(CupertinoIcons.barcode_viewfinder, color: AppTheme.accentColor),
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          final String? scanned = await showModalBottomSheet<String>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const ProductCreationScannerModal(),
                          );
                          if (scanned != null && scanned.isNotEmpty) {
                            notifier.applyScannedBarcode(scanned);
                          }
                        },
                      ),
                    ),
                    onSubmitted: (_) => _batchFocusNode.requestFocus(),
                  ),
                ],
              ],
            ),
          ),

          // Category specs (expiry, batch, warranty, IMEI, recipe, ISBN, weight, size, color, schedule)
          _buildCategorySpecsCard(state, notifier),

          // isLoose toggle
          _buildTogglesSection(state, notifier),

          // Unit selector + packaging
          _buildUnitAndPackagingCard(state, notifier, showPackaging),

          // Extra pricing (MRP, wholesale, tax) — always visible in step 2
          _buildPricingCard(state, notifier),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Category specs ──────────────────────────────────────────────────────────

  Widget _buildCategorySpecsCard(ProductFormState state, ProductFormNotifier notifier) {
    final category = state.selectedCategory;
    if (category == null) return const SizedBox.shrink();

    final fields = category.productFields;
    final batchCtrl = notifier.controllers['batchNumber']!;
    final imeiCtrl = notifier.controllers['imei']!;
    final warrantyCtrl = notifier.controllers['warranty']!;
    final recipeCtrl = notifier.controllers['recipe']!;
    final isbnCtrl = notifier.controllers['isbn']!;
    final weightCtrl = notifier.controllers['weight']!;
    final sizeCtrl = notifier.controllers['size']!;
    final colorCtrl = notifier.controllers['color']!;
    final scheduleCtrl = notifier.controllers['schedule']!;

    final List<Widget> items = [];

    if (fields.hasExpiryDate) {
      items.add(_expiryTile(state, notifier));
    }

    if (fields.hasBatchNumber) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 16));
      items.add(TextField(
        controller: batchCtrl,
        focusNode: _batchFocusNode,
        textInputAction: TextInputAction.next,
        style: _inputStyle,
        decoration: AppTheme.premiumDecoration(
          label: 'Batch Number',
          hint: 'e.g. BT2024-001',
          prefixIcon: const Icon(CupertinoIcons.number, color: AppTheme.primaryColor),
        ),
        onChanged: (v) => notifier.updateInfoField('batchNumber', v),
        onSubmitted: (_) => _warrantyFocusNode.requestFocus(),
      ));
    }

    if (fields.hasWarranty) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 16));
      items.add(TextField(
        controller: warrantyCtrl,
        focusNode: _warrantyFocusNode,
        textInputAction: TextInputAction.next,
        style: _inputStyle,
        decoration: AppTheme.premiumDecoration(
          label: 'Warranty Period',
          hint: 'e.g. 1 Year, 6 Months',
          prefixIcon: const Icon(CupertinoIcons.shield, color: AppTheme.primaryColor),
        ),
        onChanged: (v) => notifier.updateInfoField('warranty', v),
        onSubmitted: (_) => _imeiFocusNode.requestFocus(),
      ));
    }

    if (fields.hasImei) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 16));
      items.add(TextField(
        controller: imeiCtrl,
        focusNode: _imeiFocusNode,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        style: _inputStyle,
        decoration: AppTheme.premiumDecoration(
          label: 'IMEI Number (15 digits)',
          hint: 'Enter device IMEI',
          prefixIcon: const Icon(CupertinoIcons.device_phone_portrait, color: AppTheme.primaryColor),
        ),
        onChanged: (v) => notifier.updateInfoField('imei', v),
      ));
    }

    if (fields.hasRecipe) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 16));
      items.add(TextField(
        controller: recipeCtrl,
        focusNode: _recipeFocusNode,
        maxLines: 3,
        textInputAction: TextInputAction.next,
        style: _inputStyle,
        decoration: AppTheme.premiumDecoration(
          label: 'Recipe or Ingredients',
          hint: 'e.g. Wheat, Sugar, Salt...',
          prefixIcon: const Icon(CupertinoIcons.list_bullet, color: AppTheme.primaryColor),
        ),
        onChanged: (v) => notifier.updateInfoField('recipe', v),
      ));
    }

    final subcategory = state.selectedSubcategory?.toLowerCase() ?? '';
    final isBook = category.name.toLowerCase().contains('book') || subcategory.contains('book') || fields.hasIsbn;
    if (isBook) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 16));
      items.add(TextField(
        controller: isbnCtrl,
        focusNode: _isbnFocusNode,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        style: _inputStyle,
        decoration: AppTheme.premiumDecoration(
          label: 'Book Code (ISBN)',
          hint: '13-digit ISBN',
          prefixIcon: const Icon(CupertinoIcons.book, color: AppTheme.primaryColor),
        ),
        onChanged: (v) => notifier.updateInfoField('isbn', v),
      ));
    }

    if (fields.hasWeight) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 16));
      items.add(TextField(
        controller: weightCtrl,
        focusNode: _weightFocusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        style: _inputStyle,
        decoration: AppTheme.premiumDecoration(
          label: 'Weight (optional)',
          hint: 'e.g. 500, 1.5',
          prefixIcon: const Icon(CupertinoIcons.gauge, color: AppTheme.primaryColor),
          suffixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text('g/kg', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.slate400, fontSize: 14)),
          ),
        ),
        onChanged: (v) => notifier.updateInfoField('weight', v),
      ));
    }

    final isVariantMatrix = fields.template == ProductTemplate.variantMatrix;

    if (fields.hasSizeVariant && !isVariantMatrix) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 16));
      items.add(_sizeSelector(state, notifier, sizeCtrl));
    }

    if (fields.hasColorVariant && !isVariantMatrix) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 16));
      items.add(_colorSelector(state, notifier, colorCtrl));
    }

    if (fields.hasSchedule) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 16));
      items.add(DropdownButtonFormField<String>(
        initialValue: scheduleCtrl.text.isEmpty ? null : scheduleCtrl.text,
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
          scheduleCtrl.text = v ?? '';
          notifier.updateInfoField('schedule', v ?? '');
        },
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 16),
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('CATEGORY SPECIFICATIONS', AppTheme.slate500),
              const SizedBox(height: 16),
              ...items,
            ],
          ),
        ),
      ],
    );
  }

  Widget _expiryTile(ProductFormState state, ProductFormNotifier notifier) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: state.expiryDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
        );
        if (picked != null) notifier.setExpiryDate(picked);
      },
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.errorColor.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: const Icon(CupertinoIcons.calendar, color: AppTheme.errorColor),
      ),
      title: const Text('Expiry Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(
        state.expiryDate == null ? 'Not set (Required)' : DateFormat('dd MMM yyyy').format(state.expiryDate!),
        style: TextStyle(
          color: state.expiryDate == null ? AppTheme.slate400 : AppTheme.errorColor,
          fontWeight: state.expiryDate == null ? FontWeight.normal : FontWeight.w600,
        ),
      ),
      trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: AppTheme.slate400),
    );
  }

  Widget _sizeSelector(ProductFormState state, ProductFormNotifier notifier, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('SELECT STANDARD SIZE', AppTheme.slate500),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetSizes.map((s) {
            final isSelected = state.size?.toLowerCase() == s.toLowerCase();
            return GestureDetector(
              onTap: () {
                notifier.updateInfoField('size', s);
                HapticFeedback.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accentColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? AppTheme.accentColor : AppTheme.slate200, width: 1.5),
                  boxShadow: [if (isSelected) BoxShadow(color: AppTheme.accentColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Text(s, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : AppTheme.textSecondary)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl,
          focusNode: _sizeFocusNode,
          textInputAction: TextInputAction.next,
          style: _inputStyle,
          decoration: AppTheme.premiumDecoration(
            label: 'Custom Size',
            hint: 'e.g. Free Size, 32 Waist',
            prefixIcon: const Icon(CupertinoIcons.resize, color: AppTheme.primaryColor),
          ),
          onChanged: (v) => notifier.updateInfoField('size', v),
          onSubmitted: (_) => _colorFocusNode.requestFocus(),
        ),
      ],
    );
  }

  Widget _colorSelector(ProductFormState state, ProductFormNotifier notifier, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('SELECT PRESET COLOR', AppTheme.slate500),
        const SizedBox(height: 8),
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
                HapticFeedback.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorVal,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTheme.accentColor : (colorVal == Colors.white ? AppTheme.slate300 : Colors.transparent),
                    width: isSelected ? 3 : 1.5,
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isSelected ? 0.15 : 0.05), blurRadius: isSelected ? 8 : 4, offset: const Offset(0, 2))],
                ),
                child: isSelected
                    ? Icon(Icons.check, color: colorVal == Colors.white || colorName == 'Yellow' ? Colors.black : Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl,
          focusNode: _colorFocusNode,
          textInputAction: TextInputAction.next,
          style: _inputStyle,
          decoration: AppTheme.premiumDecoration(
            label: 'Custom Color',
            hint: 'e.g. Royal Blue, Striped Red',
            prefixIcon: const Icon(CupertinoIcons.color_filter, color: AppTheme.primaryColor),
          ),
          onChanged: (v) => notifier.updateInfoField('color', v),
        ),
      ],
    );
  }

  // ─── Toggles ─────────────────────────────────────────────────────────────────

  Widget _buildTogglesSection(ProductFormState state, ProductFormNotifier notifier) {
    final shopType = ref.watch(shopTypeProvider);
    final config = ShopTypeConfig.getConfig(shopType);
    if (config.minimalFieldsMode || state.isService) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 16),
        _toggleTile(
          title: state.isLoose ? 'Selling by Weight / Measure' : 'Sell by Weight / Measure?',
          subtitle: state.isLoose
              ? 'ON — stock tracked in fractions (e.g. 0.5 kg, 250 g). Tap to turn off.'
              : 'Turn ON for rice, oil, cloth, dal — items sold in kg, gram, litre, metre',
          value: state.isLoose,
          onChanged: (v) {
            notifier.setIsLoose(v);
            HapticFeedback.lightImpact();
          },
          icon: Icons.scale_outlined,
        ),
      ],
    );
  }

  // ─── Unit selector + packaging ───────────────────────────────────────────────

  Widget _buildUnitAndPackagingCard(ProductFormState state, ProductFormNotifier notifier, bool showPackaging) {
    if (state.selectedCategory == null || state.isService) return const SizedBox.shrink();

    final fields = state.selectedCategory?.productFields;
    final options = fields?.unitOptions ?? ['Piece'];
    final packagingCtrl = notifier.controllers['packagingUnit']!;
    final conversionCtrl = notifier.controllers['conversionFactor']!;

    String unitHint(String unit) {
      switch (unit) {
        case 'Tablet': return 'e.g. 10 Tablets per Strip';
        case 'Capsule': return 'e.g. capsule counted one by one';
        case 'Bottle': return 'each bottle as one unit';
        case 'Kg': case 'Gram': case 'Litre': case 'ML': return 'sold by weight/volume';
        case 'Piece': return 'counted one by one';
        case 'Metre': return 'sold by length';
        default: return '';
      }
    }

    String packHint(String unit) {
      switch (unit) {
        case 'Tablet': case 'Capsule': return 'e.g. Strip, Blister, Box';
        case 'Bottle': return 'e.g. Box, Carton, Crate';
        case 'Piece': return 'e.g. Box, Pack, Carton, Dozen';
        case 'Kg': case 'Gram': return 'e.g. Bag, Sack, Box';
        case 'Litre': case 'ML': return 'e.g. Crate, Box, Carton';
        case 'Metre': return 'e.g. Roll, Bundle';
        default: return 'e.g. Box, Pack, Carton';
      }
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.straighten_rounded, color: AppTheme.primaryColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WHAT UNIT DO YOU SELL IN?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: AppTheme.primaryColor)),
                        Text('This tells the app how to count your stock', style: TextStyle(fontSize: 11, color: AppTheme.slate500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((unit) {
                  final isSelected = state.selectedUnit == unit;
                  return GestureDetector(
                    onTap: () {
                      notifier.onUnitChanged(unit);
                      HapticFeedback.lightImpact();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.slate200, width: 1.5),
                        boxShadow: [if (isSelected) BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Text(unit, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : AppTheme.textSecondary)),
                    ),
                  );
                }).toList(),
              ),

              if (unitHint(state.selectedUnit).isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(CupertinoIcons.info_circle, size: 13, color: AppTheme.slate400),
                    const SizedBox(width: 4),
                    Text(unitHint(state.selectedUnit), style: const TextStyle(fontSize: 12, color: AppTheme.slate500)),
                  ],
                ),
              ],

              if (showPackaging) ...[
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppTheme.slate100),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(CupertinoIcons.cube_box, color: AppTheme.accentColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HOW DO YOU BUY IT? (PACK SIZE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: AppTheme.accentColor)),
                          Text('Optional — e.g. you buy a Strip of 10 Tablets', style: TextStyle(fontSize: 11, color: AppTheme.slate500)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: packagingCtrl,
                  focusNode: _packagingFocusNode,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: AppTheme.premiumDecoration(
                    label: 'Pack Name (what you call it)',
                    hint: packHint(state.selectedUnit),
                    prefixIcon: const Icon(CupertinoIcons.tag, color: AppTheme.accentColor),
                  ),
                  onChanged: (v) => notifier.updateInventoryField('packagingUnit', v),
                  onSubmitted: (_) => _conversionFocusNode.requestFocus(),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: conversionCtrl,
                  focusNode: _conversionFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: AppTheme.premiumDecoration(
                    label: 'How many ${state.selectedUnit}s in one pack?',
                    hint: 'e.g. 10  (default: 1)',
                    prefixIcon: const Icon(CupertinoIcons.number, color: AppTheme.accentColor),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Text(state.selectedUnit, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentColor, fontSize: 13)),
                    ),
                  ),
                  onChanged: (v) => notifier.updateInventoryField('conversionFactor', v),
                ),

                Builder(builder: (_) {
                  final factor = double.tryParse(conversionCtrl.text) ?? 0;
                  final packName = packagingCtrl.text.trim().isEmpty ? 'pack' : packagingCtrl.text.trim();
                  if (factor <= 0) return const SizedBox.shrink();
                  final factorStr = factor.truncateToDouble() == factor ? factor.toInt().toString() : factor.toStringAsFixed(2);
                  return Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.checkmark_circle_fill, size: 15, color: AppTheme.accentColor),
                        const SizedBox(width: 8),
                        Text('1 $packName  =  $factorStr ${state.selectedUnit}s', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.accentColor)),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─── Pricing (MRP, wholesale, tax) ───────────────────────────────────────────

  Widget _buildPricingCard(ProductFormState state, ProductFormNotifier notifier) {
    final fields = state.selectedCategory?.productFields;
    final hasMrp = fields?.hasMrp ?? true;
    final hasTax = fields?.hasTaxRate ?? false;
    final mrpCtrl = notifier.controllers['mrp']!;
    final wholesaleCtrl = notifier.controllers['wholesalePrice']!;
    final taxCtrl = notifier.controllers['tax']!;

    final List<Widget> items = [];

    if (!state.isService && hasMrp) {
      items.add(TextField(
        controller: mrpCtrl,
        focusNode: _mrpFocusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        style: _inputStyle,
        decoration: AppTheme.premiumDecoration(
          label: 'Printed Price on Pack (MRP, optional)',
          hint: 'Highest price printed on packet',
          prefixIcon: const Icon(CupertinoIcons.shield_fill, color: AppTheme.primaryColor),
          prefixText: '₹ ',
        ),
        onChanged: (v) => notifier.updatePricingField('mrp', v),
        onSubmitted: (_) => _wholesaleFocusNode.requestFocus(),
      ));
    }

    if (state.isLoose) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 16));
      items.add(TextField(
        controller: wholesaleCtrl,
        focusNode: _wholesaleFocusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        style: _inputStyle,
        decoration: AppTheme.premiumDecoration(
          label: 'Bulk Price (Wholesale, optional)',
          hint: 'Special lower price for bulk buyers',
          prefixIcon: const Icon(CupertinoIcons.square_grid_3x2_fill, color: Color(0xFFFF9500)),
          prefixText: '₹ ',
          activeColor: const Color(0xFFFF9500),
        ),
        onChanged: (v) => notifier.updatePricingField('wholesalePrice', v),
        onSubmitted: (_) => _taxFocusNode.requestFocus(),
      ));
    }

    if (hasTax) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 16));
      items.add(TextField(
        controller: taxCtrl,
        focusNode: _taxFocusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        style: _inputStyle,
        decoration: AppTheme.premiumDecoration(
          label: 'Tax / GST (%)',
          hint: state.taxRate > 0 ? 'Default: ${state.taxRate.toStringAsFixed(0)}%' : '0% (exempt) — tap to change',
          prefixIcon: const Icon(CupertinoIcons.percent, color: AppTheme.primaryColor),
          suffixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text('%', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.slate400, fontSize: 16)),
          ),
        ),
        onChanged: (v) => notifier.updatePricingField('tax', v),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 16),
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('PRICING DETAILS (OPTIONAL)', AppTheme.slate500),
              const SizedBox(height: 16),
              ...items,
            ],
          ),
        ),
      ],
    );
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────────

  static const TextStyle _inputStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary);

  Widget _sectionLabel(String label, Color color) => Text(
    label,
    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: color),
  );

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _toggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    final borderColor = value ? AppTheme.accentColor.withValues(alpha: 0.4) : AppTheme.slate200;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Icon(icon, color: value ? AppTheme.accentColor : AppTheme.slate400, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.slate600)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.accentColor,
      ),
    );
  }
}
