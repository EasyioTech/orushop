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
import 'package:orushops/core/database/database_helper.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/products_provider.dart';
import 'package:orushops/core/services/global_catalog_service.dart';
import 'package:orushops/features/onboarding/models/shop_catalog_data.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';
import 'package:orushops/providers/shop_provider.dart';

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
  int _currentStep = 0;
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
    final initialQty = int.tryParse(_initialQtyController.text) ?? 0;

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
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
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
            children: List.generate(4, (index) {
              final isActive = index <= _currentStep;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
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

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Choose Type';
      case 1: return 'What is it?';
      case 2: return 'How much?';
      case 3: return 'Inventory';
      default: return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildStepCategory();
      case 1: return _buildStepInfo();
      case 2: return _buildStepPrice();
      case 3: return _buildStepStock();
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
      padding: const EdgeInsets.all(24),
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
      padding: const EdgeInsets.all(24),
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
          const SizedBox(height: 24),
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
      padding: const EdgeInsets.all(24),
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
                    _roundBtn(
                      icon: CupertinoIcons.minus,
                      onPressed: () {
                        final val = int.tryParse(_initialQtyController.text) ?? 0;
                        if (val > 0) _initialQtyController.text = (val - 1).toString();
                      },
                    ),
                    Container(
                      width: 120,
                      alignment: Alignment.center,
                      child: TextField(
                        controller: _initialQtyController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
                        decoration: const InputDecoration(border: InputBorder.none),
                      ),
                    ),
                    _roundBtn(
                      icon: CupertinoIcons.plus,
                      onPressed: () {
                        final val = int.tryParse(_initialQtyController.text) ?? 0;
                        _initialQtyController.text = (val + 1).toString();
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
              onPressed: _currentStep == 3 ? _createProduct : () {
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
                _currentStep == 3 ? 'Save Item' : 'Next',
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
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }
}
