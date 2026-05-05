import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/core/models/product.dart';
import 'package:orushops/core/services/product_crud_service.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/products_provider.dart';
import 'package:orushops/features/onboarding/models/shop_catalog_data.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';
import 'package:orushops/providers/shop_provider.dart';
import 'package:intl/intl.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _costController = TextEditingController();

    _skuController = TextEditingController(text: widget.product.sku);
    _mrpController = TextEditingController(text: widget.product.mrp?.toString() ?? '');
    _hsnController = TextEditingController(text: widget.product.hsnCode ?? '');
    _taxController = TextEditingController(text: widget.product.taxRate > 0 ? widget.product.taxRate.toString() : '');
    _brandController = TextEditingController(text: widget.product.brand ?? '');
    _manufacturerController = TextEditingController(text: widget.product.manufacturer ?? '');
    _serialNumberController = TextEditingController(text: widget.product.serialNumber ?? '');
    _imeiController = TextEditingController(text: widget.product.imei ?? '');
    _warrantyController = TextEditingController(text: widget.product.warranty ?? '');
    _weightController = TextEditingController(text: widget.product.weight ?? '');
    _isbnController = TextEditingController(text: widget.product.isbn ?? '');
    _colorController = TextEditingController(text: widget.product.color ?? '');
    _sizeController = TextEditingController(text: widget.product.size ?? '');
    _batchNumberController = TextEditingController();
    _expiryDate = null;

    _selectedSubcategory = widget.product.subcategory;
    _selectedUnit = widget.product.unit;

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
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
        orElse: () => _categories.isNotEmpty ? _categories.first : ShopCategory(
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
    setState(() {
      _selectedCategory = cat;
      _selectedSubcategory = cat.subcategories.isNotEmpty ? cat.subcategories.first : null;
      _selectedUnit = cat.productFields.defaultUnit;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
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
    _weightController.dispose();
    _isbnController.dispose();
    _colorController.dispose();
    _sizeController.dispose();
    _batchNumberController.dispose();
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
        weight: _weightController.text.trim().isEmpty ? null : _weightController.text.trim(),
        isbn: _isbnController.text.trim().isEmpty ? null : _isbnController.text.trim(),
        color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
        size: _sizeController.text.trim().isEmpty ? null : _sizeController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await ProductCrudService().updateProduct(updated);

      HapticFeedback.mediumImpact();
      if (!mounted) return;
      ref.invalidate(productsProvider);
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
            child: const Text('Yes, Delete', style: TextStyle(color: Colors.red)),
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
        onStockAdded: () => ref.invalidate(productsProvider),
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
                    color: Colors.red.withValues(alpha: 0.2),
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
                                color: selected ? AppTheme.primaryColor : Colors.grey.shade200,
                                width: selected ? 2 : 1,
                              ),
                              boxShadow: selected
                                  ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
                                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
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
                            side: BorderSide(color: sel ? AppTheme.primaryColor : Colors.grey.shade200),
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
                  const SizedBox(height: 28),

                  // ── ADVANCED TOGGLE ─────────────────────────────────────
                  GestureDetector(
                    onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
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

  Widget _stockCard(int stock, bool outOfStock, bool lowStock) {
    final color = outOfStock ? Colors.red : lowStock ? Colors.orange : AppTheme.primaryColor;
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
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
                  '$stock items',
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
        border: Border.all(color: Colors.grey.shade100),
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

          if (fields.hasBatchNumber) ...[
            const SizedBox(height: 20),
            _label('Batch Number'),
            const SizedBox(height: 8),
            _field(controller: _batchNumberController, hint: 'Enter batch number', icon: Icons.layers_outlined),
          ],

          if (fields.hasExpiryDate) ...[
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
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _expiryDate == null ? 'Select Expiry Date' : DateFormat('MMM dd, yyyy').format(_expiryDate!),
                      style: TextStyle(color: _expiryDate == null ? Colors.grey : AppTheme.textPrimary, fontWeight: FontWeight.w600),
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

          if (fields.hasSizeVariant) ...[
            const SizedBox(height: 20),
            _label('Size'),
            const SizedBox(height: 8),
            _field(controller: _sizeController, hint: 'e.g. S, M, L, XL', icon: Icons.straighten_rounded),
          ],
        ],
      ),
    );
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
  DateTime? _expiryDate;
  bool _loading = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _incrementQty(int amount) {
    final current = int.tryParse(_qtyController.text) ?? 0;
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
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
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
    final expiry = _expiryDate ?? DateTime.now().add(const Duration(days: 365));

    setState(() => _loading = true);
    try {
      await ProductCrudService().addStock(
        productId: widget.product.id,
        quantity: qty,
        costPrice: cost,
        expiryDate: expiry,
      );

      HapticFeedback.mediumImpact();
      widget.onStockAdded?.call();
      if (!mounted) return;
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
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
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
              hintStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.grey.shade300),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final amt in [10, 50, 100])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: () => _incrementQty(amt),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text('+$amt', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
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
