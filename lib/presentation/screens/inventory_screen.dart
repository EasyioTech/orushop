import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'package:orushops/core/services/product_crud_service.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/products_provider.dart';
import 'package:orushops/providers/batch_provider.dart';
import 'package:orushops/features/inventory/screens/create_product/create_product_screen.dart';
import 'edit_product_screen.dart';
import 'inventory_history_screen.dart';
import 'batch_scan_screen.dart';
import 'package:orushops/core/models/product.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';
import 'package:orushops/providers/analytics_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedSubcategory = 'All';

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
    ).then((_) {
      ref.invalidate(productsProvider);
      ref.invalidate(paginatedProductsProvider);
      ref.invalidate(expiredBatchesProvider);
    });
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
                    (_searchQuery.isEmpty ||
                     p.name.toLowerCase().contains(_searchQuery) ||
                     (p.brand?.toLowerCase().contains(_searchQuery) ?? false) ||
                     p.sku.toLowerCase().contains(_searchQuery)) &&
                    (_selectedCategory == 'All' || p.category == _selectedCategory) &&
                    (_selectedSubcategory == 'All' || p.subcategory == _selectedSubcategory),
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
                        autofocus: false,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: AppTheme.primaryColor,
                        decoration: InputDecoration(
                          hintText: 'Search by name or SKU...',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary.withValues(alpha: 0.5),
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
                        ),
                        onChanged: (v) =>
                            setState(() => _searchQuery = v.toLowerCase()),
                      ),
                    ),
                  ),
                ),

                // Category & Subcategory Pills
                SliverToBoxAdapter(
                  child: Container(
                    color: AppTheme.backgroundColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategoryPills(ref),
                        _buildSubcategoryPills(ref),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 100),
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
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.8,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _InventoryItemPill(
                                product: filtered[index],
                                onAddStock: () =>
                                    _showAddStockSheet(context, filtered[index]),
                              ),
                              childCount: filtered.length,
                            ),
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

  Widget _buildCategoryPills(WidgetRef ref) {
    final categoriesAsync = ref.watch(productCategoriesProvider);
    return categoriesAsync.when(
      data: (categories) {
        final allCategories = ['All', ...categories];
        return Container(
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: allCategories.length,
            itemBuilder: (context, index) {
              final cat = allCategories[index];
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = cat;
                      _selectedSubcategory = 'All';
                    });
                  },
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? AppTheme.primaryColor : AppTheme.slate200),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 40),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildSubcategoryPills(WidgetRef ref) {
    if (_selectedCategory == 'All') return const SizedBox.shrink();
    final categoriesAsync = ref.watch(shopCategoriesProvider);
    return categoriesAsync.when(
      data: (categories) {
        final categoryObj = categories.firstWhere(
          (c) => c.name == _selectedCategory,
          orElse: () => categories.first,
        );
        if (categoryObj.subcategories.isEmpty) return const SizedBox.shrink();
        final allSubcats = ['All', ...categoryObj.subcategories];
        return Container(
          height: 32,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: allSubcats.length,
            itemBuilder: (context, index) {
              final subcat = allSubcats[index];
              final isSelected = _selectedSubcategory == subcat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(subcat, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedSubcategory = subcat);
                  },
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.3) : AppTheme.slate200),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 32),
      error: (e, s) => const SizedBox.shrink(),
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
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showProductMenu(context, ref),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name ?? 'Unknown',
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Qty: ${widget.product.quantity ?? 0}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEdit() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductScreen(product: widget.product),
      ),
    ).then((_) {
      ref.invalidate(productsProvider);
      ref.invalidate(paginatedProductsProvider);
      ref.invalidate(expiredBatchesProvider);
    });
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
                ).then((_) {
                  ref.invalidate(productsProvider);
                  ref.invalidate(paginatedProductsProvider);
                  ref.invalidate(expiredBatchesProvider);
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
              title: const Text('Delete Product'),
              textColor: AppTheme.errorColor,
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
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(BuildContext context, WidgetRef ref) async {
    try {
      final service = ProductCrudService();
      await service.deleteProduct(widget.product.id);
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

  Widget _buildProductInfoTags(Product product, List<ShopCategory> categories) {
    // Find the category config for this product
    final category = categories.firstWhere(
      (c) => c.name == product.category,
      orElse: () => ShopCategory(name: product.category, productFields: ProductFieldConfig.basic()),
    );
    final fields = category.productFields;
    final List<Widget> tags = [];

    void addTag(String label, String value, IconData icon) {
      if (value.isEmpty) return;
      tags.add(
        Container(
          margin: const EdgeInsets.only(right: 8, top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: AppTheme.primaryColor),
              const SizedBox(width: 4),
              Text(
                '$label: $value',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (fields.hasBrand && product.brand != null && product.brand!.isNotEmpty) {
      addTag('Brand', product.brand!, Icons.branding_watermark_outlined);
    }
    
    if (fields.hasWeight && product.weight != null && product.weight!.isNotEmpty) {
      addTag('Weight', product.weight!, Icons.scale_outlined);
    }

    if (fields.hasSizeVariant && product.size != null && product.size!.isNotEmpty) {
      addTag('Size', product.size!, Icons.straighten_outlined);
    }

    if (fields.hasColorVariant && product.color != null && product.color!.isNotEmpty) {
      addTag('Color', product.color!, Icons.palette_outlined);
    }

    if (fields.hasExpiryDate && product.expiryDate != null && product.expiryDate!.isNotEmpty) {
      addTag('Exp', product.expiryDate!.split('T')[0], Icons.event_busy_outlined);
    }

    if (fields.hasBatchNumber && product.batchNumber != null && product.batchNumber!.isNotEmpty) {
      addTag('Batch', product.batchNumber!, Icons.batch_prediction_outlined);
    }

    if (fields.hasSerialNumber && product.serialNumber != null && product.serialNumber!.isNotEmpty) {
      addTag('SN', product.serialNumber!, Icons.numbers_outlined);
    }

    return Wrap(children: tags);
  }
}

class _InventoryItemPill extends ConsumerStatefulWidget {
  final dynamic product;
  final VoidCallback onAddStock;

  const _InventoryItemPill({
    required this.product,
    required this.onAddStock,
  });

  @override
  ConsumerState<_InventoryItemPill> createState() => _InventoryItemPillState();
}

class _InventoryItemPillState extends ConsumerState<_InventoryItemPill> {
  void _openEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: widget.product),
      ),
    );
  }

  void _showProductMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_box_rounded, color: AppTheme.primaryColor),
              title: const Text('Add Stock', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                widget.onAddStock();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
              title: const Text('Edit Product', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _openEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
              title: const Text('Delete Product', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Product?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor))),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ProductCrudService().deleteProduct(widget.product.id);
                  ref.invalidate(productsProvider);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLowStock = widget.product.quantity < 10;
    final bool isOutOfStock = widget.product.quantity == 0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.slate200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.slate900.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: () {
            HapticFeedback.heavyImpact();
            _showProductMenu(context, ref);
          },
          onTap: () {
            HapticFeedback.selectionClick();
            _openEdit();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Product Icon/Image
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.slate50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.slate100, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
                        ? Image.network(
                            widget.product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                          )
                        : _buildPlaceholderIcon(),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppTheme.slate900,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOutOfStock 
                                ? AppTheme.errorColor.withValues(alpha: 0.1)
                                : (isLowStock ? AppTheme.warningColor.withValues(alpha: 0.1) : AppTheme.successColor.withValues(alpha: 0.1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOutOfStock ? Icons.error_outline_rounded : Icons.inventory_2_outlined,
                                  size: 10,
                                  color: isOutOfStock 
                                    ? AppTheme.errorColor 
                                    : (isLowStock ? AppTheme.warningColor : AppTheme.successColor),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.product.quantity.toInt()} left',
                                  style: TextStyle(
                                    color: isOutOfStock 
                                      ? AppTheme.errorColor 
                                      : (isLowStock ? AppTheme.warningColor : AppTheme.successColor),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '₹${widget.product.price}',
                            style: const TextStyle(
                              color: AppTheme.slate500,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
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
        size: 20,
        color: AppTheme.textSecondary.withValues(alpha: 0.3),
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
  final _batchController = TextEditingController();
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
    _batchController.dispose();
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
                        'QUANTITY',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: AppTheme.slate500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _qtyController,
                        focusNode: _qtyFocusNode,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          filled: true,
                          fillColor: AppTheme.slate50,
                          contentPadding: const EdgeInsets.symmetric(vertical: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: AppTheme.slate200, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2.5),
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
                        'COST PRICE',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: AppTheme.slate500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _costController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.successColor,
                        ),
                        decoration: InputDecoration(
                          prefixText: '₹',
                          prefixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          hintText: '0',
                          filled: true,
                          fillColor: AppTheme.slate50,
                          contentPadding: const EdgeInsets.symmetric(vertical: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: AppTheme.slate200, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: AppTheme.successColor, width: 2.5),
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
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Batch Number',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _batchController,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter batch number',
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    prefixIcon: const Icon(Icons.tag_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Expiry Date',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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
    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    final cost = double.tryParse(_costController.text) ?? 0;

    if (qty <= 0 || cost <= 0) {
      HapticFeedback.heavyImpact();
      return;
    }

    try {
      final service = ProductCrudService();
      await service.addStock(
        productId: widget.product.id,
        quantity: qty,
        costPrice: cost,
        expiryDate: _expiry,
        batchNumber: _batchController.text.trim().isEmpty ? null : _batchController.text.trim(),
      );

      HapticFeedback.mediumImpact();
      if (mounted) {
        ref.invalidate(productsProvider);
        ref.invalidate(lowStockProductsProvider);
        ref.invalidate(expiringBatchesProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
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

