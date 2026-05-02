import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'package:orushops/core/database/database_helper.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/products_provider.dart';
import 'package:orushops/providers/batch_provider.dart';
import 'create_product_screen.dart';
import 'edit_product_screen.dart';
import 'inventory_history_screen.dart';
import 'batch_scan_screen.dart';

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

  bool _canPop() {
    return Navigator.of(context).canPop();
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

    return PopScope(
      canPop: _canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_canPop()) {
          // Prevent back navigation when at root screen
          return;
        }
      },
      child: Scaffold(
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
          heroTag: 'inventory_add_fab',
          onPressed: _navigateToCreateProduct,
          label: const Text(
            'Add Stock',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          icon: const Icon(Icons.add_business_rounded, size: 24),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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

          return RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              ref.invalidate(productsProvider);
              ref.invalidate(expiredBatchesProvider);
              await ref.read(productsProvider.future);
              await ref.read(expiredBatchesProvider.future);
            },
            color: AppTheme.primaryColor,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 280.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppTheme.primaryColor,
                  elevation: 0,
                  leading: _canPop()
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        )
                      : null,
                  title: const Text(
                    'Store Inventory',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Batch Scan',
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BatchScanScreen(),
                            ),
                          );
                        },
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.history_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InventoryHistoryScreen(),
                            ),
                          );
                        },
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryLight,
                          ],
                        ),
                      ),
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 40,
                        left: 20,
                        right: 20,
                        bottom: 110,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [_buildStatsHeader(products, expiredCount)],
                      ),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(80.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        autofocus: false, // Explicitly disable autofocus
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: AppTheme.primaryColor,
                        decoration: InputDecoration(
                          hintText: 'Search by name or SKU...',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppTheme.primaryColor,
                            size: 22,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
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
                        onChanged: (v) =>
                            setState(() => _searchQuery = v.toLowerCase()),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  sliver: filtered.isEmpty
                      ? SliverToBoxAdapter(
                          child: Column(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.15,
                              ),
                              _buildEmptyState(),
                            ],
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _InventoryItemCard(
                              product: filtered[index],
                              onAddStock: () =>
                                  _showAddStockSheet(context, filtered[index]),
                            ),
                            childCount: filtered.length,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      ),
    );
  }

  Widget _buildStatsHeader(List products, int expiredCount) {
    final lowStockCount = products
        .where((p) => p.quantity < 10 && p.quantity > 0)
        .length;
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
            child: Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No products match your search',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for a different name or SKU',
            style: TextStyle(
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
              fontSize: 13,
            ),
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
              : (isWarning
                    ? AppTheme.warningColor.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1)),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isError
                    ? AppTheme.errorColor
                    : (isWarning ? AppTheme.warningColor : Colors.white),
                size: 14,
              ),
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

class _InventoryItemCard extends ConsumerStatefulWidget {
  final dynamic product;
  final VoidCallback onAddStock;

  const _InventoryItemCard({required this.product, required this.onAddStock});

  @override
  ConsumerState<_InventoryItemCard> createState() => _InventoryItemCardState();
}

class _InventoryItemCardState extends ConsumerState<_InventoryItemCard> {
  void _openEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductScreen(product: widget.product),
      ),
    );
  }

  void _showProductMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.add_circle_outline,
                color: AppTheme.primaryColor,
              ),
              title: const Text('Add Stock'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onAddStock();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppTheme.primaryColor,
              ),
              title: const Text('Edit Product'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProductScreen(product: widget.product),
                  ),
                );
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
        content: Text(
          'Delete "${widget.product.name}"? This will also delete all batches.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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
        await txn.delete(
          'product_batches',
          where: 'productId = ?',
          whereArgs: [widget.product.id],
        );
        await txn.delete('products', where: 'id = ?', whereArgs: [widget.product.id]);
      });
      if (context.mounted) {
        ref.invalidate(productsProvider);
        ref.invalidate(expiredBatchesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLowStock = widget.product.quantity < 10;
    final bool isOutOfStock = widget.product.quantity == 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onLongPress: () => _showProductMenu(context, ref),
          onTap: _openEdit,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                // 1. Product Image / Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5), width: 1),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
                          ? Image.network(
                              widget.product.imageUrl!,
                              fit: BoxFit.contain,
                              width: 64,
                              height: 64,
                              alignment: Alignment.center,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                            )
                          : widget.product.imagePath != null && widget.product.imagePath!.isNotEmpty
                              ? Image.file(
                                  File(widget.product.imagePath!),
                                  fit: BoxFit.contain,
                                  width: 64,
                                  height: 64,
                                  alignment: Alignment.center,
                                  errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                                )
                              : _buildPlaceholderIcon(),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // 2. Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.product.sku,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (isOutOfStock)
                            const _StatusBadge(
                              label: 'OUT OF STOCK',
                              color: AppTheme.errorColor,
                            )
                          else if (isLowStock)
                            const _StatusBadge(
                              label: 'LOW STOCK',
                              color: AppTheme.warningColor,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 3. Add Stock Button
                const SizedBox(width: 12),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onAddStock();
                  },
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isOutOfStock
                                    ? AppTheme.errorColor
                                    : (isLowStock
                                          ? AppTheme.warningColor
                                          : AppTheme.primaryColor))
                                .withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.add,
                        color: isOutOfStock
                            ? AppTheme.errorColor
                            : (isLowStock
                                  ? AppTheme.warningColor
                                  : AppTheme.primaryColor),
                        size: 20,
                      ),
                    ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.inventory_2_rounded,
        size: 24,
        color: AppTheme.textSecondary.withValues(alpha: 0.4),
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
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
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
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add Stock: ${widget.product.name}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
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
                      const Text(
                        'Quantity',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _qtyController,
                        focusNode: _qtyFocusNode,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          filled: true,
                          fillColor: AppTheme.backgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
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
                      const Text(
                        'Cost Price',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _costController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          prefixText: '₹',
                          hintText: '0',
                          filled: true,
                          fillColor: AppTheme.backgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
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
                Expanded(
                  child: _QuickAddButton(
                    label: '+10',
                    onTap: () => _incrementQty(10),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickAddButton(
                    label: '+50',
                    onTap: () => _incrementQty(50),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickAddButton(
                    label: '+100',
                    onTap: () => _incrementQty(100),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Batch Expiry Date',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
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
                    Icon(
                      Icons.calendar_today_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      DateFormat('MMMM d, yyyy').format(_expiry),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'CONFIRM ADD STOCK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

