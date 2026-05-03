import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:orushops/core/models/product.dart';
import 'package:orushops/core/database/database_helper.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/products_provider.dart';
import 'package:orushops/core/services/global_catalog_service.dart';
import 'batch_scan_screen.dart';

const List<String> _defaultCategories = [
  'Apparel',
  'Electronics',
  'Accessories',
  'Groceries',
  'Other',
];

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
  final _scannerController = MobileScannerController();
  final _imagePicker = ImagePicker();
  String _selectedCategory = _defaultCategories[0];
  bool _showScanner = false;
  File? _productImage;
  String? _externalImageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _initialQtyController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _skuController.addListener(() {
      final sku = _skuController.text.trim();
      if (sku.length >= 8) { // Standard barcode length
        _lookupGlobalProduct(sku);
      }
    });
  }

  void _lookupGlobalProduct(String sku) {
    final catalog = ref.read(globalCatalogServiceProvider);
    final product = catalog.searchBySKU(sku);

    if (product != null && _nameController.text.isEmpty) {
      setState(() {
        _nameController.text = product.name;
        _priceController.text = product.typicalPrice.toString();
        _costController.text = product.typicalCost.toString();
        _externalImageUrl = product.imageUrl;
        if (_defaultCategories.contains(product.category)) {
          _selectedCategory = product.category;
        }
      });
      
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text('Auto-filled: ${product.name}'),
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

  void _generateSKU() {
    final prefix = _selectedCategory.substring(0, 3).toUpperCase();
    final random = (1000 + (DateTime.now().millisecond % 9000));
    _skuController.text = '$prefix-$random';
    HapticFeedback.selectionClick();
  }

  Future<void> _createProduct() async {
    final name = _nameController.text.trim();
    final sku = _skuController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0;
    final cost = double.tryParse(_costController.text) ?? 0;
    final initialQty = int.tryParse(_initialQtyController.text) ?? 0;

    if (name.isEmpty || sku.isEmpty || price <= 0 || cost <= 0 || initialQty < 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all required fields correctly'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.errorColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

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
        category: _selectedCategory,
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
          await txn.insert('product_batches', {
            'productId': productId,
            'quantity': initialQty,
            'costPrice': cost,
            'expiryDate': now.add(const Duration(days: 365)).toIso8601String(),
            'createdAt': now.toIso8601String(),
          });
        }
      });

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ref.invalidate(productsProvider);

      // Wait briefly for provider to rebuild before navigation
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text('Successfully added $name'),
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

  void _openSKUScanner() {
    setState(() => _showScanner = true);
  }

  Future<void> _captureProductImage() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() => _productImage = File(photo.path));
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e')),
        );
      }
    }
  }

  Future<void> _pickProductImage() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() => _productImage = File(photo.path));
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
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
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
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
                padding: const EdgeInsets.all(16.0),
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
          // Branded Header
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
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 12,
              right: 20,
              bottom: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Add New Product',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BatchScanScreen()),
                        );
                      },
                      icon: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                      label: const Text('BATCH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white24,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Text(
                    'Fill in the details to expand your catalog',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
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
                  // Section 1: Basic Info
                  _buildSectionHeader('BASIC INFORMATION'),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInputField(
                          controller: _nameController,
                          label: 'Product Name',
                          hint: 'e.g. Premium Cotton T-Shirt',
                          icon: Icons.shopping_bag_outlined,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: _buildInputField(
                                controller: _skuController,
                                label: 'Product SKU',
                                hint: 'PROD-123',
                                icon: Icons.qr_code_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildSquareButton(
                              onPressed: _openSKUScanner,
                              icon: Icons.camera_alt_outlined,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            _buildSquareButton(
                              onPressed: _generateSKU,
                              icon: Icons.auto_fix_high_rounded,
                              color: AppTheme.primaryLight,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Section 1.5: Product Image
                  _buildSectionHeader('PRODUCT IMAGE'),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_productImage != null || _externalImageUrl != null)
                          Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: _productImage != null
                                      ? Image.file(
                                          _productImage!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 200,
                                        )
                                      : Image.network(
                                          _externalImageUrl!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 200,
                                          errorBuilder: (context, error, stackTrace) => const Center(
                                            child: Icon(Icons.broken_image_outlined, size: 48, color: AppTheme.textSecondary),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildImageButton(
                                      onPressed: _captureProductImage,
                                      icon: Icons.camera_alt_rounded,
                                      label: _productImage != null ? 'Retake' : 'Capture',
                                      isPrimary: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildImageButton(
                                      onPressed: () => setState(() {
                                        _productImage = null;
                                        _externalImageUrl = null;
                                      }),
                                      icon: Icons.close_rounded,
                                      label: 'Remove',
                                      isPrimary: false,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 40,
                                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No image selected',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary.withValues(alpha: 0.6),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildImageButton(
                                      onPressed: _captureProductImage,
                                      icon: Icons.camera_alt_rounded,
                                      label: 'Capture',
                                      isPrimary: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildImageButton(
                                      onPressed: _pickProductImage,
                                      icon: Icons.photo_library_rounded,
                                      label: 'Gallery',
                                      isPrimary: false,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Section 2: Pricing & Stock
                  _buildSectionHeader('PRICING & STOCK'),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                controller: _priceController,
                                label: 'Selling Price',
                                hint: '0.00',
                                icon: Icons.payments_outlined,
                                keyboardType: TextInputType.number,
                                prefix: '₹ ',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInputField(
                                controller: _costController,
                                label: 'Cost Price',
                                hint: '0.00',
                                icon: Icons.receipt_long_outlined,
                                keyboardType: TextInputType.number,
                                prefix: '₹ ',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          controller: _initialQtyController,
                          label: 'Initial Stock (Units)',
                          hint: '0',
                          icon: Icons.inventory_2_outlined,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 13, 
                            fontWeight: FontWeight.bold, 
                            color: AppTheme.textSecondary.withValues(alpha: 0.8), 
                            letterSpacing: 0.5
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _defaultCategories.map((cat) {
                            final isSelected = _selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedCategory = cat),
                              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                              labelStyle: TextStyle(
                                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                              backgroundColor: AppTheme.backgroundColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.transparent),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _createProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                        shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                      ),
                      child: const Text(
                        'CREATE PRODUCT',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppTheme.textSecondary.withValues(alpha: 0.6),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    String? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary.withValues(alpha: 0.7), letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryColor),
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSquareButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }

  Widget _buildImageButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppTheme.primaryColor : AppTheme.backgroundColor,
        foregroundColor: isPrimary ? Colors.white : AppTheme.primaryColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}


