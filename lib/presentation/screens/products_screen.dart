import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';

import 'package:orushops/core/models/cart_item.dart';
import 'package:orushops/core/models/product.dart';
import 'package:orushops/core/models/product_variant.dart';
import 'package:orushops/core/repositories/variant_repository.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/core/utils/currency_formatter.dart';
import 'package:orushops/providers/products_provider.dart';
import 'package:orushops/providers/cart_provider.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';
import 'package:orushops/providers/held_carts_provider.dart';
import 'package:orushops/core/models/customer.dart';
import 'package:orushops/providers/checkout_provider.dart';
import 'package:orushops/providers/sale_provider.dart' show customerRepositoryProvider;
import 'package:orushops/core/repositories/owner_provider.dart';

import 'sales_history_screen.dart';
import 'receipt_screen.dart';

part 'products/product_grid_card.dart';
part 'products/product_grid_card_actions.dart';
part 'products/product_grid_card_image.dart';
part 'products/checkout_sheet.dart';
part 'products/checkout_customer_dialog.dart';
part 'products/cart_step.dart';
part 'products/sheet_cart_item.dart';
part 'products/step_btn.dart';
part 'products/checkout_step.dart';
part 'products/qty_input_sheet.dart';
part 'products/qr_scanner_modal.dart';
part 'products/variant_picker_sheet.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late ScrollController _scrollController;
  final Set<int> _recentlyAddedIds = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paginatedProductsProvider.notifier).reset();
      ref.invalidate(productCategoriesProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(paginatedProductsProvider.notifier).loadMore();
    }
  }

  Future<void> _addToCart(
    Product product, {
    double qty = 1.0,
    int? variantId,
    String variantLabel = '',
    double? unitPrice,
  }) async {
    HapticFeedback.mediumImpact();

    final effectivePrice = unitPrice ?? product.price.toDouble();

    final cartItems = ref.read(cartProvider);
    // For variant items check stock against the specific variant already in cart
    final currentInCart = cartItems
        .where((i) => i.productId == product.id && i.variantId == variantId)
        .fold(0.0, (sum, i) => sum + i.quantity);

    if (!product.isService && variantId == null && currentInCart + qty > product.displayQuantity) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only ${product.displayQuantity} ${product.unit} of "${product.name}" available'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    ref.read(cartProvider.notifier).addItem(CartItem(
      productId: product.id,
      productName: product.name,
      quantity: qty,
      unitPrice: effectivePrice,
      selectedBatchIds: [],
      variantId: variantId,
      variantLabel: variantLabel,
    ));

    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _recentlyAddedIds.add(product.id));
    Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _recentlyAddedIds.remove(product.id));
    });
  }

  Future<void> _addVariantToCart(Product product) async {
    final picked = await showModalBottomSheet<_VariantSelection>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VariantPickerSheet(product: product),
    );
    if (picked == null) return;
    await _addToCart(
      product,
      qty: picked.qty,
      variantId: picked.variantId,
      variantLabel: picked.label,
      unitPrice: picked.price,
    );
  }

  Future<void> _addLooseToCart(Product product) async {
    await _showQtyBottomSheet(product);
  }

  Future<void> _showQtyBottomSheet(Product product) async {
    final double maxQty = product.isService ? double.infinity : product.displayQuantity;
    final alreadyInCart = ref.read(cartProvider)
        .where((i) => i.productId == product.id)
        .fold(0.0, (sum, i) => sum + i.quantity);
    final double remaining = product.isService ? double.infinity : (maxQty - alreadyInCart);

    final result = await showModalBottomSheet<double>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QtyInputSheet(
        product: product,
        remaining: remaining,
      ),
    );
    if (result == null || result <= 0) return;
    await _addToCart(product, qty: result);
  }

  void _openQRScanner() {
    final products = ref.read(paginatedProductsProvider);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QRScannerModal(
        products: products,
        onProductScanned: (product) async {
          await _addToCart(product, qty: 1);
        },
      ),
    );
  }

  void _showHeldCartsDialog(BuildContext context, WidgetRef ref) {
    final heldCarts = ref.watch(heldCartsProvider);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Paused Sales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
                  ),
                  child: const Text('View History'),
                ),
              ],
            ),
          ),
          if (heldCarts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('No paused sales'),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: heldCarts.length,
                itemBuilder: (context, index) {
                  final cart = heldCarts[index];
                  final total = cart.items.fold<double>(0, (sum, item) => sum + (item.unitPrice * item.quantity));
                  
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Icon(Icons.pause, color: Colors.white),
                    ),
                    title: Text('Sale from ${DateFormat('MMM d, HH:mm').format(cart.createdAt)}'),
                    subtitle: Text('${cart.items.length} items • ₹${total.toStringAsFixed(2)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final items = await ref.read(heldCartsProvider.notifier).recallCart(cart.id);
                      ref.read(cartProvider.notifier).clearCart();
                      
                      int adjustedCount = 0;
                      int removedCount = 0;
                      
                      for (final item in items) {
                        try {
                          final product = await ref.read(productByIdProvider(item.productId).future);
                          if (product == null) {
                            removedCount++;
                            continue;
                          }
                          
                          double finalQty = item.quantity;
                          if (finalQty > product.displayQuantity) {
                            finalQty = product.displayQuantity;
                            adjustedCount++;
                          }
                          
                          if (finalQty > 0) {
                            ref.read(cartProvider.notifier).addItem(item.copyWith(quantity: finalQty));
                          } else {
                            removedCount++;
                          }
                        } catch (_) {
                          // Product might have been deleted
                          removedCount++;
                        }
                      }
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        String message = 'Sale resumed';
                        if (adjustedCount > 0 || removedCount > 0) {
                          List<String> details = [];
                          if (adjustedCount > 0) details.add('$adjustedCount adjusted');
                          if (removedCount > 0) details.add('$removedCount removed');
                          message += ' (${details.join(', ')} due to stock)';
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor: (adjustedCount > 0 || removedCount > 0) ? AppTheme.warningColor : AppTheme.primaryColor,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(filteredProductsProvider);
    final cartTotal = ref.watch(cartSubtotalProvider);
    final cartCount = ref.watch(cartTotalQuantityProvider);
    final searchQuery = ref.watch(productSearchQueryProvider);
    // Removed unused selectedCategory

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      bottomNavigationBar: _buildSummaryBar(cartTotal, cartCount),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await ref.read(paginatedProductsProvider.notifier).reset();
          ref.invalidate(productCategoriesProvider);
        },
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Hideable Header & Pinned Search Bar
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: true,
              backgroundColor: AppTheme.backgroundColor,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              toolbarHeight: 76,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    // Search Bar
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.fromLTRB(16, 0, 10, 0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryDark.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: AppTheme.slate400, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                autofocus: false,
                                style: const TextStyle(fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Search products...',
                                  hintStyle: TextStyle(color: AppTheme.slate400, fontSize: 15, fontWeight: FontWeight.w400),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                onChanged: (value) => ref.read(productSearchQueryProvider.notifier).state = value,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Scan Button
                    GestureDetector(
                      onTap: _openQRScanner,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryDark.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.qr_code_scanner, size: 20, color: AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // History / Paused Button
                    Consumer(
                      builder: (context, ref, child) {
                        final heldCarts = ref.watch(heldCartsProvider);
                        final hasHeldCarts = heldCarts.isNotEmpty;
                        
                        return GestureDetector(
                          onTap: () {
                            if (hasHeldCarts) {
                              _showHeldCartsDialog(context, ref);
                            } else {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesHistoryScreen()));
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: hasHeldCarts ? AppTheme.primaryColor : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (hasHeldCarts ? AppTheme.primaryColor : AppTheme.primaryDark).withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.history_rounded, 
                                  size: 22, 
                                  color: hasHeldCarts ? Colors.white : AppTheme.primaryColor
                                ),
                                if (hasHeldCarts)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.errorColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // 2. Dynamic Category Chips
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildCategorySelector(ref),
                  _buildSubcategorySelector(ref),
                ],
              ),
            ),

            // 3. Product List
            SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                sliver: Builder(
                  builder: (context) {
                    if (products.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(searchQuery),
                      );
                    }

                    return SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.88,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];
                          final isRecentlyAdded = _recentlyAddedIds.contains(product.id);

                          return _ProductGridCard(
                            product: product,
                            isRecentlyAdded: isRecentlyAdded,
                            onAdd: (qty) => _addToCart(product, qty: qty),
                            onAddLoose: _addLooseToCart,
                            onAddVariant: () => _addVariantToCart(product),
                          );
                        },
                        childCount: products.length,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(WidgetRef ref) {
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final selectedCategory = ref.watch(productCategoryProvider);
    
    return categoriesAsync.when(
      data: (categories) {
        final allCategories = ['All', ...categories];
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allCategories.length,
              itemBuilder: (context, index) {
                final cat = allCategories[index];
                final isSelected = selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(productCategoryProvider.notifier).state = cat;
                    ref.read(productSubcategoryProvider.notifier).state = 'All';
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.slate200,
                        width: 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 36),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildSubcategorySelector(WidgetRef ref) {
    final selectedCategory = ref.watch(productCategoryProvider);
    if (selectedCategory == 'All') return const SizedBox.shrink();

    final categoriesAsync = ref.watch(shopCategoriesProvider);
    final selectedSubcategory = ref.watch(productSubcategoryProvider);

    return categoriesAsync.when(
      data: (categories) {
        final categoryObj = categories.firstWhere(
          (c) => c.name == selectedCategory,
          orElse: () => categories.first,
        );

        if (categoryObj.subcategories.isEmpty) return const SizedBox.shrink();

        final allSubcats = ['All', ...categoryObj.subcategories];

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: SizedBox(
            height: 28,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allSubcats.length,
              itemBuilder: (context, index) {
                final subcat = allSubcats[index];
                final isSelected = selectedSubcategory == subcat;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(productSubcategoryProvider.notifier).state = subcat;
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.5) : AppTheme.slate300,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      subcat,
                      style: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 28),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(String searchQuery) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppTheme.slate400),
          const SizedBox(height: 16),
          Text(
            'No products found matching "$searchQuery"',
            style: TextStyle(color: AppTheme.slate600),
          ),
          TextButton(
            onPressed: () {
              _searchController.clear();
              ref.read(productSearchQueryProvider.notifier).state = '';
            },
            child: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }

  void _showCheckoutSheet({String initialStep = 'cart'}) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CheckoutSheet(initialStep: initialStep),
    );
  }

  void _showMiniCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final cartItems = ref.watch(cartProvider);
            if (cartItems.isEmpty) {
              Future.microtask(() {
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
              });
              return const SizedBox.shrink();
            }
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quick Look',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: cartItems.length,
                        separatorBuilder: (context, index) => const Divider(height: 24, color: Color(0xFFF0F4F8)),
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: AppTheme.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '${item.quantity}x',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          CurrencyFormatter.format(item.unitPrice.toDouble()),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format((item.unitPrice * item.quantity).toDouble()),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      ref.read(cartProvider.notifier).removeItem(item.productId);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Remove',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.errorColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryBar(double total, double count) {
    if (count == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _showMiniCartBottomSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryDark.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref.read(cartProvider.notifier).clearCart();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: AppTheme.errorColor, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${count == count.truncateToDouble() ? count.toInt() : count.toStringAsFixed(2)} Items',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(total.toDouble()),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showCheckoutSheet(initialStep: 'cart'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text(
                  'View Items',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _showCheckoutSheet(initialStep: 'checkout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Checkout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
