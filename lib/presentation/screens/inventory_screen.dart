import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/database_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/products_provider.dart';
import '../../providers/batch_provider.dart';
import 'create_product_screen.dart';
import 'edit_product_screen.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _navigateToCreateProduct() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateProductScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final expiredAsync = ref.watch(expiredBatchesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      // Removed standard AppBar to use Custom Branded Header
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _navigateToCreateProduct,
          label: const Text('New Product', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          icon: const Icon(Icons.add_business_rounded, size: 24),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      body: productsAsync.when(
        data: (products) {
          final filtered = products
              .where(
                (p) =>
                    p.name.toLowerCase().contains(_searchQuery) ||
                    p.sku.toLowerCase().contains(_searchQuery),
              )
              .toList();

          final expiredCount = expiredAsync.asData?.value.length ?? 0;

          return Column(
            children: [
              // Branded Header Section with Stats & Search
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
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20,
                  right: 20,
                  bottom: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Inventory Master',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildStatsHeader(products, expiredCount),
                    const SizedBox(height: 24),
                    // Integrated Search Bar with premium styling
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                      cursorColor: AppTheme.primaryColor,
                      decoration: InputDecoration(
                        hintText: 'Search by name or SKU...',
                        hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor, size: 22),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    ),
                  ],
                ),
              ),

              // Inventory List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    HapticFeedback.mediumImpact();
                    ref.invalidate(productsProvider);
                    ref.invalidate(expiredBatchesProvider);
                    await ref.read(productsProvider.future);
                    await ref.read(expiredBatchesProvider.future);
                  },
                  color: AppTheme.primaryColor,
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                            _buildEmptyState(),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _InventoryItemCard(
                            product: filtered[index],
                            onAddStock: () => _showAddStockSheet(context, filtered[index]),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStatsHeader(List products, int expiredCount) {
    final lowStockCount = products.where((p) => p.quantity < 10 && p.quantity > 0).length;
    final totalValue = products.fold<double>(
      0,
      (sum, p) => sum + (p.quantity * p.price),
    );

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: 'Inventory Value',
            value: '₹${NumberFormat.compact().format(totalValue)}',
            icon: Icons.account_balance_wallet_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBox(
            label: 'Low Stock',
            value: '$lowStockCount',
            icon: Icons.warning_amber_rounded,
            isWarning: lowStockCount > 0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBox(
            label: 'Expired',
            value: '$expiredCount',
            icon: Icons.event_busy_rounded,
            isError: expiredCount > 0,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.primaryColor.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 20),
          Text(
            'No products match your search',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for a different name or SKU',
            style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showAddStockSheet(BuildContext context, dynamic product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddStockBottomSheet(product: product),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isWarning;
  final bool isError;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    this.isWarning = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isError 
            ? AppTheme.errorColor.withValues(alpha: 0.5) 
            : (isWarning ? AppTheme.warningColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1)),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isError ? AppTheme.errorColor : (isWarning ? AppTheme.warningColor : Colors.white), size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryItemCard extends ConsumerWidget {
  final dynamic product;
  final VoidCallback onAddStock;

  const _InventoryItemCard({required this.product, required this.onAddStock});

  void _showProductMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
              title: const Text('Add Stock'),
              onTap: () {
                Navigator.pop(ctx);
                onAddStock();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
              title: const Text('Edit Product'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => EditProductScreen(product: product)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Product'),
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"? This will also delete all batches.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteProduct(context, ref);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(BuildContext context, WidgetRef ref) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        await txn.delete('product_batches', where: 'productId = ?', whereArgs: [product.id]);
        await txn.delete('products', where: 'id = ?', whereArgs: [product.id]);
      });
      if (context.mounted) {
        ref.invalidate(productsProvider);
        ref.invalidate(expiredBatchesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted'), backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isLowStock = product.quantity < 10;
    final bool isOutOfStock = product.quantity == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: () => _showProductMenu(context, ref),
          onTap: onAddStock,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 1. Visual Indicator / Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: (isOutOfStock
                            ? AppTheme.errorColor
                            : (isLowStock ? AppTheme.warningColor : AppTheme.primaryColor))
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isOutOfStock
                        ? Icons.error_outline_rounded
                        : (isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_rounded),
                    size: 24,
                    color: isOutOfStock
                        ? AppTheme.errorColor
                        : (isLowStock ? AppTheme.warningColor : AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 14),
                // 2. Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.4,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.sku,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (isOutOfStock)
                            const _StatusBadge(label: 'OUT OF STOCK', color: AppTheme.errorColor)
                          else if (isLowStock)
                            const _StatusBadge(label: 'LOW STOCK', color: AppTheme.warningColor),
                        ],
                      ),
                    ],
                  ),
                ),
                // 3. Quantity Display
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (isOutOfStock
                            ? AppTheme.errorColor
                            : (isLowStock ? AppTheme.warningColor : AppTheme.primaryColor))
                        .withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${product.displayQuantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          height: 1,
                          color: isOutOfStock
                              ? AppTheme.errorColor
                              : (isLowStock ? AppTheme.warningColor : AppTheme.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PCS',
                        style: TextStyle(
                          fontSize: 8,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: AppTheme.primaryColor.withValues(alpha: 0.3), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.2),
      ),
    );
  }
}

class _AddStockBottomSheet extends ConsumerStatefulWidget {
  final dynamic product;
  const _AddStockBottomSheet({required this.product});

  @override
  ConsumerState<_AddStockBottomSheet> createState() =>
      _AddStockBottomSheetState();
}

class _AddStockBottomSheetState extends ConsumerState<_AddStockBottomSheet> {
  final _qtyController = TextEditingController();
  final _costController = TextEditingController();
  final _qtyFocusNode = FocusNode();
  DateTime _expiry = DateTime.now().add(const Duration(days: 365));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _qtyFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _costController.dispose();
    _qtyFocusNode.dispose();
    super.dispose();
  }

  void _incrementQty(int amount) {
    final current = int.tryParse(_qtyController.text) ?? 0;
    _qtyController.text = (current + amount).toString();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24,
        right: 24,
        top: 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppTheme.borderColor, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Text(
              'Add Stock: ${widget.product.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _qtyController,
                        focusNode: _qtyFocusNode,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: '0',
                          filled: true,
                          fillColor: AppTheme.backgroundColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cost Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _costController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          prefixText: '₹',
                          hintText: '0',
                          filled: true,
                          fillColor: AppTheme.backgroundColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _QuickAddButton(label: '+10', onTap: () => _incrementQty(10))),
                const SizedBox(width: 8),
                Expanded(child: _QuickAddButton(label: '+50', onTap: () => _incrementQty(50))),
                const SizedBox(width: 8),
                Expanded(child: _QuickAddButton(label: '+100', onTap: () => _incrementQty(100))),
              ],
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Batch Expiry Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _expiry,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (date != null) setState(() => _expiry = date);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor),
                    const SizedBox(width: 16),
                    Text(
                      DateFormat('MMMM d, yyyy').format(_expiry),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_rounded, size: 18, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'CONFIRM ADD STOCK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    final qty = int.tryParse(_qtyController.text) ?? 0;
    final cost = double.tryParse(_costController.text) ?? 0;

    if (qty <= 0 || cost <= 0) {
      HapticFeedback.heavyImpact();
      return;
    }

    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      await db.transaction((txn) async {
        await txn.insert('product_batches', {
          'productId': widget.product.id,
          'quantity': qty,
          'costPrice': cost,
          'expiryDate': _expiry.toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
        });
      });

      HapticFeedback.mediumImpact();
      if (mounted) {
        ref.invalidate(productsProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _QuickAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
