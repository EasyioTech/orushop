import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/features/inventory/controllers/product_form_notifier.dart';
import 'package:orushops/core/theme/app_theme.dart';

class VariantsStep extends ConsumerStatefulWidget {
  const VariantsStep({super.key});

  @override
  ConsumerState<VariantsStep> createState() => _VariantsStepState();
}

class _VariantsStepState extends ConsumerState<VariantsStep> {
  // Maps to store controllers for variant fields
  final Map<String, TextEditingController> priceControllers = {};
  final Map<String, TextEditingController> mrpControllers = {};
  final Map<String, TextEditingController> stockControllers = {};
  final Map<String, TextEditingController> barcodeControllers = {};
  final Map<String, TextEditingController> skuControllers = {};

  // Local text controllers for size and color input
  late final TextEditingController sizeInputController;
  late final TextEditingController colorInputController;

  @override
  void initState() {
    super.initState();
    sizeInputController = TextEditingController();
    colorInputController = TextEditingController();
  }

  @override
  void dispose() {
    sizeInputController.dispose();
    colorInputController.dispose();
    for (final ctrl in priceControllers.values) {
      ctrl.dispose();
    }
    for (final ctrl in mrpControllers.values) {
      ctrl.dispose();
    }
    for (final ctrl in stockControllers.values) {
      ctrl.dispose();
    }
    for (final ctrl in barcodeControllers.values) {
      ctrl.dispose();
    }
    for (final ctrl in skuControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(
    String key,
    Map<String, TextEditingController> controllers,
    String initialValue,
  ) {
    if (!controllers.containsKey(key)) {
      controllers[key] = TextEditingController(text: initialValue);
    } else {
      controllers[key]!.text = initialValue;
    }
    return controllers[key]!;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(productFormNotifierProvider.notifier);
    final state = ref.watch(productFormNotifierProvider);

    void addSize() {
      final v = sizeInputController.text.trim();
      if (v.isNotEmpty && !state.variantSizes.contains(v)) {
        notifier.addVariantSize(v);
        sizeInputController.clear();
      }
    }

    void addColor() {
      final v = colorInputController.text.trim();
      if (v.isNotEmpty && !state.variantColors.contains(v)) {
        notifier.addVariantColor(v);
        colorInputController.clear();
      }
    }

    // Build variant combinations
    final combos = <(String, String)>[];
    if (state.variantSizes.isEmpty && state.variantColors.isNotEmpty) {
      for (final c in state.variantColors) {
        combos.add(('', c));
      }
    } else if (state.variantColors.isEmpty && state.variantSizes.isNotEmpty) {
      for (final s in state.variantSizes) {
        combos.add((s, ''));
      }
    } else if (state.variantSizes.isNotEmpty && state.variantColors.isNotEmpty) {
      for (final s in state.variantSizes) {
        for (final c in state.variantColors) {
          combos.add((s, c));
        }
      }
    }

    return SingleChildScrollView(
      key: const ValueKey(4),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBigCard(
            child: _buildChipInput(
              label: 'Sizes',
              items: state.variantSizes,
              controller: sizeInputController,
              onAdd: addSize,
              onRemove: (s) => notifier.removeVariantSize(s),
            ),
          ),
          const SizedBox(height: 16),
          _buildBigCard(
            child: _buildChipInput(
              label: 'Colors',
              items: state.variantColors,
              controller: colorInputController,
              onAdd: addColor,
              onRemove: (c) => notifier.removeVariantColor(c),
            ),
          ),
          if (combos.isEmpty) ...[
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Add sizes or colors above\nto build your variant grid.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.slate400, fontSize: 15),
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'VARIANT GRID',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...combos.map((combo) {
              final (size, color) = combo;
              final key = '$size|$color';
              final ov = state.variantOverrides[key];

              final label = [size, color].where((s) => s.isNotEmpty).join(' / ');

              // Get or create controllers for this variant
              final priceCtrl = _getController(key, priceControllers, ov?.price.text ?? '');
              final mrpCtrl = _getController(key, mrpControllers, ov?.mrp.text ?? '');
              final stockCtrl = _getController(key, stockControllers, ov?.stock.text ?? '');
              final barcodeCtrl = _getController(key, barcodeControllers, ov?.barcode.text ?? '');
              final skuCtrl = _getController(key, skuControllers, ov?.sku.text ?? '');

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildBigCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Price ₹', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                TextField(
                                  controller: priceCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: UnderlineInputBorder(),
                                    hintText: '0',
                                  ),
                                  onChanged: (value) => notifier.updateVariantOverride(key, price: value),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('MRP ₹', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                TextField(
                                  controller: mrpCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: UnderlineInputBorder(),
                                    hintText: '0',
                                  ),
                                  onChanged: (value) => notifier.updateVariantOverride(key, mrp: value),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Stock', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                TextField(
                                  controller: stockCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: UnderlineInputBorder(),
                                    hintText: '0',
                                  ),
                                  onChanged: (value) => notifier.updateVariantOverride(key, stock: value),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Barcode', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                TextField(
                                  controller: barcodeCtrl,
                                  decoration: const InputDecoration(
                                    border: UnderlineInputBorder(),
                                    hintText: 'Scan/Type',
                                  ),
                                  onChanged: (value) => notifier.updateVariantOverride(key, barcode: value),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('SKU', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                TextField(
                                  controller: skuCtrl,
                                  decoration: InputDecoration(
                                    border: const UnderlineInputBorder(),
                                    hintText: '${state.sku}-$label'.replaceAll(' ', ''),
                                  ),
                                  onChanged: (value) => notifier.updateVariantOverride(key, sku: value),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          if (state.isVariantTemplate && combos.isEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.exclamationmark_triangle, color: AppTheme.warningColor, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add at least one size or color to create variants, or tap Save to save without variants.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChipInput({
    required String label,
    required List<String> items,
    required TextEditingController controller,
    required VoidCallback onAdd,
    required void Function(String) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...items.map((v) => Chip(
              label: Text(v),
              deleteIcon: const Icon(CupertinoIcons.xmark, size: 14),
              onDeleted: () => onRemove(v),
              backgroundColor: AppTheme.accentColor.withValues(alpha: 0.1),
              side: BorderSide(color: AppTheme.accentColor.withValues(alpha: 0.3)),
            )),
            SizedBox(
              width: 120,
              height: 36,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Add...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  suffixIcon: GestureDetector(
                    onTap: onAdd,
                    child: const Icon(CupertinoIcons.plus_circle_fill, color: AppTheme.accentColor, size: 20),
                  ),
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
          ],
        ),
      ],
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
