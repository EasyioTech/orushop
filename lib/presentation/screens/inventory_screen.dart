import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

part 'inventory/inventory_widgets.dart';
part 'inventory/add_stock_sheet.dart';

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
    // Variant-matrix products keep stock per size/color combo, which the
    // simple add-stock sheet can't express — send the owner to the editor.
    if (product is Product && product.template == ProductTemplate.variantMatrix) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product has variants — open it to update stock per size/color.'),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditProductScreen(product: product)),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddStockBottomSheet(product: product),
    );
  }
}
