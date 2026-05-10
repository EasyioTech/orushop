import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:orushops/core/models/product.dart';
import 'package:orushops/core/models/product_variant.dart';
import 'package:orushops/core/database/database_helper.dart';
import 'package:orushops/core/database/table_constants.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/products_provider.dart';
import 'package:orushops/core/services/global_catalog_service.dart';
import 'package:orushops/features/onboarding/models/shop_catalog_data.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';
import 'package:orushops/providers/shop_provider.dart';
import 'package:orushops/providers/analytics_provider.dart';

class CreateProductScreen extends ConsumerStatefulWidget {
  const CreateProductScreen({super.key});

  @override
  ConsumerState<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends ConsumerState<CreateProductScreen> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _costController = TextEditingController();
  final _initialQtyController = TextEditingController(text: '0');

  // Advanced fields (hidden or auto-filled)
  final _mrpController = TextEditingController();
  final _hsnController = TextEditingController();
  final _taxController = TextEditingController();
  final _brandController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _imeiController = TextEditingController();
  final _warrantyController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _recipeController = TextEditingController();
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
  bool _isService = false;
  bool _isLoose = false;
  int _currentStep = 0;
  File? _productImage;
  String? _externalImageUrl;

  // Variant matrix state
  final List<String> _variantSizes = [];
  final List<String> _variantColors = [];
  // per-combo override: key = "$size|$color"
  final Map<String, _VariantOverride> _variantOverrides = {};
  final _newSizeController = TextEditingController();
  final _newColorController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _wholesalePriceController.dispose();
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
    _scheduleController.dispose();
    _recipeController.dispose();
    _weightController.dispose();
    _isbnController.dispose();
    _colorController.dispose();
    _sizeController.dispose();
    _scannerController.dispose();
    _newSizeController.dispose();
    _newColorController.dispose();
    for (final ov in _variantOverrides.values) { ov.dispose(); }
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
    final fields = category.productFields;
    setState(() {
      _selectedCategory = category;
      _selectedSubcategory = category.subcategories.isNotEmpty ? category.subcategories.first : null;
      _selectedUnit = fields.defaultUnit;
      _taxController.text = fields.defaultTaxRate.toString();
      _expiryDate = null;
      _isLoose = fields.isLoose;
      _isService = fields.isService;
      if (_isLoose) _isService = false;
      if (_isService) _isLoose = false;
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
        if (_currentStep == 1) _currentStep = 2; // Auto-advance
      });
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 20),
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
    final initialQty = double.tryParse(_initialQtyController.text) ?? 0.0;

    if (name.isEmpty) {
      HapticFeedback.heavyImpact();
      _showError('Please enter the name');
      setState(() => _currentStep = 1);
      return;
    }
    if (price <= 0) {
      HapticFeedback.heavyImpact();
      _showError('Please enter the price');
      setState(() => _currentStep = 2);
      return;
    }

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
        schedule: _scheduleController.text.trim().isEmpty ? null : _scheduleController.text.trim(),
        recipe: _recipeController.text.trim().isEmpty ? null : _recipeController.text.trim(),
        weight: _weightController.text.trim().isEmpty ? null : _weightController.text.trim(),
        isbn: _isbnController.text.trim().isEmpty ? null : _isbnController.text.trim(),
        color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
        size: _sizeController.text.trim().isEmpty ? null : _sizeController.text.trim(),
        imageUrl: imageUrl,
        imagePath: imagePath,
        createdAt: now,
        updatedAt: now,
        expiryDate: _expiryDate?.toIso8601String(),
        batchNumber: _batchNumberController.text.trim().isEmpty ? null : _batchNumberController.text.trim(),
        isService: _isService,
        isLoose: _isLoose,
        wholesalePrice: double.tryParse(_wholesalePriceController.text),
        costPrice: double.tryParse(_costController.text),
      );

      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      await db.transaction((txn) async {
        final productMap = product.toMap();
        productMap.remove('id');
        final productId = await txn.insert(TableConstants.products, productMap);

        if (_isVariantTemplate && _variantOverrides.isNotEmpty) {
          // Insert variant rows; stock is tracked in product_variants, not product_batches
          for (final entry in _variantOverrides.entries) {
            final parts = entry.key.split('|');
            final size = parts[0];
            final color = parts.length > 1 ? parts[1] : '';
            final ov = entry.value;
            final varPrice = double.tryParse(ov.price.text) ?? price;
            final varStock = double.tryParse(ov.stock.text) ?? 0.0;
            final varSku = ov.sku.text.trim().isNotEmpty
                ? ov.sku.text.trim()
                : '$sku-${[size, color].where((s) => s.isNotEmpty).join('-')}';
            final variant = ProductVariant(
              id: 0,
              productId: productId,
              size: size,
              color: color,
              sku: varSku,
              price: varPrice,
              stock: varStock,
              costPrice: cost > 0 ? cost : null,
              createdAt: now,
              updatedAt: now,
            );
            final varMap = variant.toMap()..remove('id');
            await txn.insert(TableConstants.productVariants, varMap);
          }
          // Update parent product quantity to sum of variant stocks
          final totalStock = _variantOverrides.values
              .fold<double>(0, (s, ov) => s + (double.tryParse(ov.stock.text) ?? 0));
          await txn.rawUpdate(
            'UPDATE products SET quantity = ? WHERE id = ?',
            [totalStock, productId],
          );
        } else if (initialQty > 0) {
          final batchMap = {
            'productId': productId,
            'quantity': initialQty,
            'costPrice': cost,
            'batchNumber': _batchNumberController.text.trim().isEmpty ? null : _batchNumberController.text.trim(),
            'expiryDate': (_expiryDate ?? now.add(const Duration(days: 365))).toIso8601String(),
            'createdAt': now.toIso8601String(),
          };
          await txn.insert(TableConstants.productBatches, batchMap);
        }
      });

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ref.invalidate(productsProvider);
      ref.invalidate(paginatedProductsProvider);
      ref.invalidate(lowStockProductsProvider);
      ref.invalidate(expiringBatchesProvider);
      Navigator.pop(context, true);
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showError('Error: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white, size: 36),
                  onPressed: () => setState(() => _showScanner = false),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.backgroundColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            _buildVisualHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStep(),
              ),
            ),
            _buildNavigationFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(CupertinoIcons.back, color: Colors.white),
              ),
              const Text(
                'Add Item',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 24),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(_totalSteps, (index) {
              final isActive = index <= _currentStep;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index == _totalSteps - 1 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            _getStepTitle(),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }

  bool get _isVariantTemplate =>
      _selectedCategory?.productFields.template == ProductTemplate.variantMatrix;

  int get _totalSteps => _isVariantTemplate ? 5 : 4;

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Choose Type';
      case 1: return 'What is it?';
      case 2: return 'How much?';
      case 3: return 'Inventory';
      case 4: return 'Variants';
      default: return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildStepCategory();
      case 1: return _buildStepInfo();
      case 2: return _buildStepPrice();
      case 3: return _buildStepStock();
      case 4: return _buildStepVariants();
      default: return const SizedBox();
    }
  }

  Widget _buildStepCategory() {
    return GridView.builder(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final isSelected = _selectedCategory == cat;
        return GestureDetector(
          onTap: () {
            _onCategoryChanged(cat);
            HapticFeedback.mediumImpact();
            setState(() => _currentStep = 1);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isSelected ? Colors.transparent : AppTheme.borderColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getCategoryIcon(cat.name),
                  size: 40,
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                ),
                const SizedBox(height: 12),
                Text(
                  cat.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Widget _buildStepInfo() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          _buildBigCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Name of Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'e.g. Sugar, Milk, Paracetamol',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey.shade300),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  onPressed: () => setState(() => _showScanner = true),
                  icon: CupertinoIcons.barcode_viewfinder,
                  label: 'Scan Barcode',
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionBtn(
                  onPressed: _captureProductImage,
                  icon: CupertinoIcons.camera_fill,
                  label: 'Take Photo',
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          if (_productImage != null) ...[
            const SizedBox(height: 24),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.file(_productImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _productImage = null),
                    child: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepPrice() {
    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          _buildBigCard(
            color: AppTheme.successColor.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selling Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.successColor)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('₹', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.successColor)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppTheme.successColor),
                        decoration: const InputDecoration(border: InputBorder.none, hintText: '0'),
                        onSubmitted: (_) => setState(() => _currentStep = 3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoose) ...[
            const SizedBox(height: 16),
            _buildBigCard(
              color: const Color(0xFFFF9500).withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Wholesale Price (full pack)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFF9500))),
                  const Text('Lower price for bulk buyers', style: TextStyle(fontSize: 12, color: Color(0xFFFF9500))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('₹', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFFFF9500))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _wholesalePriceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFFFF9500)),
                          decoration: const InputDecoration(border: InputBorder.none, hintText: '0'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildBigCard(
            color: AppTheme.errorColor.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Buying Cost', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.errorColor)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('₹', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.errorColor)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _costController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppTheme.errorColor),
                        decoration: const InputDecoration(border: InputBorder.none, hintText: '0'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepStock() {
    return SingleChildScrollView(
      key: const ValueKey(3),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBigCard(
            child: Column(
              children: [
                const Text('Current Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isLoose)
                      _roundBtn(
                        icon: CupertinoIcons.minus,
                        onPressed: () {
                          final val = double.tryParse(_initialQtyController.text) ?? 0;
                          if (val > 0) _initialQtyController.text = (val - 1).toStringAsFixed(0);
                        },
                      ),
                    Container(
                      width: _isLoose ? 200 : 120,
                      alignment: Alignment.center,
                      child: TextField(
                        controller: _initialQtyController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.numberWithOptions(decimal: _isLoose),
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
                        decoration: const InputDecoration(border: InputBorder.none),
                      ),
                    ),
                    if (!_isLoose)
                      _roundBtn(
                        icon: CupertinoIcons.plus,
                        onPressed: () {
                          final val = double.tryParse(_initialQtyController.text) ?? 0;
                          _initialQtyController.text = (val + 1).toStringAsFixed(0);
                        },
                      ),
                  ],
                ),
                Text(_selectedUnit, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (_selectedCategory?.productFields.hasExpiryDate ?? false) ...[
            const SizedBox(height: 24),
            _buildBigCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: _pickExpiryDate,
                title: const Text('Expiry Date', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_expiryDate == null ? 'Not set' : DateFormat('dd MMM yyyy').format(_expiryDate!)),
                trailing: const Icon(CupertinoIcons.calendar),
              ),
            ),
          ],
          if (_selectedCategory?.productFields.hasBatchNumber ?? false) ...[
            const SizedBox(height: 16),
            _buildBigCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Batch Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Text('Number printed on the box/packet', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _batchNumberController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. BT2024-001',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.numbers_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_selectedCategory?.productFields.hasSerialNumber ?? false) ...[
            const SizedBox(height: 16),
            _buildBigCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Serial Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _serialNumberController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. SN123456789',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.tag_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_selectedCategory?.productFields.hasImei ?? false) ...[
            const SizedBox(height: 16),
            _buildBigCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('IMEI Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Text('15-digit number on the box or under battery', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _imeiController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '15-digit IMEI',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.phone_android_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_selectedCategory?.productFields.hasWarranty ?? false) ...[
            const SizedBox(height: 16),
            _buildBigCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Warranty Period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Text('How long is the guarantee?', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _warrantyController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 1 Year, 6 Months',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.verified_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_selectedCategory?.productFields.hasSchedule ?? false) ...[
            const SizedBox(height: 16),
            _buildBigCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Drug Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Text('H = prescription required, H1 = dangerous, X = narcotic', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _scheduleController.text.isEmpty ? null : _scheduleController.text,
                    decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.warning_amber_outlined)),
                    hint: const Text('Not scheduled (OTC)'),
                    items: const [
                      DropdownMenuItem(value: 'H', child: Text('Schedule H — Prescription Only')),
                      DropdownMenuItem(value: 'H1', child: Text('Schedule H1 — Dangerous Drug')),
                      DropdownMenuItem(value: 'X', child: Text('Schedule X — Narcotic/Psychotropic')),
                    ],
                    onChanged: (v) => setState(() => _scheduleController.text = v ?? ''),
                  ),
                ],
              ),
            ),
          ],
          if (_selectedCategory?.productFields.hasIsbn ?? false) ...[
            const SizedBox(height: 16),
            _buildBigCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Book Code (ISBN)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Text('13-digit number on the back of the book', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _isbnController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '13-digit ISBN',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.menu_book_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_selectedCategory?.productFields.hasRecipe ?? false) ...[
            const SizedBox(height: 16),
            _buildBigCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('What is in it?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Text('List the ingredients or cooking notes (optional)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _recipeController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Wheat, Sugar, Salt...',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.restaurant_menu_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Only show toggles when the category doesn't already force these flags
          if (!(_selectedCategory?.productFields.isService ?? false) ||
              !(_selectedCategory?.productFields.isLoose ?? false)) ...[
            const SizedBox(height: 32),
          ],
          if (!(_selectedCategory?.productFields.isService ?? false)) ...[
            _toggleTile(
              title: 'Service (No Stock)',
              subtitle: 'Turn ON for repairs, haircut, labor — stock will not go down on sale',
              value: _isService,
              onChanged: (v) => setState(() { _isService = v; if (v) _isLoose = false; }),
              icon: Icons.design_services_outlined,
            ),
            const SizedBox(height: 12),
          ],
          if (!(_selectedCategory?.productFields.isLoose ?? false)) ...[
            _toggleTile(
              title: 'Sell by Weight / Measure',
              subtitle: 'Turn ON if you sell in grams, kg, ml, litre — e.g. rice, oil, cloth',
              value: _isLoose,
              onChanged: (v) => setState(() { _isLoose = v; if (v) _isService = false; }),
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
                  child: _productImage != null 
                    ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_productImage!, fit: BoxFit.cover))
                    : const Icon(CupertinoIcons.cube_box, color: AppTheme.slate400),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_nameController.text.isEmpty ? 'New Item' : _nameController.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.5)),
                      Text('Selling at ₹${_priceController.text}', style: const TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.w800, fontSize: 16)),
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

  Widget _toggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: value ? AppTheme.primaryColor.withValues(alpha: 0.4) : Colors.grey.shade200),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Icon(icon, color: value ? AppTheme.primaryColor : Colors.grey.shade400, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildBigCard({required Widget child, Color? color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildActionBtn({required VoidCallback onPressed, required IconData icon, required String label, required Color color}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _roundBtn({required IconData icon, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 28),
      ),
    );
  }

  Widget _buildStepVariants() {
    final basePrice = double.tryParse(_priceController.text) ?? 0;

    Widget chipInput({
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
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
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
                      child: const Icon(CupertinoIcons.plus_circle_fill, color: AppTheme.primaryColor, size: 20),
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

    void addSize() {
      final v = _newSizeController.text.trim();
      if (v.isNotEmpty && !_variantSizes.contains(v)) {
        setState(() {
          _variantSizes.add(v);
          _newSizeController.clear();
        });
      }
    }

    void addColor() {
      final v = _newColorController.text.trim();
      if (v.isNotEmpty && !_variantColors.contains(v)) {
        setState(() {
          _variantColors.add(v);
          _newColorController.clear();
        });
      }
    }

    void removeSize(String s) {
      setState(() {
        _variantSizes.remove(s);
        _variantOverrides.removeWhere((k, _) => k.startsWith('$s|'));
      });
    }

    void removeColor(String c) {
      setState(() {
        _variantColors.remove(c);
        _variantOverrides.removeWhere((k, _) => k.endsWith('|$c'));
      });
    }

    // Build grid rows
    final combos = <(String, String)>[];
    if (_variantSizes.isEmpty && _variantColors.isNotEmpty) {
      for (final c in _variantColors) { combos.add(('', c)); }
    } else if (_variantColors.isEmpty && _variantSizes.isNotEmpty) {
      for (final s in _variantSizes) { combos.add((s, '')); }
    } else {
      for (final s in _variantSizes) {
        for (final c in _variantColors) { combos.add((s, c)); }
      }
    }

    return SingleChildScrollView(
      key: const ValueKey(4),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBigCard(
            child: chipInput(
              label: 'Sizes',
              items: _variantSizes,
              controller: _newSizeController,
              onAdd: addSize,
              onRemove: removeSize,
            ),
          ),
          const SizedBox(height: 16),
          _buildBigCard(
            child: chipInput(
              label: 'Colors',
              items: _variantColors,
              controller: _newColorController,
              onAdd: addColor,
              onRemove: removeColor,
            ),
          ),
          if (combos.isEmpty) ...[
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Add sizes or colors above\nto build your variant grid.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('VARIANT GRID', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppTheme.textSecondary, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 12),
            ...combos.map((combo) {
              final (size, color) = combo;
              final key = '$size|$color';
              final ov = _variantOverrides.putIfAbsent(key, () => _VariantOverride(
                price: basePrice > 0 ? basePrice.toStringAsFixed(0) : '',
                stock: '0',
                sku: '',
              ));
              final label = [size, color].where((s) => s.isNotEmpty).join(' / ');
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
                                  controller: ov.price,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(border: UnderlineInputBorder(), hintText: '0'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Stock', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                TextField(
                                  controller: ov.stock,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(border: UnderlineInputBorder(), hintText: '0'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('SKU', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                TextField(
                                  controller: ov.sku,
                                  decoration: InputDecoration(border: const UnderlineInputBorder(), hintText: '${_skuController.text}-$label'.replaceAll(' ', '')),
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
          // Warn if variant template but no combos defined
          if (_isVariantTemplate && combos.isEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.exclamationmark_triangle, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Add at least one size or color to create variants, or tap Save to save without variants.', style: TextStyle(fontSize: 13))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _currentStep--),
                child: const Text('Back', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentStep == _totalSteps - 1 ? _createProduct : () {
                if (_currentStep == 1 && _nameController.text.isEmpty) {
                  _showError('Please enter item name');
                  return;
                }
                setState(() => _currentStep++);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                _currentStep == _totalSteps - 1 ? 'Save Item' : 'Next',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

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


  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }
}

class _VariantOverride {
  final TextEditingController price;
  final TextEditingController stock;
  final TextEditingController sku;
  _VariantOverride({String? price, String? stock, String? sku})
      : price = TextEditingController(text: price ?? ''),
        stock = TextEditingController(text: stock ?? ''),
        sku = TextEditingController(text: sku ?? '');
  void dispose() {
    price.dispose();
    stock.dispose();
    sku.dispose();
  }
}
