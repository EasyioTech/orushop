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

  // Local stock quantity — refreshed when stock is added so the header card
  // stays accurate without needing to rebuild the whole route.
  late double _currentQuantity;

  // Inline add-stock fields
  final _addQtyController = TextEditingController();
  final _addCostController = TextEditingController();
  bool _addStockLoading = false;

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
    _currentQuantity = widget.product.displayQuantity;
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

    // Load variants asynchronously after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadVariants();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load categories here instead of initState so ref is available,
    // and also listen to shop type changes in one safe place — never inside build().
    _loadCategories();
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

      ShopCategory? matchingCat = _categories.cast<ShopCategory?>().firstWhere(
        (cat) => cat!.name == widget.product.category,
        orElse: () => null,
      );

      if (matchingCat == null && widget.product.category.isNotEmpty) {
        matchingCat = ShopCategory(
          name: widget.product.category,
          subcategories: [],
          productFields: ProductFieldConfig.basic(),
        );
        _categories = [matchingCat, ..._categories];
      }

      _selectedCategory = matchingCat;

      if (_selectedSubcategory == null || _selectedSubcategory!.isEmpty) {
        _selectedSubcategory = widget.product.subcategory;
      }

      if (_selectedSubcategory != null &&
          matchingCat != null &&
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
    _addQtyController.dispose();
    _addCostController.dispose();
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

      if (_currentTemplate == ProductTemplate.variantMatrix) {
        final repo = VariantRepository();
        for (final idStr in _deletedVariantIds) {
          await repo.delete(int.parse(idStr));
        }
        for (final v in _variants) {
          await repo.upsert(v);
        }
        final totalStock = _variants.fold<double>(0, (s, v) => s + v.stock);
        await repo.syncParentQuantity(widget.product.id, totalStock);
      }

      HapticFeedback.mediumImpact();
      if (!mounted) return;
      ref.invalidate(productsProvider);
      ref.invalidate(paginatedProductsProvider);
      ref.read(analyticsRevisionProvider.notifier).state++;
      // Show snackbar BEFORE popping — after pop the context is dead.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated ✓'), backgroundColor: AppTheme.successColor),
      );
      Navigator.pop(context, true);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Item?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('"${widget.product.name}" will be removed permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
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
      ref.read(analyticsRevisionProvider.notifier).state++;
      Navigator.pop(context, true);
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  Future<void> _submitInlineAddStock() async {
    final qty = double.tryParse(_addQtyController.text.trim()) ?? 0.0;
    if (qty <= 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter how many items came in')),
      );
      return;
    }
    final cost = double.tryParse(_addCostController.text.trim()) ?? 0.0;
    setState(() => _addStockLoading = true);
    try {
      await ProductCrudService().addStock(
        productId: widget.product.id,
        quantity: qty,
        costPrice: cost,
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        template: _currentTemplate ?? widget.product.template,
      );
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      setState(() {
        _currentQuantity += qty;
        _addQtyController.clear();
        _addCostController.clear();
      });
      // Use reset() so the products screen rebuilds with fresh DB data immediately.
      ref.read(paginatedProductsProvider.notifier).reset();
      ref.invalidate(productsProvider);
      ref.read(analyticsRevisionProvider.notifier).state++;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${qty % 1 == 0 ? qty.toInt() : qty.toStringAsFixed(2)} items added ✓'),
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
      if (mounted) setState(() => _addStockLoading = false);
    }
  }

  Widget _inlineAddStockSection() {
    const qtyColor = Color(0xFF0EA5E9);   // sky blue — "how many"
    const costColor = Color(0xFF8B5CF6);  // violet — "what you paid"

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: qtyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_box_outlined, size: 18, color: qtyColor),
                ),
                const SizedBox(width: 10),
                const Text('Add Stock', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                const Spacer(),
                Text(
                  'Current: ${_currentQuantity % 1 == 0 ? _currentQuantity.toInt() : _currentQuantity.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          const SizedBox(height: 14),

          // Field 1 — Quantity
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: qtyColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text('How many items are coming in?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _addQtyController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: qtyColor),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFCBD5E1)),
                    suffixText: 'items',
                    suffixStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: qtyColor.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: qtyColor.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: qtyColor.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: qtyColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final amt in [10.0, 50.0, 100.0])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            final cur = double.tryParse(_addQtyController.text) ?? 0.0;
                            final res = cur + amt;
                            setState(() {
                              _addQtyController.text = res % 1 == 0 ? res.toInt().toString() : res.toStringAsFixed(2);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: qtyColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: qtyColor.withValues(alpha: 0.25)),
                            ),
                            child: Text('+${amt.toInt()}', style: const TextStyle(color: qtyColor, fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          const SizedBox(height: 16),

          // Field 2 — Purchase price
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: costColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text('How much did you pay per item?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _addCostController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: costColor),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFCBD5E1)),
                    prefixText: '₹  ',
                    prefixStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: costColor),
                    suffixText: 'per item',
                    suffixStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: costColor.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: costColor.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: costColor.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: costColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Add button — full-width bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _addStockLoading ? null : _submitInlineAddStock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _addStockLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Add to Stock', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: ref.listen is NOT called here — it lives in didChangeDependencies.
    final isOutOfStock = _currentQuantity <= 0;
    final isLowStock = _currentQuantity > 0 && _currentQuantity < 10;
    final unitOptions = _selectedCategory?.productFields.unitOptions ?? ['Piece'];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 4,
              right: 16,
              bottom: 12,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Edit Item', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                      Text(
                        widget.product.name,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _deleteProduct,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.errorColor),
                  label: const Text('Delete', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w700, fontSize: 13)),
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.errorColor.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── STOCK STATUS ────────────────────────────────────────────
                  _stockStatusCard(_currentQuantity, isOutOfStock, isLowStock),
                  const SizedBox(height: 10),

                  // ── INLINE ADD STOCK ────────────────────────────────────────
                  if (widget.product.template != ProductTemplate.serviceLabor &&
                      _currentTemplate != ProductTemplate.variantMatrix)
                    _inlineAddStockSection(),
                  const SizedBox(height: 20),

                  // ── ITEM DETAILS CARD ───────────────────────────────────────
                  _sectionCard(
                    title: 'Item Details',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category dropdown
                        if (_categories.isNotEmpty) ...[
                          _label('Category'),
                          const SizedBox(height: 8),
                          _dropdown<ShopCategory>(
                            value: _selectedCategory,
                            items: _categories,
                            label: (c) => c.name,
                            onChanged: _onCategoryChanged,
                            hint: 'Select category',
                          ),
                          const SizedBox(height: 16),

                          // Subcategory dropdown
                          if (_selectedCategory != null && _selectedCategory!.subcategories.isNotEmpty) ...[
                            _label('Sub-category'),
                            const SizedBox(height: 8),
                            _dropdown<String>(
                              value: _selectedCategory!.subcategories.contains(_selectedSubcategory)
                                  ? _selectedSubcategory
                                  : _selectedCategory!.subcategories.first,
                              items: _selectedCategory!.subcategories,
                              label: (s) => s,
                              onChanged: (v) => setState(() => _selectedSubcategory = v),
                              hint: 'Select sub-category',
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],

                        // Item name
                        _label('Item Name *'),
                        const SizedBox(height: 8),
                        _field(
                          controller: _nameController,
                          hint: 'e.g. Tea, Soap, Shirt',
                          icon: Icons.label_outline_rounded,
                        ),
                        const SizedBox(height: 16),

                        // Unit dropdown (visible by default)
                        _label('Unit'),
                        const SizedBox(height: 8),
                        _dropdown<String>(
                          value: unitOptions.contains(_selectedUnit) ? _selectedUnit : unitOptions.first,
                          items: unitOptions,
                          label: (u) => u,
                          onChanged: (v) { if (v != null) setState(() => _selectedUnit = v); },
                          hint: 'Select unit',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── PRICING CARD ────────────────────────────────────────────
                  _sectionCard(
                    title: 'Pricing',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Sell Price *'),
                        const SizedBox(height: 8),
                        _priceField(
                          controller: _priceController,
                          hint: '0',
                          color: AppTheme.primaryColor,
                          icon: Icons.sell_rounded,
                        ),
                        if (_isLoose) ...[
                          const SizedBox(height: 16),
                          _label('Wholesale Price (bulk)'),
                          const SizedBox(height: 8),
                          _priceField(
                            controller: _wholesalePriceController,
                            hint: '0',
                            color: const Color(0xFF10B981),
                            icon: Icons.store_outlined,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── MORE DETAILS (ADVANCED) ─────────────────────────────────
                  GestureDetector(
                    onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _showAdvanced ? AppTheme.primaryColor.withValues(alpha: 0.4) : const Color(0xFFEEEEEE),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'More Details',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            ),
                          ),
                          Text(
                            'SKU · MRP · Brand · GST',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _showAdvanced ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.textSecondary,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_showAdvanced) ...[
                    const SizedBox(height: 12),
                    _advancedSection(),
                  ],

                  const SizedBox(height: 24),

                  // ── SAVE BUTTON ─────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _updateProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
