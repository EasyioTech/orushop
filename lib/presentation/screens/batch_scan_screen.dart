import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/core/database/database_helper.dart';
import 'package:orushops/core/database/table_constants.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/core/services/global_catalog_service.dart';
import 'package:orushops/providers/products_provider.dart';
import 'package:orushops/providers/shop_provider.dart';

class _ScannedItem {
  final GlobalProduct product;
  int quantity = 0;

  _ScannedItem({required this.product});
}

class BatchScanScreen extends ConsumerStatefulWidget {
  const BatchScanScreen({super.key});

  @override
  ConsumerState<BatchScanScreen> createState() => _BatchScanScreenState();
}

class _BatchScanScreenState extends ConsumerState<BatchScanScreen> {
  final List<_ScannedItem> _scannedItems = [];
  final Map<String, int> _skuToIndex = {};
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  String? _lastScannedName;
  String? _lastScannedSKU;
  DateTime? _lastScanTime;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final sku = (barcode.rawValue ?? '').trim();
      if (sku.isEmpty) continue;

      final now = DateTime.now();
      if (_lastScanTime != null && 
          now.difference(_lastScanTime!) < const Duration(milliseconds: 1500)) {
        continue;
      }

      _processSKU(sku);
      _lastScanTime = now;
      break; 
    }
  }

  Future<void> _processSKU(String sku) async {
    if (mounted) {
      setState(() {
        _isProcessing = true;
        _lastScannedSKU = sku;
        _lastScannedName = null; // Clear previous name while searching
      });
    }
    
    final catalog = ref.read(globalCatalogServiceProvider);
    final shopType = ref.read(shopDetailsProvider)?.shopType;
    final product = await catalog.searchBySKU(sku, shopType?.name);

    if (product != null) {
      _addItemToList(product);
      // Short feedback delay for found items
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _isProcessing = false);
    } else {
      HapticFeedback.vibrate();
      await _showQuickAddDialog(sku);
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _addItemToList(GlobalProduct product) {
    setState(() {
      final sku = product.sku;
      if (_skuToIndex.containsKey(sku)) {
        final index = _skuToIndex[sku]!;
        _scannedItems[index].quantity++;
      } else {
        _scannedItems.insert(0, _ScannedItem(product: product));
        // Re-map indices
        _skuToIndex.clear();
        for (int i = 0; i < _scannedItems.length; i++) {
          _skuToIndex[_scannedItems[i].product.sku] = i;
        }
      }
      _lastScannedName = product.name;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _showQuickAddDialog(String sku) async {
    _scannerController.stop();
    final TextEditingController nameController = TextEditingController();
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('New Product Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: $sku', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                hintText: 'Enter name for this item',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final newProduct = GlobalProduct(
                  name: nameController.text,
                  sku: sku,
                  typicalPrice: 0.0,
                  typicalCost: 0.0,
                  category: 'Uncategorized',
                );
                _addItemToList(newProduct);
                Navigator.pop(context);
              }
            },
            child: const Text('ADD TO LIST'),
          ),
        ],
      ),
    );
    
    _scannerController.start();
  }

  Future<void> _saveAll() async {
    if (_scannedItems.isEmpty) return;

    setState(() => _isProcessing = true);
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final now = DateTime.now();

    try {
      await db.transaction((txn) async {
        for (final item in _scannedItems) {
          final p = item.product;
          final productMap = {
            'name': p.name,
            'sku': p.sku,
            'price': p.typicalPrice,
            'imageUrl': p.imageUrl,
            'quantity': item.quantity,
            'category': p.category,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          };
          
          final productId = await txn.insert(TableConstants.products, productMap);

          await txn.insert(TableConstants.productBatches, {
            'productId': productId,
            'quantity': item.quantity,
            'costPrice': p.typicalCost,
            'expiryDate': now.add(const Duration(days: 365)).toIso8601String(),
            'createdAt': now.toIso8601String(),
          });
        }
      });

      HapticFeedback.heavyImpact();
      ref.invalidate(productsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully added ${_scannedItems.length} products'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.no_photography_rounded, size: 48, color: Colors.white54),
                    const SizedBox(height: 16),
                    Text(
                      'Camera access required or not available',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),

          // Custom Scanner Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    width: 280,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isProcessing ? AppTheme.primaryColor : Colors.white54,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  child: Stack(
                    children: [
                      const _ScanningLine(),
                      if (_isProcessing)
                        const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                      if (!_isProcessing)
                        const Center(
                          child: Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Colors.white24,
                            size: 48,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        style: IconButton.styleFrom(backgroundColor: AppTheme.slate500),
                      ),
                      const Spacer(),
                      if (_scannedItems.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_scannedItems.length} Products Found',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),

                if (_lastScannedName != null || _isProcessing)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: AppTheme.slate400, blurRadius: 10)],
                      ),
                      child: Row(
                        children: [
                          _isProcessing 
                            ? const SizedBox(
                                width: 20, 
                                height: 20, 
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)
                              )
                            : const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isProcessing 
                                ? 'Looking up SKU: ${_lastScannedSKU ?? ""}' 
                                : 'Found: $_lastScannedName',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const Spacer(),

                // Scanned Items List
                Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textSecondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: _scannedItems.isEmpty
                            ? Center(
                                child: Text(
                                  'Scan items to build a list',
                                  style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _scannedItems.length,
                                itemBuilder: (context, index) {
                                  final item = _scannedItems[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ListTile(
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: item.product.imageUrl != null
                                              ? Image.network(item.product.imageUrl!, fit: BoxFit.cover)
                                              : const Icon(Icons.image),
                                        ),
                                      ),
                                      title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                                      trailing: Text('x${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
                                    ),
                                  );
                                },
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _scannedItems.isEmpty || _isProcessing ? null : _saveAll,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isProcessing 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('APPROVE ALL (${_scannedItems.length})'),
                          ),
                        ),
                      ),
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
}

class _ScanningLine extends StatefulWidget {
  const _ScanningLine();

  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: 200 * _controller.value,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
              color: AppTheme.primaryColor,
            ),
          ),
        );
      },
    );
  }
}
