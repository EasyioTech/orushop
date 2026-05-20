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

part 'edit_product/edit_product_helpers.dart';
part 'edit_product/edit_product_advanced.dart';
part 'edit_product/edit_product_variants.dart';
part 'edit_product/edit_product_add_stock_sheet.dart';

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

}
