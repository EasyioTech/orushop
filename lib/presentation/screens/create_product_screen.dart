import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:orushops/core/models/product.dart';
import 'package:orushops/core/database/database_helper.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/products_provider.dart';
import 'package:orushops/core/services/global_catalog_service.dart';
import 'package:orushops/features/onboarding/models/shop_catalog_data.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';
import 'package:orushops/providers/shop_provider.dart';
import 'batch_scan_screen.dart';

class CreateProductScreen extends ConsumerStatefulWidget {
  const CreateProductScreen({super.key});

  @override
  ConsumerState<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends ConsumerState<CreateProductScreen> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _initialQtyController = TextEditingController();

  // Advanced fields
  final _mrpController = TextEditingController();
  final _hsnController = TextEditingController();
  final _taxController = TextEditingController();
  final _brandController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _imeiController = TextEditingController();
  final _warrantyController = TextEditingController();
  final _weightController = TextEditingController();
  final _isbnController = TextEditingController();
  final _colorController = TextEditingController();
  final _sizeController = TextEditingController();

  final _scannerController = MobileScannerController();
  final _imagePicker = ImagePicker();

  List<ShopCategory> _categories = [];
  ShopCategory? _selectedCategory;
  String? _selectedSubcategory;
  String _selectedUnit = 'Piece';
  DateTime? _expiryDate;

  bool _showScanner = false;
  bool _showAdvanced = false;
  File? _productImage;
  String? _externalImageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _initialQtyController.dispose();
    _mrpController.dispose();
    _hsnController.dispose();
    _taxController.dispose();
    _brandController.dispose();
    _manufacturerController.dispose();
    _batchNumberController.dispose();
    _serialNumberController.dispose();
    _imeiController.dispose();
    _warrantyController.dispose();
    _weightController.dispose();
    _isbnController.dispose();
    _colorController.dispose();
    _sizeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });

    _skuController.addListener(() {
      final sku = _skuController.text.trim();
      if (sku.length >= 8) {
        _lookupGlobalProduct(sku);
      }
    });
  }

  void _loadCategories() {
    final shopType = ref.read(shopTypeProvider);
    final catalog = ShopCatalog.forType(shopType);
    if (!mounted) return;
    setState(() {
      _categories = catalog;
      if (_categories.isNotEmpty && _selectedCategory == null) {
        _onCategoryChanged(_categories.first);
      }
    });
  }

  void _onCategoryChanged(ShopCategory? category) {
    if (category == null) return;
    setState(() {
      _selectedCategory = category;
      _selectedSubcategory = category.subcategories.isNotEmpty ? category.subcategories.first : null;
      _selectedUnit = category.productFields.defaultUnit;
      _taxController.text = category.productFields.defaultTaxRate.toString();
      _expiryDate = null;
    });
  }

  Future<void> _lookupGlobalProduct(String sku) async {
    final catalog = ref.read(globalCatalogServiceProvider);
    final product = await catalog.searchBySKU(sku);
    if (product != null && mounted && _nameController.text.isEmpty) {
      setState(() {
        _nameController.text = product.name;
        _priceController.text = product.typicalPrice.toString();
        _costController.text = product.typicalCost.toString();
        _externalImageUrl = product.imageUrl;
        final matchingCat = _categories.firstWhere(
          (c) => c.name.toLowerCase() == product.category.toLowerCase(),
          orElse: () => _categories.first,
        );
        _onCategoryChanged(matchingCat);
      });
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('Found: ${product.name}'),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _generateSKU() {
    final prefix = (_selectedCategory?.name ?? 'PROD').substring(0, 3).toUpperCase();
    final random = (1000 + (DateTime.now().millisecond % 9000));
    _skuController.text = '$prefix-$random';
    HapticFeedback.selectionClick();
  }

  Future<void> _createProduct() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0;
    final cost = double.tryParse(_costController.text) ?? 0;
    final initialQty = int.tryParse(_initialQtyController.text) ?? 0;

    if (name.isEmpty) {
      HapticFeedback.heavyImpact();
      _showError('Enter the item name');
      return;
    }
    if (price <= 0) {
      HapticFeedback.heavyImpact();
      _showError('Enter the sell price');
      return;
    }
    if (cost <= 0) {
      HapticFeedback.heavyImpact();
      _showError('Enter the buy price');
      return;
    }

    // Auto-generate SKU if empty
    if (_skuController.text.trim().isEmpty) {
      _generateSKU();
    }
    final sku = _skuController.text.trim();

    try {
      final now = DateTime.now();
      String? imageUrl;
      String? imagePath;

      if (_productImage != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final newImage = await _productImage!.copy('${appDir.path}/$fileName');
        imagePath = newImage.path;
      } else if (_externalImageUrl != null) {
        imageUrl = _externalImageUrl;
      }

      final product = Product(
        id: 0,
        name: name,
        sku: sku,
        price: price,
        quantity: initialQty,
        category: _selectedCategory?.name ?? 'Other',
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
        imageUrl: imageUrl,
        imagePath: imagePath,
        createdAt: now,
        updatedAt: now,
      );

      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      await db.transaction((txn) async {
        final productMap = product.toMap();
        productMap.remove('id');
        final productId = await txn.insert('products', productMap);

        if (initialQty > 0) {
          final batchMap = {
            'productId': productId,
            'quantity': initialQty,
            'costPrice': cost,
            'batchNumber': _batchNumberController.text.trim().isEmpty ? null : _batchNumberController.text.trim(),
            'expiryDate': (_expiryDate ?? now.add(const Duration(days: 365))).toIso8601String(),
            'createdAt': now.toIso8601String(),
          };
          await txn.insert('product_batches', batchMap);
        }
      });

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ref.invalidate(productsProvider);
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text('$name added!'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.successColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openSKUScanner() => setState(() => _showScanner = true);

  Future<void> _captureProductImage() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (photo != null) {
        setState(() => _productImage = File(photo.path));
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _pickProductImage() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (photo != null) {
        setState(() => _productImage = File(photo.path));
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primaryColor,
            onPrimary: Colors.white,
            onSurface: AppTheme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    // Watch for shop type changes (e.g. from Other to Medical)
    ref.listen(shopTypeAsyncProvider, (previous, next) {
      if (next.hasValue) {
        _loadCategories();
      }
    });
    if (_showScanner) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                for (final barcode in capture.barcodes) {
                  final sku = barcode.rawValue ?? '';
                  if (sku.isNotEmpty) {
                    HapticFeedback.mediumImpact();
                    _skuController.text = sku;
                    setState(() => _showScanner = false);
                    break;
                  }
                }
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                  onPressed: () => setState(() => _showScanner = false),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── CATEGORY FIRST — tap one button ─────────────────────
                  _buildLabel('What type of item is this?'),
                  const SizedBox(height: 10),
                  _buildCategoryChips(),
                  if (_selectedCategory != null && _selectedCategory!.subcategories.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildLabel('Choose type'),
                    const SizedBox(height: 10),
                    _buildSubcategoryChips(),
                  ],
                  const SizedBox(height: 28),

                  // ── PRODUCT NAME ─────────────────────────────────────────
                  _buildLabel('Item Name *'),
                  const SizedBox(height: 10),
                  _buildBigInput(
                    controller: _nameController,
                    hint: 'e.g. Sugar, Shirt, Soap',
                    icon: Icons.shopping_bag_outlined,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 24),

                  // ── PRICE ROW ────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Sell Price *'),
                            const SizedBox(height: 10),
                            _buildBigInput(
                              controller: _priceController,
                              hint: '0',
                              icon: Icons.sell_outlined,
                              prefix: '₹',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Buy Price *'),
                            const SizedBox(height: 10),
                            _buildBigInput(
                              controller: _costController,
                              hint: '0',
                              icon: Icons.receipt_long_outlined,
                              prefix: '₹',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── STOCK COUNT ──────────────────────────────────────────
                  _buildLabel('How many items do you have now?'),
                  const SizedBox(height: 10),
                  _buildBigInput(
                    controller: _initialQtyController,
                    hint: '0',
                    icon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),

                  // ── PHOTO ────────────────────────────────────────────────
                  _buildLabel('Photo (not required)'),
                  const SizedBox(height: 10),
                  _buildPhotoSection(),
                  const SizedBox(height: 28),

                  // ── ADVANCED TOGGLE ──────────────────────────────────────
                  GestureDetector(
                    onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _showAdvanced ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _showAdvanced ? 'Show less' : 'More details (not required)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_showAdvanced) ...[
                    const SizedBox(height: 20),
                    _buildAdvancedSection(),
                  ],

                  const SizedBox(height: 32),

                  // ── CREATE BUTTON ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 68,
                    child: ElevatedButton.icon(
                      onPressed: _createProduct,
                      icon: const Icon(Icons.add_circle_rounded, size: 24),
                      label: const Text(
                        'Add Item',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                        shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
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

  Widget _buildHeader() {
    return Container(
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
        right: 16,
        bottom: 28,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Add New Item',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
          ),
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BatchScanScreen())),
            icon: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
            label: const Text('Bulk Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white24,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
    );
  }

  Widget _buildBigInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? prefix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 18, color: Colors.grey.shade400),
        prefixText: prefix != null ? '$prefix ' : null,
        prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        prefixIcon: Icon(icon, size: 22, color: AppTheme.primaryColor),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.map((cat) {
        final isSelected = _selectedCategory == cat;
        return GestureDetector(
          onTap: () => _onCategoryChanged(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                  : [],
            ),
            child: Text(
              cat.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubcategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedCategory!.subcategories.map((sub) {
        final isSelected = _selectedSubcategory == sub;
        return GestureDetector(
          onTap: () => setState(() => _selectedSubcategory = sub),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.12) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
            ),
            child: Text(
              sub,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotoSection() {
    final hasImage = _productImage != null || _externalImageUrl != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _productImage != null
                  ? Image.file(_productImage!, height: 160, width: double.infinity, fit: BoxFit.cover)
                  : Image.network(_externalImageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, size: 48)),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: _buildPhotoBtn(
                  onPressed: _captureProductImage,
                  icon: Icons.camera_alt_rounded,
                  label: hasImage ? 'Retake' : 'Camera',
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPhotoBtn(
                  onPressed: hasImage ? () => setState(() { _productImage = null; _externalImageUrl = null; }) : _pickProductImage,
                  icon: hasImage ? Icons.close_rounded : Icons.photo_library_rounded,
                  label: hasImage ? 'Remove' : 'Gallery',
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoBtn({required VoidCallback onPressed, required IconData icon, required String label, required bool isPrimary}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppTheme.primaryColor : AppTheme.backgroundColor,
        foregroundColor: isPrimary ? Colors.white : AppTheme.primaryColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    final fields = _selectedCategory?.productFields;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SKU / Barcode
          _buildSmallLabel('Barcode / SKU'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skuController,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: _smallInputDec('PROD-1234', Icons.qr_code_rounded),
                ),
              ),
              const SizedBox(width: 8),
              _iconBtn(onPressed: _openSKUScanner, icon: Icons.camera_alt_outlined, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              _iconBtn(onPressed: _generateSKU, icon: Icons.auto_fix_high_rounded, color: AppTheme.primaryLight),
            ],
          ),

          if (fields != null && fields.hasMrp) ...[
            const SizedBox(height: 16),
            _buildSmallLabel('MRP (printed price on pack)'),
            const SizedBox(height: 8),
            TextField(
              controller: _mrpController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: _smallInputDec('0.00', Icons.tag_rounded, prefix: '₹ '),
            ),
          ],

          if (fields != null && fields.hasBrand) ...[
            const SizedBox(height: 16),
            _buildSmallLabel('Brand'),
            const SizedBox(height: 8),
            TextField(
              controller: _brandController,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: _smallInputDec('e.g. Samsung, Amul', Icons.branding_watermark_outlined),
            ),
          ],

          if (fields != null && fields.hasWeight) ...[
            const SizedBox(height: 16),
            _buildSmallLabel('Weight / Volume'),
            const SizedBox(height: 8),
            TextField(
              controller: _weightController,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: _smallInputDec('e.g. 500g, 1L', Icons.scale_outlined),
            ),
          ],

          if (fields != null && fields.hasUnit && (fields.unitOptions.length > 1)) ...[
            const SizedBox(height: 16),
            _buildSmallLabel('Unit (piece / kg / litre)'),
            const SizedBox(height: 8),
            _buildUnitDropdown(fields.unitOptions),
          ],

          if (fields != null && fields.hasExpiryDate) ...[
            const SizedBox(height: 16),
            _buildSmallLabel('Expiry Date (not required)'),
            const SizedBox(height: 8),
            _buildDateTile(),
          ],

          if (fields != null && (fields.hasHsnCode || fields.hasTaxRate)) ...[
            const SizedBox(height: 16),
            _buildSmallLabel('GST / Tax Info'),
            const SizedBox(height: 8),
            Row(
              children: [
                if (fields.hasHsnCode)
                  Expanded(
                    child: TextField(
                      controller: _hsnController,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      decoration: _smallInputDec('HSN Code', Icons.article_outlined),
                    ),
                  ),
                if (fields.hasHsnCode && fields.hasTaxRate) const SizedBox(width: 12),
                if (fields.hasTaxRate)
                  Expanded(
                    child: TextField(
                      controller: _taxController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      decoration: _smallInputDec('Tax %', Icons.percent_rounded),
                    ),
                  ),
              ],
            ),
          ],

          if (fields != null && fields.hasSerialNumber) ...[
            const SizedBox(height: 16),
            _buildSmallLabel('Serial Number'),
            const SizedBox(height: 8),
            TextField(
              controller: _serialNumberController,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: _smallInputDec('SN-123456', Icons.numbers_rounded),
            ),
          ],

          if (fields != null && fields.hasImei) ...[
            const SizedBox(height: 16),
            _buildSmallLabel('IMEI Number'),
            const SizedBox(height: 8),
            TextField(
              controller: _imeiController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: _smallInputDec('15-digit IMEI', Icons.phone_android_rounded),
            ),
          ],

          if (fields != null && fields.hasWarranty) ...[
            const SizedBox(height: 16),
            _buildSmallLabel('Warranty'),
            const SizedBox(height: 8),
            TextField(
              controller: _warrantyController,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: _smallInputDec('e.g. 1 Year, 6 Months', Icons.verified_user_outlined),
            ),
          ],

          if (fields != null && fields.hasSizeVariant) ...[
            const SizedBox(height: 16),
            _buildSmallLabel('Size'),
            const SizedBox(height: 8),
            if (fields.sizeOptions.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: fields.sizeOptions.map((s) {
                  final isSel = _sizeController.text == s;
                  return GestureDetector(
                    onTap: () => setState(() => _sizeController.text = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? AppTheme.primaryColor : AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSel ? AppTheme.primaryColor : Colors.grey.shade300),
                      ),
                      child: Text(s, style: TextStyle(fontWeight: FontWeight.bold, color: isSel ? Colors.white : AppTheme.textPrimary)),
                    ),
                  );
                }).toList(),
              )
            else
              TextField(
                controller: _sizeController,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                decoration: _smallInputDec('e.g. XL, 42', Icons.straighten_rounded),
              ),
          ],

          if (fields != null && fields.hasColorVariant) ...[
            const SizedBox(height: 16),
            _buildSmallLabel('Color'),
            const SizedBox(height: 8),
            TextField(
              controller: _colorController,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: _smallInputDec('e.g. Red, Navy Blue', Icons.palette_outlined),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary.withValues(alpha: 0.8)));
  }

  InputDecoration _smallInputDec(String hint, IconData icon, {String? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixText: prefix,
      prefixIcon: Icon(icon, size: 18, color: AppTheme.primaryColor),
      filled: true,
      fillColor: AppTheme.backgroundColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _iconBtn({required VoidCallback onPressed, required IconData icon, required Color color}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onPressed, borderRadius: BorderRadius.circular(12), child: Icon(icon, color: color, size: 22)),
      ),
    );
  }

  Widget _buildUnitDropdown(List<String> options) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(12)),
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

  Widget _buildDateTile() {
    return GestureDetector(
      onTap: _pickExpiryDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(Icons.event_busy_rounded, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            Text(
              _expiryDate == null ? 'Pick a date' : DateFormat('dd MMM yyyy').format(_expiryDate!),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _expiryDate == null ? Colors.grey.shade400 : AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
