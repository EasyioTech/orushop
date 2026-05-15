import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/core/models/product.dart';
import 'package:orushops/core/models/product_variant.dart';
import 'package:orushops/core/repositories/variant_repository.dart';
import 'package:orushops/core/services/product_crud_service.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/products_provider.dart';
import 'package:orushops/features/onboarding/models/shop_catalog_data.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';
import 'package:orushops/providers/shop_provider.dart';
import 'package:intl/intl.dart';
import 'package:orushops/providers/analytics_provider.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _wholesalePriceController;
  late TextEditingController _costController;

  // Advanced fields
  late TextEditingController _skuController;
  late TextEditingController _mrpController;
  late TextEditingController _hsnController;
  late TextEditingController _taxController;
  late TextEditingController _brandController;
  late TextEditingController _manufacturerController;
  late TextEditingController _serialNumberController;
  late TextEditingController _imeiController;
  late TextEditingController _warrantyController;
  late TextEditingController _scheduleController;
  late TextEditingController _recipeController;
  late TextEditingController _weightController;
  late TextEditingController _isbnController;
  late TextEditingController _colorController;
  late TextEditingController _sizeController;
  late TextEditingController _batchNumberController;
  DateTime? _expiryDate;

  List<ShopCategory> _categories = [];
  ShopCategory? _selectedCategory;
  String? _selectedSubcategory;
  String _selectedUnit = 'Piece';
  bool _showAdvanced = false;
  bool _isService = false;
  bool _isLoose = false;

  // Variant matrix state
  List<ProductVariant> _variants = [];
  final List<String> _deletedVariantIds = [];
  final _newVariantSizeCtrl = TextEditingController();
  final _newVariantColorCtrl = TextEditingController();
  final _newVariantPriceCtrl = TextEditingController();
  final _newVariantStockCtrl = TextEditingController();

  ProductTemplate? _currentTemplate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _wholesalePriceController = TextEditingController(text: widget.product.wholesalePrice?.toString() ?? '');
    _costController = TextEditingController(text: widget.product.costPrice?.toString() ?? '');

    _skuController = TextEditingController(text: widget.product.sku);
    _mrpController = TextEditingController(text: widget.product.mrp?.toString() ?? '');
    _hsnController = TextEditingController(text: widget.product.hsnCode ?? '');
    _taxController = TextEditingController(text: widget.product.taxRate > 0 ? widget.product.taxRate.toString() : '');
    _brandController = TextEditingController(text: widget.product.brand ?? '');
    _manufacturerController = TextEditingController(text: widget.product.manufacturer ?? '');
    _serialNumberController = TextEditingController(text: widget.product.serialNumber ?? '');
    _imeiController = TextEditingController(text: widget.product.imei ?? '');
    _warrantyController = TextEditingController(text: widget.product.warranty ?? '');
    _scheduleController = TextEditingController(text: widget.product.schedule ?? '');
    _recipeController = TextEditingController(text: widget.product.recipe ?? '');
    _weightController = TextEditingController(text: widget.product.weight ?? '');
    _isbnController = TextEditingController(text: widget.product.isbn ?? '');
    _colorController = TextEditingController(text: widget.product.color ?? '');
    _sizeController = TextEditingController(text: widget.product.size ?? '');
    _batchNumberController = TextEditingController(text: widget.product.batchNumber ?? '');
    if (widget.product.expiryDate != null) {
      _expiryDate = DateTime.tryParse(widget.product.expiryDate!);
    }
    _currentTemplate = widget.product.template;

    _selectedSubcategory = widget.product.subcategory;
    _selectedUnit = widget.product.unit;
    _isService = widget.product.isService;
    _isLoose = widget.product.isLoose;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadCategories();
      await _loadVariants();
    });
  }

  Future<void> _loadVariants() async {
    final variants = await VariantRepository().getByProduct(widget.product.id);
    if (!mounted) return;
    setState(() => _variants = variants);
  }

  void _loadCategories() {
    final shopType = ref.read(shopTypeProvider);
    final catalog = ShopCatalog.forType(shopType);
    if (!mounted) return;

    setState(() {
      _categories = catalog;

      // Prioritize finding the exact category name in the new shop catalog
      final matchingCat = _categories.firstWhere(
        (cat) => cat.name == widget.product.category,
        orElse: () => ShopCategory(
          name: widget.product.category,
          subcategories: [],
          productFields: ProductFieldConfig.basic(),
        ),
      );

      _selectedCategory = matchingCat;
      
      // Synchronize subcategory if applicable
      if (_selectedSubcategory == null || _selectedSubcategory!.isEmpty) {
        _selectedSubcategory = widget.product.subcategory;
      }
      
      // If the selected category doesn't have the current subcategory, default to first or null
      if (_selectedSubcategory != null && 
          !matchingCat.subcategories.contains(_selectedSubcategory) && 
          matchingCat.subcategories.isNotEmpty) {
        _selectedSubcategory = matchingCat.subcategories.first;
      }
    });
  }

  void _onCategoryChanged(ShopCategory? cat) {
    if (cat == null) return;
    final fields = cat.productFields;
    setState(() {
      _selectedCategory = cat;
      _selectedSubcategory = cat.subcategories.isNotEmpty ? cat.subcategories.first : null;
      _selectedUnit = fields.defaultUnit;
      _currentTemplate = fields.template;
      _isLoose = fields.isLoose;
      _isService = fields.isService;
      if (_isLoose) _isService = false;
      if (_isService) _isLoose = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _wholesalePriceController.dispose();
    _costController.dispose();
    _skuController.dispose();
    _mrpController.dispose();
    _hsnController.dispose();
    _taxController.dispose();
    _brandController.dispose();
    _manufacturerController.dispose();
    _serialNumberController.dispose();
    _imeiController.dispose();
    _warrantyController.dispose();
    _scheduleController.dispose();
    _recipeController.dispose();
    _weightController.dispose();
    _isbnController.dispose();
    _colorController.dispose();
    _sizeController.dispose();
    _batchNumberController.dispose();
    _newVariantSizeCtrl.dispose();
    _newVariantColorCtrl.dispose();
    _newVariantPriceCtrl.dispose();
    _newVariantStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0;

    if (name.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Enter the item name'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }
    if (price <= 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Enter a valid sell price'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    final sku = _skuController.text.trim().isEmpty ? widget.product.sku : _skuController.text.trim();

    try {
      final updated = widget.product.copyWith(
        name: name,
        sku: sku,
        price: price,
        category: _selectedCategory?.name ?? widget.product.category,
        subcategory: _selectedSubcategory,
        unit: _selectedUnit,
        mrp: double.tryParse(_mrpController.text),
        hsnCode: _hsnController.text.trim().isEmpty ? null : _hsnController.text.trim(),
        taxRate: double.tryParse(_taxController.text) ?? 0.0,
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        manufacturer: _manufacturerController.text.trim().isEmpty ? null : _manufacturerController.text.trim(),
        serialNumber: _serialNumberController.text.trim().isEmpty ? null : _serialNumberController.text.trim(),
        imei: _imeiController.text.trim().isEmpty ? null : _imeiController.text.trim(),
        warranty: _warrantyController.text.trim().isEmpty ? null : _warrantyController.text.trim(),
        schedule: _scheduleController.text.trim().isEmpty ? null : _scheduleController.text.trim(),
        recipe: _recipeController.text.trim().isEmpty ? null : _recipeController.text.trim(),
        weight: _weightController.text.trim().isEmpty ? null : _weightController.text.trim(),
        isbn: _isbnController.text.trim().isEmpty ? null : _isbnController.text.trim(),
        color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
        size: _sizeController.text.trim().isEmpty ? null : _sizeController.text.trim(),
        expiryDate: _expiryDate?.toIso8601String(),
        batchNumber: _batchNumberController.text.trim().isEmpty ? null : _batchNumberController.text.trim(),
        isService: _isService,
        isLoose: _isLoose,
        wholesalePrice: double.tryParse(_wholesalePriceController.text),
        costPrice: double.tryParse(_costController.text),
        template: _currentTemplate ?? widget.product.template,
        updatedAt: DateTime.now(),
      );

      await ProductCrudService().updateProduct(updated);

      // Persist variant changes for variantMatrix products
      if (_currentTemplate == ProductTemplate.variantMatrix) {
        final repo = VariantRepository();
        for (final idStr in _deletedVariantIds) {
          await repo.delete(int.parse(idStr));
        }
        for (final v in _variants) {
          await repo.upsert(v);
        }
        // Sync parent quantity to sum of variant stocks
        final totalStock = _variants.fold<double>(0, (s, v) => s + v.stock);
        await repo.syncParentQuantity(widget.product.id, totalStock);
      }

      HapticFeedback.mediumImpact();
      if (!mounted) return;
      ref.invalidate(productsProvider);
      ref.invalidate(paginatedProductsProvider);
      ref.invalidate(lowStockProductsProvider);
      ref.invalidate(expiringBatchesProvider);
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Item updated ✓'), backgroundColor: AppTheme.successColor),
      );
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('"${widget.product.name}" will be removed forever.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ProductCrudService().deleteProduct(widget.product.id);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      ref.invalidate(productsProvider);
      ref.invalidate(paginatedProductsProvider);
      ref.invalidate(lowStockProductsProvider);
      ref.invalidate(expiringBatchesProvider);
      Navigator.pop(context, true);
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  void _showAddStockSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddStockBottomSheet(
        product: widget.product,
      onStockAdded: () {
        ref.invalidate(productsProvider);
        ref.invalidate(paginatedProductsProvider);
        ref.invalidate(lowStockProductsProvider);
        ref.invalidate(expiringBatchesProvider);
      },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch shop type to trigger category refresh if it changes (e.g. from Other to real type)
    ref.listen(shopTypeAsyncProvider, (previous, next) {
      if (next.hasValue) {
        _loadCategories();
      }
    });

    final currentStock = widget.product.displayQuantity;
    final isOutOfStock = currentStock <= 0;
    final isLowStock = currentStock < 10;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryColor, AppTheme.primaryLight],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 12,
              right: 20,
              bottom: 28,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Item',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        widget.product.name,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                    onPressed: _deleteProduct,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── STOCK CARD ──────────────────────────────────────────
                  _stockCard(currentStock, isOutOfStock, isLowStock),
                  const SizedBox(height: 12),
                  if (widget.product.template != ProductTemplate.serviceLabor)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _showAddStockSheet,
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                        label: const Text(
                          'Add Stock',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),

                  // ── CATEGORY CHIPS ──────────────────────────────────────
                  if (_categories.isNotEmpty) ...[
                    const Text(
                      'What type of item is this?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final selected = _selectedCategory?.name == cat.name;
                        return GestureDetector(
                          onTap: () => _onCategoryChanged(cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.primaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected ? AppTheme.primaryColor : AppTheme.slate200,
                                width: selected ? 2 : 1,
                              ),
                              boxShadow: selected
                                  ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
                                  : [BoxShadow(color: AppTheme.primaryDark.withValues(alpha: 0.04), blurRadius: 4)],
                            ),
                            child: Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                color: selected ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_selectedCategory != null && _selectedCategory!.subcategories.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedCategory!.subcategories.map((sub) {
                          final sel = _selectedSubcategory == sub;
                          return ChoiceChip(
                            label: Text(sub),
                            selected: sel,
                            onSelected: (v) { if (v) setState(() => _selectedSubcategory = sub); },
                            selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: sel ? AppTheme.primaryColor : AppTheme.textSecondary,
                              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(color: sel ? AppTheme.primaryColor : AppTheme.slate200),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 28),
                  ],

                  // ── PRODUCT NAME ────────────────────────────────────────
                  _label('Item Name *'),
                  const SizedBox(height: 8),
                  _field(controller: _nameController, hint: 'e.g. Tea, Soap, Shirt', icon: Icons.shopping_bag_outlined),
                  const SizedBox(height: 20),

                  // ── PRICE ROW ───────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Sell Price *'),
                            const SizedBox(height: 8),
                            _field(controller: _priceController, hint: '0', icon: Icons.sell_outlined, keyboard: TextInputType.number, prefix: '₹ '),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Buy Price'),
                            const SizedBox(height: 8),
                            _field(controller: _costController, hint: '0', icon: Icons.shopping_cart_outlined, keyboard: TextInputType.number, prefix: '₹ '),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_isLoose) ...[
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Wholesale Price (bulk/full pack)'),
                        const SizedBox(height: 8),
                        _field(controller: _wholesalePriceController, hint: '0', icon: Icons.store_outlined, keyboard: TextInputType.number, prefix: '₹ '),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),

                  // ── ADVANCED TOGGLE ─────────────────────────────────────
                  GestureDetector(
                    onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.slate200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _showAdvanced ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'More details',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                                ),
                                Text(
                                  'SKU, MRP, Brand, Weight, GST — not required',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_showAdvanced) ...[
                    const SizedBox(height: 20),
                    _advancedSection(),
                  ],

                  const SizedBox(height: 32),

                  // ── SAVE BUTTON ─────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _updateProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                        shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockCard(double stock, bool outOfStock, bool lowStock) {
    final color = outOfStock ? AppTheme.errorColor : lowStock ? AppTheme.warningColor : AppTheme.primaryColor;
    final msg = outOfStock
        ? 'Out of stock — add stock now'
        : lowStock
            ? 'Low stock — add more soon'
            : 'Stock is good';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.primaryDark.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.inventory_2_outlined, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stock % 1 == 0 ? stock.toInt() : stock.toStringAsFixed(2)} items',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                ),
                Text(msg, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _advancedSection() {
    if (_selectedCategory == null) return const SizedBox.shrink();
    final fields = _selectedCategory!.productFields;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('SKU / Barcode'),
          const SizedBox(height: 8),
          _field(controller: _skuController, hint: 'Scan or type barcode', icon: Icons.qr_code_rounded),

          if (fields.hasMrp) ...[
            const SizedBox(height: 20),
            _label('MRP (Printed Price)'),
            const SizedBox(height: 8),
            _field(controller: _mrpController, hint: '0', icon: Icons.tag_rounded, keyboard: TextInputType.number, prefix: '₹ '),
          ],

          if (fields.hasBrand) ...[
            const SizedBox(height: 20),
            _label('Brand Name'),
            const SizedBox(height: 8),
            _field(controller: _brandController, hint: 'e.g. Samsung, Tata', icon: Icons.branding_watermark_outlined),
          ],

          if (fields.hasWeight) ...[
            const SizedBox(height: 20),
            _label('Weight / Volume'),
            const SizedBox(height: 8),
            _field(controller: _weightController, hint: 'e.g. 500g, 1kg, 750ml', icon: Icons.scale_outlined),
          ],

          if (fields.hasUnit) ...[
            const SizedBox(height: 20),
            _label('Unit'),
            const SizedBox(height: 8),
            _unitDropdown(),
          ],

          const SizedBox(height: 20),
          _toggleTile(
            title: 'Service / No Stock',
            subtitle: 'No inventory deducted on sale (repairs, labor, sessions)',
            value: _isService,
            onChanged: (v) => setState(() { _isService = v; if (v) _isLoose = false; }),
            icon: Icons.design_services_outlined,
          ),

          const SizedBox(height: 12),
          _toggleTile(
            title: 'Loose / Fractional Qty',
            subtitle: 'Sell by weight, volume, or partial units (grams, ml, tablets)',
            value: _isLoose,
            onChanged: (v) => setState(() { _isLoose = v; if (v) _isService = false; }),
            icon: Icons.scale_outlined,
          ),

          if (_currentTemplate == ProductTemplate.batchExpiry || fields.hasBatchNumber) ...[
            const SizedBox(height: 20),
            _label('Batch Number'),
            const SizedBox(height: 8),
            _field(controller: _batchNumberController, hint: 'Enter batch number', icon: Icons.layers_outlined),
          ],

          if (_currentTemplate == ProductTemplate.batchExpiry || fields.hasExpiryDate) ...[
            const SizedBox(height: 20),
            _label('Expiry Date'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _expiryDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (date != null) setState(() => _expiryDate = date);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.slate200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _expiryDate == null ? 'Select Expiry Date' : DateFormat('MMM dd, yyyy').format(_expiryDate!),
                      style: TextStyle(color: _expiryDate == null ? AppTheme.slate500 : AppTheme.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (fields.hasImei) ...[
            const SizedBox(height: 20),
            _label('IMEI Number'),
            const SizedBox(height: 8),
            _field(controller: _imeiController, hint: '15-digit IMEI', icon: Icons.phone_android_rounded, keyboard: TextInputType.number),
          ],

          if (fields.hasSerialNumber) ...[
            const SizedBox(height: 20),
            _label('Serial Number'),
            const SizedBox(height: 8),
            _field(controller: _serialNumberController, hint: 'Manufacturer Serial No', icon: Icons.vibration_rounded),
          ],

          if (fields.hasTaxRate || fields.hasHsnCode) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                if (fields.hasHsnCode)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('HSN Code'),
                        const SizedBox(height: 8),
                        _field(controller: _hsnController, hint: '123456', icon: Icons.numbers_rounded),
                      ],
                    ),
                  ),
                if (fields.hasHsnCode && fields.hasTaxRate) const SizedBox(width: 12),
                if (fields.hasTaxRate)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Tax (%)'),
                        const SizedBox(height: 8),
                        _field(controller: _taxController, hint: '18', icon: Icons.percent_rounded, keyboard: TextInputType.number),
                      ],
                    ),
                  ),
              ],
            ),
          ],

          if (fields.hasWarranty) ...[
            const SizedBox(height: 20),
            _label('Warranty'),
            const SizedBox(height: 8),
            _field(controller: _warrantyController, hint: 'e.g. 1 Year', icon: Icons.verified_user_outlined),
          ],

          if (fields.hasIsbn) ...[
            const SizedBox(height: 20),
            _label('ISBN Number'),
            const SizedBox(height: 8),
            _field(controller: _isbnController, hint: '978-3...', icon: Icons.menu_book_rounded),
          ],

          if (fields.hasSchedule) ...[
            const SizedBox(height: 20),
            _label('Drug Schedule'),
            const SizedBox(height: 4),
            Text('H = prescription, H1 = dangerous, X = narcotic', style: TextStyle(fontSize: 12, color: AppTheme.slate500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _scheduleController.text.isEmpty ? null : _scheduleController.text,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.warning_amber_outlined),
              ),
              hint: const Text('Not scheduled (OTC)'),
              items: const [
                DropdownMenuItem(value: 'H', child: Text('Schedule H — Prescription Only')),
                DropdownMenuItem(value: 'H1', child: Text('Schedule H1 — Dangerous Drug')),
                DropdownMenuItem(value: 'X', child: Text('Schedule X — Narcotic/Psychotropic')),
              ],
              onChanged: (v) => setState(() => _scheduleController.text = v ?? ''),
            ),
          ],

          if (fields.hasRecipe) ...[
            const SizedBox(height: 20),
            _label('Recipe / Ingredients'),
            const SizedBox(height: 8),
            TextField(
              controller: _recipeController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'List ingredients or cooking notes...',
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.restaurant_menu_outlined),
              ),
            ),
          ],

          if (fields.template == ProductTemplate.variantMatrix) ...[
            const SizedBox(height: 20),
            _buildVariantEditor(),
          ] else if (fields.hasSizeVariant) ...[
            const SizedBox(height: 20),
            _label('Size'),
            const SizedBox(height: 8),
            _field(controller: _sizeController, hint: 'e.g. S, M, L, XL', icon: Icons.straighten_rounded),
          ],
        ],
      ),
    );
  }

  Widget _buildVariantEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.grid_view_rounded, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            _label('Size / Color Variants'),
            const Spacer(),
            Text('${_variants.length} combos', style: TextStyle(fontSize: 12, color: AppTheme.slate500)),
          ],
        ),
        const SizedBox(height: 12),

        // Existing variants list
        if (_variants.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.slate400),
                const SizedBox(width: 8),
                Text('No variants yet. Add below.', style: TextStyle(color: AppTheme.slate500, fontSize: 13)),
              ],
            ),
          )
        else
          ...List.generate(_variants.length, (i) {
            final v = _variants[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('₹${v.price.toStringAsFixed(0)}  ·  ${v.stock % 1 == 0 ? v.stock.toInt() : v.stock.toStringAsFixed(2)} in stock',
                          style: TextStyle(fontSize: 12, color: AppTheme.slate600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor, size: 20),
                    onPressed: () {
                      setState(() {
                        if (v.id > 0) _deletedVariantIds.add(v.id.toString());
                        _variants.removeAt(i);
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 12),
        // Add new variant row
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Variant', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newVariantSizeCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Size (S, M, L…)',
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _newVariantColorCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Color (Red…)',
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newVariantPriceCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Price',
                        prefixText: '₹ ',
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _newVariantStockCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Stock',
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addNewVariantLocally,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _addNewVariantLocally() {
    final size = _newVariantSizeCtrl.text.trim();
    final color = _newVariantColorCtrl.text.trim();
    if (size.isEmpty && color.isEmpty) return;
    final price = double.tryParse(_newVariantPriceCtrl.text) ?? widget.product.price.toDouble();
    final stock = double.tryParse(_newVariantStockCtrl.text) ?? 0.0;
    final now = DateTime.now();
    final sku = '${widget.product.sku}-${[size, color].where((s) => s.isNotEmpty).join('-')}';
    setState(() {
      _variants.add(ProductVariant(
        id: 0,
        productId: widget.product.id,
        size: size,
        color: color,
        sku: sku,
        price: price,
        stock: stock,
        costPrice: widget.product.costPrice,
        createdAt: now,
        updatedAt: now,
      ));
      _newVariantSizeCtrl.clear();
      _newVariantColorCtrl.clear();
      _newVariantPriceCtrl.clear();
      _newVariantStockCtrl.clear();
    });
  }

  Widget _unitDropdown() {
    final options = _selectedCategory?.productFields.unitOptions ?? ['Piece'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(_selectedUnit) ? _selectedUnit : options.first,
          isExpanded: true,
          items: options.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
          onChanged: (val) { if (val != null) setState(() => _selectedUnit = val); },
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
    );
  }

  Widget _toggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: value ? AppTheme.primaryColor.withValues(alpha: 0.4) : AppTheme.slate200),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Icon(icon, color: value ? AppTheme.primaryColor : AppTheme.slate400, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.slate600)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    String? prefix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix,
        prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryColor),
        filled: true,
        fillColor: AppTheme.backgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

// ── Add Stock Bottom Sheet ──────────────────────────────────────────────────

class _AddStockBottomSheet extends ConsumerStatefulWidget {
  final Product product;
  final VoidCallback? onStockAdded;

  const _AddStockBottomSheet({required this.product, this.onStockAdded});

  @override
  ConsumerState<_AddStockBottomSheet> createState() => _AddStockBottomSheetState();
}

class _AddStockBottomSheetState extends ConsumerState<_AddStockBottomSheet> {
  final _qtyController = TextEditingController();
  final _costController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _imeiController = TextEditingController();
  DateTime? _expiryDate;
  bool _loading = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _costController.dispose();
    _serialNumberController.dispose();
    _imeiController.dispose();
    super.dispose();
  }

  void _incrementQty(double amount) {
    final current = double.tryParse(_qtyController.text) ?? 0.0;
    _qtyController.text = (current + amount).toString();
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _submit() async {
    final qty = double.tryParse(_qtyController.text.trim()) ?? 0.0;
    final cost = double.tryParse(_costController.text.trim()) ?? 0;

    if (qty <= 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter how many items came in')),
      );
      return;
    }
    if (cost <= 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the buy price')),
      );
      return;
    }

    // Serialized template requires IMEI or serial number
    if (widget.product.template == ProductTemplate.serialized) {
      final serial = _serialNumberController.text.trim();
      final imei = _imeiController.text.trim();
      if (serial.isEmpty && imei.isEmpty) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter serial number or IMEI')),
        );
        return;
      }
    }

    final expiry = _expiryDate ?? DateTime.now().add(const Duration(days: 365));

    setState(() => _loading = true);
    try {
      await ProductCrudService().addStock(
        productId: widget.product.id,
        quantity: qty,
        costPrice: cost,
        expiryDate: expiry,
        batchNumber: null,
        template: widget.product.template,
        serialNumber: _serialNumberController.text.trim(),
        imei: _imeiController.text.trim(),
      );

      HapticFeedback.mediumImpact();
      widget.onStockAdded?.call();
      if (!mounted) return;
      ref.invalidate(productsProvider);
      ref.invalidate(paginatedProductsProvider);
      ref.invalidate(expiringBatchesProvider);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$qty items added ✓'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppTheme.slate300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('How many items came in?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
          Text(widget.product.name, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),

          // Quantity
          const Text('Number of items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.slate300),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final amt in [10.0, 50.0, 100.0])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: () => _incrementQty(amt),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text('+${amt.toInt()}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Cost Price
          const Text('Buy Price', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _costController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              hintText: '0.00',
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
          const SizedBox(height: 20),

          // Serial/IMEI fields (serialized products only)
          if (widget.product.template == ProductTemplate.serialized) ...[
            const Text('Serial Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _serialNumberController,
              keyboardType: TextInputType.text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Enter serial number',
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Text('IMEI (if applicable)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _imeiController,
              keyboardType: TextInputType.text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Enter IMEI',
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Expiry Date (optional)
          GestureDetector(
            onTap: _pickExpiry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    _expiryDate == null
                        ? 'Expiry date (not required)'
                        : 'Expires: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _expiryDate == null ? AppTheme.textSecondary : AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (_expiryDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _expiryDate = null),
                      child: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 6,
                shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
              child: _loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Add Stock ✓', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
