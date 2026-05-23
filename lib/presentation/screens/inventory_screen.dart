import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/widgets/shimmer_list.dart';

import 'package:orushops/core/services/product_crud_service.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/products_provider.dart';
import 'package:orushops/providers/batch_provider.dart';
import 'inventory_history_screen.dart';
import 'batch_scan_screen.dart';
import 'package:orushops/core/models/product.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';
import 'package:orushops/providers/analytics_provider.dart';
import 'package:orushops/providers/staff_provider.dart';
import 'package:orushops/providers/service_categories_provider.dart';
import 'package:orushops/providers/shop_provider.dart';
import 'package:orushops/features/inventory/controllers/product_form_notifier.dart';

part 'inventory/inventory_widgets.dart';
part 'inventory/add_stock_sheet.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> with SingleTickerProviderStateMixin {
  static final _compactFmt = NumberFormat.compact();
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedSubcategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _selectedCategory = 'All';
          _selectedSubcategory = 'All';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _canPop() => context.canPop();

  Future<void> _navigateToCreateProduct() async {
    HapticFeedback.mediumImpact();
    ref.read(productFormNotifierProvider.notifier).reset();
    await context.push('/stock/create');
    if (!mounted) return;
    ref.invalidate(productsProvider);
    ref.invalidate(paginatedProductsProvider);
    ref.invalidate(expiredBatchesProvider);
  }

  Future<void> _navigateToCreateService() async {
    HapticFeedback.mediumImpact();
    await context.push('/stock/create-service');
    if (!mounted) return;
    ref.invalidate(productsProvider);
    ref.invalidate(paginatedProductsProvider);
    ref.invalidate(expiredBatchesProvider);
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
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 90.0 + MediaQuery.of(context).padding.bottom),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (_tabController.index == 0 ? AppTheme.primaryColor : Colors.teal.shade600).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            heroTag: 'inventory_add_fab',
            onPressed: _tabController.index == 0 ? _navigateToCreateProduct : _navigateToCreateService,
            label: Text(
              _tabController.index == 0 ? 'Add Product' : 'Add Service',
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            icon: Icon(_tabController.index == 0 ? Icons.add_business_rounded : Icons.home_repair_service_rounded, size: 24),
            backgroundColor: _tabController.index == 0 ? AppTheme.primaryColor : Colors.teal.shade600,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
      body: productsAsync.when(
        data: (products) {
          final filtered = products
              .where(
                (p) =>
                    (_tabController.index == 0 ? !p.isService : p.isService) &&
                    (_searchQuery.isEmpty ||
                     p.name.toLowerCase().contains(_searchQuery) ||
                     (p.brand?.toLowerCase().contains(_searchQuery) ?? false) ||
                     p.sku.toLowerCase().contains(_searchQuery)) &&
                    (_selectedCategory == 'All' || p.category == _selectedCategory) &&
                    (_tabController.index == 1 || _selectedSubcategory == 'All' || p.subcategory == _selectedSubcategory),
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
            color: _tabController.index == 0 ? AppTheme.primaryColor : Colors.teal.shade600,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 330.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: _tabController.index == 0 ? AppTheme.primaryColor : Colors.teal.shade600,
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
                    if (_tabController.index == 0) ...[
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
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            final status = await Permission.camera.request();
                            if (status.isGranted && context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BatchScanScreen(),
                                ),
                              );
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Camera permission required to scan'),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              );
                            }
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
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _tabController.index == 0
                              ? [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryLight,
                                ]
                              : [
                                  Colors.teal.shade700,
                                  Colors.teal.shade500,
                                ],
                        ),
                      ),
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 40,
                        left: 20,
                        right: 20,
                        bottom: 165,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [_buildStatsHeader(products, expiredCount)],
                      ),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(140.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 48,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.slate100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                color: _tabController.index == 0 ? AppTheme.primaryColor : Colors.teal.shade600,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_tabController.index == 0 ? AppTheme.primaryColor : Colors.teal.shade600).withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: AppTheme.textSecondary,
                              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              tabs: const [
                                Tab(text: 'Products'),
                                Tab(text: 'Services'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            autofocus: false,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            cursorColor: _tabController.index == 0 ? AppTheme.primaryColor : Colors.teal.shade600,
                            decoration: InputDecoration(
                              hintText: _tabController.index == 0 ? 'Search products...' : 'Search services...',
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: _tabController.index == 0 ? AppTheme.primaryColor : Colors.teal.shade600,
                                size: 22,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (v) =>
                                setState(() => _searchQuery = v.toLowerCase()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Category & Subcategory Pills
                if (_tabController.index == 0)
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
                if (_tabController.index == 1)
                  SliverToBoxAdapter(
                    child: Container(
                      color: AppTheme.backgroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    context.push('/staff');
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.teal.shade700, Colors.teal.shade500],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.teal.withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.people_alt_rounded, color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Manage Staff',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    context.push('/service-categories');
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.teal.shade600, width: 1.5),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.category_rounded, color: Colors.teal.shade700, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Categories',
                                          style: TextStyle(
                                            color: Colors.teal.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'CATEGORIES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: AppTheme.slate500,
                            ),
                          ),
                          _buildServiceCategoryPills(ref),
                          const SizedBox(height: 4),
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
                              (context, index) => RepaintBoundary(
                                child: _InventoryItemPill(
                                  product: filtered[index],
                                  onAddStock: () =>
                                      _showAddStockSheet(context, filtered[index]),
                                )
                                    .animate(key: ValueKey(filtered[index].id))
                                    .fadeIn(duration: 200.ms, delay: (index * 25).ms)
                                    .slideY(begin: 0.04, curve: Curves.easeOut),
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
        loading: () => const ShimmerList(),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      ),
    );
  }

  Widget _buildStatsHeader(List<Product> products, int expiredCount) {
    if (_tabController.index == 0) {
      final totalValue = products.where((p) => !p.isService).fold<double>(0, (sum, p) => sum + (p.quantity * p.price));
      final lowStockCount = products.where((p) => !p.isService && p.quantity < 10 && p.quantity > 0).length;
      return Row(
        children: [
          Expanded(
            child: _StatBox(
              label: 'Inventory Value',
              value: '₹${_compactFmt.format(totalValue)}',
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
    } else {
      final activeServicesCount = products.where((p) => p.isService).length;
      final staffListAsync = ref.watch(staffListProvider);
      final staffCount = staffListAsync.asData?.value.length ?? 0;
      final shopType = ref.watch(shopTypeProvider);
      final categoriesAsync = ref.watch(serviceCategoriesProvider(shopType.name));
      final categoryCount = categoriesAsync.asData?.value.length ?? 0;
      return Row(
        children: [
          Expanded(
            child: _StatBox(
              label: 'Active Services',
              value: '$activeServicesCount',
              icon: Icons.home_repair_service_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatBox(
              label: 'Staff Count',
              value: '$staffCount',
              icon: Icons.people_alt_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatBox(
              label: 'Categories',
              value: '$categoryCount',
              icon: Icons.category_rounded,
            ),
          ),
        ],
      );
    }
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

  Widget _buildServiceCategoryPills(WidgetRef ref) {
    final shopType = ref.watch(shopTypeProvider);
    final categoriesAsync = ref.watch(serviceCategoriesProvider(shopType.name));
    return categoriesAsync.when(
      data: (categories) {
        final allCategoryNames = ['All', ...categories.map((c) => c.name)];
        return Container(
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: allCategoryNames.length,
            itemBuilder: (context, index) {
              final cat = allCategoryNames[index];
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
                  selectedColor: Colors.teal.withValues(alpha: 0.15),
                  checkmarkColor: Colors.teal.shade700,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.teal.shade700 : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? Colors.teal.shade600 : AppTheme.slate200),
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
      context.push('/stock/edit', extra: product);
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
