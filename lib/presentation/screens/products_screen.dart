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
import 'package:orushops/providers/auth_provider.dart';
import 'package:orushops/providers/held_carts_provider.dart';
import 'package:orushops/core/models/customer.dart';
import 'package:orushops/providers/checkout_provider.dart';
import 'package:orushops/providers/sale_provider.dart' show customerRepositoryProvider;
import 'package:orushops/core/repositories/owner_provider.dart';

import 'profile_screen.dart';
import 'sales_history_screen.dart';
import 'receipt_screen.dart';

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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QRScannerModal(
        products: products,
        onScanned: (sku) {
          _searchController.text = sku;
          ref.read(productSearchQueryProvider.notifier).state = sku.toLowerCase();
        },
      ),
    );
  }

  void _showHeldCartsDialog(BuildContext context, WidgetRef ref) {
    final heldCarts = ref.watch(heldCartsProvider);

    showModalBottomSheet(
      context: context,
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
              toolbarHeight: 68,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                      child: Container(
                        width: 38,
                        height: 38,
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
                        child: Consumer(
                          builder: (context, ref, child) {
                            final user = ref.watch(currentUserProvider);
                            if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
                              return ClipOval(child: Image.network(user.photoURL!, fit: BoxFit.cover));
                            }
                            return const Icon(Icons.person_outline_rounded, color: AppTheme.textPrimary, size: 24);
                          },
                        ),
                      ),
                    ),
                    Image.asset(
                      'images/logo.png',
                      height: 32,
                      fit: BoxFit.contain,
                    ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: hasHeldCarts ? AppTheme.primaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: (hasHeldCarts ? AppTheme.primaryColor : AppTheme.primaryDark).withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              hasHeldCarts ? 'Paused (${heldCarts.length})' : 'History',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: hasHeldCarts ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(104),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.fromLTRB(20, 0, 10, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppTheme.slate400, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            autofocus: false, // Explicitly disable autofocus
                            style: const TextStyle(fontSize: 17),
                            decoration: InputDecoration(
                              hintText: 'Search products by name...',
                              hintStyle: TextStyle(color: AppTheme.slate400, fontSize: 17, fontWeight: FontWeight.w400),
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
                        GestureDetector(
                          onTap: _openQRScanner,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.qr_code_scanner, size: 22, color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
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
            height: 48,
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
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(24),
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
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 48),
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
            height: 36,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
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
                        fontSize: 12,
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CheckoutSheet(initialStep: initialStep),
    );
  }

  void _showMiniCartBottomSheet() {
    showModalBottomSheet(
      context: context,
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

class _ProductGridCard extends ConsumerStatefulWidget {
  final Product product;
  final bool isRecentlyAdded;
  final void Function(double qty) onAdd;
  final Future<void> Function(Product) onAddLoose;
  final Future<void> Function() onAddVariant;

  const _ProductGridCard({
    required this.product,
    required this.isRecentlyAdded,
    required this.onAdd,
    required this.onAddLoose,
    required this.onAddVariant,
  });

  @override
  ConsumerState<_ProductGridCard> createState() => _ProductGridCardState();
}

class _ProductGridCardState extends ConsumerState<_ProductGridCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _showQuantityPicker() async {
    await widget.onAddLoose(widget.product);
  }

  void _addWithAnimation(double qty) {
    widget.onAdd(qty);
    _animationController.forward().then((_) => _animationController.reverse());
  }

  Future<void> _addOne() async {
    if (widget.product.isLoose) {
      widget.onAddLoose(widget.product);
      return;
    }

    final variants = await VariantRepository().getByProduct(widget.product.id);
    if (!mounted) return;
    if (variants.isNotEmpty) {
      await widget.onAddVariant();
      return;
    }

    final currentCartQty = ref.read(cartProvider)
        .where((i) => i.productId == widget.product.id)
        .fold(0.0, (sum, i) => sum + i.quantity);

    if (!widget.product.isService && currentCartQty >= widget.product.displayQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient stock for ${widget.product.name}'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    _addWithAnimation(1.0);
  }

  Future<void> _decrement() async {
    final cartItems = ref.read(cartProvider)
        .where((i) => i.productId == widget.product.id)
        .toList();

    if (cartItems.isEmpty) return;

    HapticFeedback.mediumImpact();

    final currentQty = cartItems.fold(0.0, (sum, i) => sum + i.quantity);
    final double step = widget.product.isLoose ? 0.1 : 1.0;
    final double nextQty = currentQty - step;

    if (nextQty <= 0.05) {
      ref.read(cartProvider.notifier).updateQuantity(widget.product.id, 0.0);
    } else {
      final double roundedQty = double.parse(nextQty.toStringAsFixed(2));
      ref.read(cartProvider.notifier).updateQuantity(widget.product.id, roundedQty);
    }
  }

  Future<void> _increment() async {
    final variants = await VariantRepository().getByProduct(widget.product.id);
    if (!mounted) return;
    if (variants.isNotEmpty) {
      await widget.onAddVariant();
      return;
    }

    final cartItems = ref.read(cartProvider)
        .where((i) => i.productId == widget.product.id)
        .toList();

    final currentQty = cartItems.fold(0.0, (sum, i) => sum + i.quantity);
    final double step = widget.product.isLoose ? 0.1 : 1.0;
    final double nextQty = currentQty + step;

    if (!widget.product.isService && nextQty > widget.product.displayQuantity) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only ${widget.product.displayQuantity} available in stock'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final double roundedQty = double.parse(nextQty.toStringAsFixed(2));
    ref.read(cartProvider.notifier).updateQuantity(widget.product.id, roundedQty);
  }

  Widget _buildMiniTags(Product product, List<ShopCategory> categories) {
    final category = categories.firstWhere(
      (c) => c.name == product.category,
      orElse: () => ShopCategory(name: product.category, productFields: ProductFieldConfig.basic()),
    );
    final fields = category.productFields;
    final List<String> tagValues = [];

    if (fields.hasBrand && product.brand != null && product.brand!.isNotEmpty) {
      tagValues.add(product.brand!);
    }
    if (fields.hasWeight && product.weight != null && product.weight!.isNotEmpty) {
      tagValues.add(product.weight!);
    }
    if (fields.hasSizeVariant && product.size != null && product.size!.isNotEmpty) {
      tagValues.add(product.size!);
    }
    if (fields.hasColorVariant && product.color != null && product.color!.isNotEmpty) {
      tagValues.add(product.color!);
    }

    if (tagValues.isEmpty) return const SizedBox.shrink();

    return Text(
      tagValues.join(' • '),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary.withValues(alpha: 0.5),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartQty = cartItems
        .where((i) => i.productId == widget.product.id)
        .fold(0.0, (sum, i) => sum + i.quantity);

    final shopCategories = ref.watch(shopCategoriesProvider).maybeWhen(
      data: (cats) => cats,
      orElse: () => <ShopCategory>[],
    );

    final bool inCart = cartQty > 0;
    final bool outOfStock = !widget.product.isService && widget.product.displayQuantity <= 0;
    final bool lowStock = !widget.product.isService && widget.product.displayQuantity > 0 && widget.product.displayQuantity <= 5;

    final String qtyDisplay = widget.product.isLoose 
        ? '${cartQty.toStringAsFixed(2)} ${widget.product.unit}'
        : '${cartQty.toInt()}';

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: outOfStock ? null : () async {
          HapticFeedback.lightImpact();
          if (inCart) {
            _showQuantityPicker();
          } else {
            await _addOne();
          }
        },
        onLongPress: outOfStock ? null : () {
          HapticFeedback.mediumImpact();
          _showQuantityPicker();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: inCart
                  ? AppTheme.accentColor.withValues(alpha: 0.6)
                  : AppTheme.slate200.withValues(alpha: 0.5),
              width: inCart ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: inCart 
                    ? AppTheme.accentColor.withValues(alpha: 0.12) 
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: inCart ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Beautiful Compact Image Wrapper (No longer oversized)
              Stack(
                children: [
                  Container(
                    height: 85,
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.slate50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'product_image_${widget.product.id}',
                            child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
                                ? Image.network(
                                    widget.product.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                                  )
                                : widget.product.imagePath != null && widget.product.imagePath!.isNotEmpty
                                    ? Image.file(
                                        File(widget.product.imagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                                      )
                                    : _buildPlaceholderIcon(),
                          ),
                          if (outOfStock)
                            Container(
                              color: Colors.black.withValues(alpha: 0.4),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'SOLD OUT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Active Quantity Overlay (Top Left)
                  if (inCart)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentColor.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              qtyDisplay,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Loose/Service or New Indicators (Top Right)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.product.isLoose)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.scale_rounded,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        if (widget.product.isService)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.room_service_rounded,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        if (widget.isRecentlyAdded && !inCart) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // 2. Product Details with Beautiful Compact Spacing
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Product Name & Mini-Tags Block
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _buildMiniTags(widget.product, shopCategories),
                              ),
                              if (lowStock)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${widget.product.displayQuantity.toInt()} left',
                                    style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.errorColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Price Block (Price, MRP, and discount percentage)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  CurrencyFormatter.format(widget.product.price.toDouble()),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                                if (widget.product.mrp != null && widget.product.mrp! > widget.product.price) ...[
                                  const SizedBox(height: 1),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        CurrencyFormatter.format(widget.product.mrp!.toDouble()),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: AppTheme.textSecondary.withValues(alpha: 0.4),
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(((widget.product.mrp! - widget.product.price) / widget.product.mrp!) * 100).toInt()}% OFF',
                                        style: const TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.successColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Action Button or Quantity Selector
                      SizedBox(
                        height: 28,
                        child: outOfStock
                            ? Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.slate100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'Unavailable',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary.withValues(alpha: 0.4),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              )
                            : !inCart
                                ? ElevatedButton(
                                    onPressed: () async {
                                      HapticFeedback.mediumImpact();
                                      await _addOne();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_rounded, size: 14),
                                        SizedBox(width: 2),
                                        Text(
                                          'ADD',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.accentColor.withValues(alpha: 0.3),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: _decrement,
                                          behavior: HitTestBehavior.opaque,
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentColor.withValues(alpha: 0.05),
                                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                                            ),
                                            child: const Icon(
                                              Icons.remove_rounded,
                                              color: AppTheme.accentColor,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: _showQuantityPicker,
                                            behavior: HitTestBehavior.opaque,
                                            child: Center(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    widget.product.isLoose
                                                        ? cartQty.toStringAsFixed(2)
                                                        : '${cartQty.toInt()}',
                                                    style: const TextStyle(
                                                      color: AppTheme.accentColor,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                  if (widget.product.isLoose) ...[
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      widget.product.unit,
                                                      style: const TextStyle(
                                                        color: AppTheme.accentColor,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _increment,
                                          behavior: HitTestBehavior.opaque,
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentColor.withValues(alpha: 0.05),
                                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                                            ),
                                            child: const Icon(
                                              Icons.add_rounded,
                                              color: AppTheme.accentColor,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    final int hash = widget.product.category.hashCode;
    final List<Color> gradients = [
      [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
      [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
      [const Color(0xFFFAF5FF), const Color(0xFFF3E8FF)],
      [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)],
    ][hash.abs() % 4];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradients,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 28,
              color: AppTheme.primaryColor.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 4),
            Text(
              widget.product.category.toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryColor.withValues(alpha: 0.45),
                letterSpacing: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Unified Checkout Sheet ────────────────────────────────────────────────────

class _CheckoutSheet extends ConsumerStatefulWidget {
  final String initialStep;
  const _CheckoutSheet({this.initialStep = 'cart'});

  @override
  ConsumerState<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<_CheckoutSheet> {
  late String _step; // 'cart' | 'checkout'
  String? _selectedPaymentMethod;
  String? _customerPhone;
  String? _customerName;
  double _quickDiscount = 0;
  double _amountPaid = 0;
  String _receivedPaymentMode = 'Cash';


  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
  }

  Future<void> _processSale(double subtotal, List<CartItem> items) async {
    final finalAmount = subtotal - _quickDiscount;

    // MANDATORY: Customer validation before sale
    if (_customerPhone == null || _customerPhone!.trim().length < 10) {
      HapticFeedback.heavyImpact();
      _showCustomerDialog(() => _processSale(subtotal, items));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer mobile number is required to proceed'),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final checkoutState = ref.read(checkoutProvider);
    if (checkoutState.isLoading) return;

    // Unfocus keyboard before processing to avoid IME layout issues and warnings
    FocusScope.of(context).unfocus();

    final success = await ref.read(checkoutProvider.notifier).saveSale(
      items: items,
      subtotal: subtotal,
      discountAmount: _quickDiscount,
      finalAmount: finalAmount,
      paymentMethod: _selectedPaymentMethod!,
      selectedBatches: {},
      customerPhone: _customerPhone,
      customerName: _customerName,
      amountPaid: _selectedPaymentMethod == 'Khata' ? _amountPaid : null,
      receivedPaymentMode: _selectedPaymentMethod == 'Khata' ? _receivedPaymentMode : null,
    );

    if (!mounted) return;

    if (success != null) {
      HapticFeedback.heavyImpact();
      // Note: analytics revision and stock decrement are now handled globally in checkoutProvider
      ref.read(productSearchQueryProvider.notifier).state = '';
      ref.read(cartProvider.notifier).clearCart();

      Map<String, dynamic>? ownerDetails;
      try {
        ownerDetails = await ref.read(ownerDetailsProvider.future);
      } catch (_) {
        ownerDetails = null;
      }
      if (!mounted) return;
      Navigator.pop(context); // close sheet
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            sale: success['sale'],
            items: success['items'],
            storeName: ownerDetails?['storeName'] as String?,
            storePhone: ownerDetails?['phoneNumber'] as String?,
            storeAddress: ownerDetails?['address'] as String?,
            upiId: ownerDetails?['upiId'] as String?,
          ),
        ),
      );
    } else {
      final error = ref.read(checkoutProvider).error;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to save sale'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showCustomerDialog(VoidCallback onSaved) {
    final phoneCtrl = TextEditingController(text: _customerPhone);
    final nameCtrl = TextEditingController(text: _customerName);
    final customerRepo = ref.read(customerRepositoryProvider);
    final phoneFocusNode = FocusNode();
    List<Customer> suggestions = [];

    Future.delayed(const Duration(milliseconds: 350), () {
      if (phoneFocusNode.canRequestFocus) {
        phoneFocusNode.requestFocus();
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            left: 24,
            right: 24,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person_add_rounded, color: AppTheme.primaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Lookup',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                        Text(
                          'Search existing or add new customer',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ),
                ],
              ),
              const Text(
                'PHONE NUMBER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.slate500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                focusNode: phoneFocusNode,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: 1.5),
                decoration: InputDecoration(
                  hintText: '00000 00000',
                  hintStyle: TextStyle(color: AppTheme.slate300, letterSpacing: 1.5),
                  prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppTheme.primaryColor),
                  prefixText: '+91 ',
                  prefixStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w900, fontSize: 18),
                  filled: true,
                  fillColor: AppTheme.slate50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (val) async {
                  if (val.length >= 3) {
                    final results = await customerRepo.searchByQuery(val);
                    setD(() => suggestions = results);
                  } else {
                    setD(() => suggestions = []);
                  }
                },
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuart,
                constraints: BoxConstraints(
                  maxHeight: suggestions.isEmpty ? 0 : 200,
                ),
                child: suggestions.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 180),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: suggestions.length,
                              separatorBuilder: (_, _) => Padding(
                                padding: const EdgeInsets.only(left: 56),
                                child: Divider(height: 1, thickness: 1, color: AppTheme.slate100),
                              ),
                              itemBuilder: (ctx, i) {
                                final c = suggestions[i];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                  dense: true,
                                  leading: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppTheme.primaryColor.withValues(alpha: 0.1), AppTheme.primaryColor.withValues(alpha: 0.05)],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    c.name, 
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.slate900),
                                  ),
                                  subtitle: Text(
                                    c.phone, 
                                    style: const TextStyle(fontSize: 11, color: AppTheme.slate500, fontWeight: FontWeight.w600),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.slate300),
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    setD(() {
                                      String p = c.phone.replaceAll(RegExp(r'\D'), '');
                                      if (p.length > 10 && p.startsWith('91')) p = p.substring(2);
                                      phoneCtrl.text = p;
                                      nameCtrl.text = c.name;
                                      suggestions = [];
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 16),
              const Text(
                'CUSTOMER NAME (OPTIONAL)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.slate500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'John Doe',
                  hintStyle: TextStyle(color: AppTheme.slate300),
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.slate400),
                  filled: true,
                  fillColor: AppTheme.slate50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                textCapitalization: TextCapitalization.words,
              ),
              if (MediaQuery.of(ctx).viewInsets.bottom == 0) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      String phone = phoneCtrl.text.trim();
                      final name = nameCtrl.text.trim();

                      phone = phone.replaceAll(RegExp(r'\D'), '');
                      if (phone.length == 12 && phone.startsWith('91')) {
                        phone = phone.substring(2);
                      }

                      if (phone.length != 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid 10-digit mobile number'),
                            backgroundColor: AppTheme.errorColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _customerPhone = phone;
                        _customerName = name.isEmpty ? null : name;
                      });
                      Navigator.pop(context);
                      onSaved();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 8,
                      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('PROCEED TO PAYMENT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        SizedBox(width: 12),
                        Icon(Icons.arrow_forward_ios_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final isLoading = ref.watch(checkoutProvider).isLoading;
    final finalAmount = subtotal - _quickDiscount;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),

          // Header row with step indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
            child: Row(
              children: [
                if (_step == 'checkout')
                  GestureDetector(
                    onTap: () => setState(() => _step = 'cart'),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
                    ),
                  ),
                Text(
                  _step == 'cart' ? 'Cart  (${cartItems.length} items)' : 'Checkout',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          // Body — animated step switch
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(
                  begin: _step == 'checkout'
                      ? const Offset(1, 0)
                      : const Offset(-1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: _step == 'cart'
                  ? _CartStep(
                      key: const ValueKey('cart'),
                      cartItems: cartItems,
                      onProceed: () => setState(() => _step = 'checkout'),
                      bottomPad: bottomPad,
                    )
                  : _CheckoutStep(
                      key: const ValueKey('checkout'),
                      cartItems: cartItems,
                      subtotal: subtotal,
                      finalAmount: finalAmount,
                      isLoading: isLoading,
                      quickDiscount: _quickDiscount,
                      selectedPaymentMethod: _selectedPaymentMethod,
                      customerName: _customerName,
                      customerPhone: _customerPhone,
                      receivedPaymentMode: _receivedPaymentMode,
                      amountPaid: _amountPaid,
                      bottomPad: bottomPad,
                      onDiscountChanged: (v) => setState(() => _quickDiscount = v),
                      onPaymentSelected: (method) {
                        setState(() => _selectedPaymentMethod = method);
                        _showCustomerDialog(() {
                          if (_selectedPaymentMethod != null) {
                            _processSale(subtotal, cartItems);
                          }
                        });
                      },
                      onConfirm: () => _processSale(subtotal, cartItems),
                      onAmountPaidChanged: (v) => setState(() => _amountPaid = v),
                      onReceivedModeChanged: (v) => setState(() => _receivedPaymentMode = v),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cart Step ─────────────────────────────────────────────────────────────────

class _CartStep extends ConsumerWidget {
  final List<CartItem> cartItems;
  final VoidCallback onProceed;
  final double bottomPad;

  const _CartStep({
    super.key,
    required this.cartItems,
    required this.onProceed,
    required this.bottomPad,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cartItems.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 48, color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              const SizedBox(height: 12),
              const Text('Cart is empty', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Item list
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: cartItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _SheetCartItem(item: cartItems[i]),
          ),
        ),

        // Total + Proceed button
        Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.5))),
          ),
          child: Row(
            children: [
              Consumer(
                builder: (_, ref, _) {
                  final subtotal = ref.watch(cartSubtotalProvider);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Subtotal', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                      Text(
                        '₹${subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.5),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onProceed,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Proceed to Checkout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Cart Item Row inside sheet ─────────────────────────────────────────────────

class _SheetCartItem extends ConsumerWidget {
  final CartItem item;
  const _SheetCartItem({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartNotifier = ref.read(cartProvider.notifier);
    final maxStock = ref.watch(productByIdProvider(item.productId)).value?.displayQuantity ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${item.unitPrice.toStringAsFixed(0)} / unit',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Qty stepper
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepBtn(
                icon: item.quantity <= 1 ? Icons.delete_outline_rounded : Icons.remove,
                color: item.quantity <= 1 ? AppTheme.errorColor : AppTheme.textPrimary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (item.quantity <= 1) {
                    cartNotifier.removeItem(item.productId);
                  } else {
                    cartNotifier.updateQuantity(item.productId, item.quantity - 1);
                  }
                },
              ),
              SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    item.quantity == item.quantity.truncateToDouble()
                        ? '${item.quantity.toInt()}'
                        : item.quantity.toStringAsFixed(2),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              _StepBtn(
                icon: Icons.add,
                color: item.quantity < maxStock ? AppTheme.primaryColor : AppTheme.textSecondary,
                onTap: item.quantity < maxStock
                    ? () {
                        HapticFeedback.lightImpact();
                        cartNotifier.updateQuantity(item.productId, item.quantity + 1);
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(width: 10),
          Text(
            '₹${item.totalPrice.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: onTap != null ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: onTap != null
              ? [BoxShadow(color: AppTheme.primaryDark.withValues(alpha: 0.06), blurRadius: 4)]
              : null,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Checkout Step ─────────────────────────────────────────────────────────────

class _CheckoutStep extends StatelessWidget {
  final List<CartItem> cartItems;
  final double subtotal;
  final double finalAmount;
  final bool isLoading;
  final double quickDiscount;
  final String? selectedPaymentMethod;
  final String? customerName;
  final String? customerPhone;
  final String receivedPaymentMode;
  final double amountPaid;
  final double bottomPad;
  final ValueChanged<double> onDiscountChanged;
  final ValueChanged<String> onPaymentSelected;
  final VoidCallback onConfirm;
  final ValueChanged<double> onAmountPaidChanged;
  final ValueChanged<String> onReceivedModeChanged;

  const _CheckoutStep({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.finalAmount,
    required this.isLoading,
    required this.quickDiscount,
    required this.selectedPaymentMethod,
    required this.customerName,
    required this.customerPhone,
    required this.receivedPaymentMode,
    required this.amountPaid,
    required this.bottomPad,
    required this.onDiscountChanged,
    required this.onPaymentSelected,
    required this.onConfirm,
    required this.onAmountPaidChanged,
    required this.onReceivedModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bill summary card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCol(label: 'Subtotal', value: '₹${subtotal.toStringAsFixed(0)}'),
                ),
                if (quickDiscount > 0) ...[
                  Container(width: 1, height: 28, color: AppTheme.borderColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCol(
                      label: 'Discount',
                      value: '−₹${quickDiscount.toStringAsFixed(0)}',
                      valueColor: AppTheme.successColor,
                    ),
                  ),
                ],
                Container(width: 1, height: 28, color: AppTheme.borderColor),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCol(
                    label: 'Total',
                    value: '₹${finalAmount.toStringAsFixed(0)}',
                    valueColor: AppTheme.accentColor,
                    bold: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Discount
          const Text('Quick Discount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _DiscountChip(label: 'None', active: quickDiscount == 0, onTap: () => onDiscountChanged(0.0)),
                const SizedBox(width: 8),
                _DiscountChip(label: '−₹10', active: quickDiscount == 10, onTap: () => onDiscountChanged(quickDiscount == 10 ? 0.0 : 10.0)),
                const SizedBox(width: 8),
                _DiscountChip(label: '−₹50', active: quickDiscount == 50, onTap: () => onDiscountChanged(quickDiscount == 50 ? 0.0 : 50.0)),
                const SizedBox(width: 8),
                _DiscountChip(
                  label: '−5%',
                  active: quickDiscount == (subtotal * 0.05).toInt(),
                  onTap: () {
                    final v = (subtotal * 0.05).toInt();
                    onDiscountChanged(quickDiscount == v ? 0.0 : v.toDouble());
                  },
                ),
                const SizedBox(width: 8),
                _DiscountChip(
                  label: '−10%',
                  active: quickDiscount == (subtotal * 0.10).toInt(),
                  onTap: () {
                    final v = (subtotal * 0.10).toInt();
                    onDiscountChanged(quickDiscount == v ? 0.0 : v.toDouble());
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Payment Mode
          const Text('Select Payment Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          const Text(
            'Tap a payment mode to open customer details and confirm the sale.',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PayBtn(label: 'Cash', icon: Icons.payments_rounded, color: const Color(0xFF16A34A), selected: selectedPaymentMethod == 'Cash', onTap: () => onPaymentSelected('Cash')),
                const SizedBox(width: 8),
                _PayBtn(label: 'UPI', icon: Icons.qr_code_scanner_rounded, color: AppTheme.accentColor, selected: selectedPaymentMethod == 'UPI', onTap: () => onPaymentSelected('UPI')),
                const SizedBox(width: 8),
                _PayBtn(label: 'Card', icon: Icons.credit_card_rounded, color: const Color(0xFF2563EB), selected: selectedPaymentMethod == 'Card', onTap: () => onPaymentSelected('Card')),
                const SizedBox(width: 8),
                _PayBtn(label: 'Khata', icon: Icons.book_rounded, color: const Color(0xFFD97706), selected: selectedPaymentMethod == 'Khata', onTap: () => onPaymentSelected('Khata')),
                const SizedBox(width: 8),
                _PayBtn(label: 'Other', icon: Icons.more_horiz_rounded, color: AppTheme.textSecondary, selected: selectedPaymentMethod == 'Other', onTap: () => onPaymentSelected('Other')),
              ],
            ),
          ),

          // Khata partial payment section
          if (selectedPaymentMethod == 'Khata') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Amount Received Today?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: '0',
                            prefixText: '₹ ',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (v) => onAmountPaidChanged(double.tryParse(v) ?? 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: receivedPaymentMode,
                              isExpanded: true,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                              items: ['Cash', 'UPI', 'Card', 'Other']
                                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                                  .toList(),
                              onChanged: (v) { if (v != null) onReceivedModeChanged(v); },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Remaining', style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                          Text(
                            '₹${finalAmount - amountPaid}',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.errorColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Customer display (if set)
          if (customerPhone != null || customerName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, color: AppTheme.accentColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      [customerName, customerPhone].where((v) => v != null && v.isNotEmpty).join(' · '),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

          // Pay Now button (only if payment already selected)
          if (selectedPaymentMethod != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        'Pay ₹$finalAmount  →',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _SummaryCol({required this.label, required this.value, this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DiscountChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _DiscountChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.successColor.withValues(alpha: 0.1) : AppTheme.backgroundColor,
          border: Border.all(color: active ? AppTheme.successColor : Colors.transparent),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? AppTheme.successColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PayBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _PayBtn({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.mediumImpact(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppTheme.borderColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? Colors.white : color.withValues(alpha: 0.8), size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Qty Input Bottom Sheet ────────────────────────────────────────────────────

class _QtyInputSheet extends StatefulWidget {
  final Product product;
  final double remaining; // double.infinity for services

  const _QtyInputSheet({required this.product, required this.remaining});

  @override
  State<_QtyInputSheet> createState() => _QtyInputSheetState();
}

class _QtyInputSheetState extends State<_QtyInputSheet> {
  final _controller = TextEditingController();
  String _display = '';
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tap(String value) {
    setState(() {
      if (value == '⌫') {
        if (_display.isNotEmpty) _display = _display.substring(0, _display.length - 1);
      } else if (value == '.') {
        if (!_display.contains('.')) _display += '.';
      } else {
        if (_display == '0') {
          _display = value;
        } else {
          _display += value;
        }
      }
      _validateDisplay();
    });
  }

  void _validateDisplay() {
    final parsed = double.tryParse(_display);
    if (_display.isEmpty || parsed == null || parsed <= 0) {
      _error = null; // empty = not yet entered, keep button disabled silently
    } else if (widget.remaining != double.infinity && parsed > widget.remaining) {
      _error = 'Only ${_fmtQty(widget.remaining)} ${widget.product.unit} left';
    } else {
      _error = null;
    }
  }

  String _fmtQty(double q) {
    if (q == q.truncateToDouble()) return q.toInt().toString();
    return q.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  bool get _canAdd {
    final parsed = double.tryParse(_display);
    return parsed != null && parsed > 0 && _error == null;
  }

  Widget _numKey(String label, {Color? color}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _tap(label),
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: label == '⌫' ? AppTheme.errorColor.withValues(alpha: 0.1) : AppTheme.slate100,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          height: 64,
          child: Text(
            label,
            style: TextStyle(
              fontSize: label == '⌫' ? 22 : 26,
              fontWeight: FontWeight.w700,
              color: color ?? (label == '⌫' ? AppTheme.errorColor : AppTheme.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoose = widget.product.isLoose;
    final unit = widget.product.unit;
    final price = widget.product.price;
    final parsed = double.tryParse(_display);
    final previewAmount = parsed != null ? parsed * price : null;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.slate300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),

            // Product name + unit
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isLoose ? 'How much? (in $unit)' : 'How many?',
                          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${price % 1 == 0 ? price.toInt() : price.toStringAsFixed(2)} / $unit',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                      ),
                      if (widget.remaining != double.infinity)
                        Text(
                          'Stock: ${_fmtQty(widget.remaining)} $unit',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Big display
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: _error != null ? AppTheme.errorColor.withValues(alpha: 0.1) : AppTheme.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _error != null ? AppTheme.errorColor.withValues(alpha: 0.3) : AppTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _display.isEmpty ? '0' : _display,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: _display.isEmpty ? AppTheme.slate300 : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Text(unit, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 28),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_error!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            if (previewAmount != null && _error == null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 28),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '= ₹${previewAmount % 1 == 0 ? previewAmount.toInt() : previewAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.successColor),
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Numpad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Row(children: ['1', '2', '3'].map((k) => _numKey(k)).toList()),
                  Row(children: ['4', '5', '6'].map((k) => _numKey(k)).toList()),
                  Row(children: ['7', '8', '9'].map((k) => _numKey(k)).toList()),
                  Row(children: [
                    isLoose ? _numKey('.') : Expanded(child: SizedBox(height: 64)),
                    _numKey('0'),
                    _numKey('⌫'),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Add button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _canAdd ? () => Navigator.pop(context, double.parse(_display)) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    disabledBackgroundColor: AppTheme.slate200,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: Text(
                    _canAdd
                        ? 'Add to Bill  +${_fmtQty(double.parse(_display))} $unit'
                        : 'Enter Qty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _canAdd ? Colors.white : AppTheme.slate400,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _QRScannerModal extends StatefulWidget {
  final List<Product> products;
  final Function(String) onScanned;

  const _QRScannerModal({
    required this.products,
    required this.onScanned,
  });

  @override
  State<_QRScannerModal> createState() => _QRScannerModalState();
}

class _QRScannerModalState extends State<_QRScannerModal> {
  late MobileScannerController controller;
  String? errorMessage;
  Timer? _errorTimer;
  String? _lastScanned;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() {
      errorMessage = message;
    });
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          errorMessage = null;
          _lastScanned = null;
        });
      }
    });
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp) {
        HapticFeedback.lightImpact();
        controller.toggleTorch();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
        HapticFeedback.lightImpact();
        controller.stop().then((_) => controller.start());
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scan Product SKU',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Position the QR code within the frame',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  MobileScanner(
                    controller: controller,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        final sku = barcode.rawValue?.trim() ?? '';
                        if (sku.isNotEmpty && sku != _lastScanned) {
                          _lastScanned = sku;
                          
                          final product = widget.products.cast<Product?>().firstWhere(
                            (p) => p?.sku.toLowerCase() == sku.toLowerCase(),
                            orElse: () => null,
                          );
  
                          if (product != null) {
                            if (product.displayQuantity > 0) {
                              HapticFeedback.mediumImpact();
                              Navigator.pop(context);
                              widget.onScanned(sku);
                            } else {
                              HapticFeedback.heavyImpact();
                              _showError('"${product.name}" is out of stock');
                            }
                          } else {
                            HapticFeedback.heavyImpact();
                            _showError('SKU "$sku" not found in inventory');
                          }
                          break;
                        }
                      }
                    },
                    errorBuilder: (context, error, child) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.no_photography_rounded, size: 48, color: AppTheme.textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              'Camera access required',
                              style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  // Scanner Frame Overlay (Rectangle)
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        width: 280,
                        height: 160,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            _ScannerCorner(isTop: true, isLeft: true),
                            _ScannerCorner(isTop: true, isLeft: false),
                            _ScannerCorner(isTop: false, isLeft: true),
                            _ScannerCorner(isTop: false, isLeft: false),
                          ],
                        ),
                      ),
                    ),
                  ),
  
                  // Controls (Torch & Refocus)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Column(
                      children: [
                        _ScannerActionButton(
                          icon: Icons.flashlight_on_rounded,
                          onPressed: () => controller.toggleTorch(),
                          label: 'Torch',
                        ),
                        const SizedBox(height: 16),
                        _ScannerActionButton(
                          icon: Icons.filter_center_focus_rounded,
                          onPressed: () async {
                            await controller.stop();
                            await controller.start();
                          },
                          label: 'Focus',
                        ),
                      ],
                    ),
                  ),
  
                  // Error Message Overlay
                  if (errorMessage != null)
                    Positioned(
                      bottom: 40,
                      left: 40,
                      right: 40,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.errorColor.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ScannerCorner extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _ScannerCorner({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: isTop ? -2 : null,
      bottom: !isTop ? -2 : null,
      left: isLeft ? -2 : null,
      right: !isLeft ? -2 : null,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: AppTheme.primaryColor, width: 3) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: AppTheme.primaryColor, width: 3) : BorderSide.none,
            left: isLeft ? const BorderSide(color: AppTheme.primaryColor, width: 3) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: AppTheme.primaryColor, width: 3) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(8) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(8) : Radius.zero,
            bottomLeft: !isTop && isLeft ? const Radius.circular(8) : Radius.zero,
            bottomRight: !isTop && !isLeft ? const Radius.circular(8) : Radius.zero,
          ),
        ),
      ),
    );
  }
}

class _ScannerActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String label;

  const _ScannerActionButton({
    required this.icon,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryDark.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              onPressed();
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ── Variant picker ─────────────────────────────────────────────────────────────

class _VariantSelection {
  final int variantId;
  final String label;
  final double price;
  final double qty;
  const _VariantSelection({
    required this.variantId,
    required this.label,
    required this.price,
    required this.qty,
  });
}

class _VariantPickerSheet extends StatefulWidget {
  final Product product;
  const _VariantPickerSheet({required this.product});

  @override
  State<_VariantPickerSheet> createState() => _VariantPickerSheetState();
}

class _VariantPickerSheetState extends State<_VariantPickerSheet> {
  List<ProductVariant> _variants = [];
  ProductVariant? _selected;
  final _qtyController = TextEditingController(text: '1');
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    VariantRepository().getByProduct(widget.product.id).then((v) {
      if (mounted) setState(() { _variants = v; _loading = false; });
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.slate300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.product.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Choose a variant', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_variants.isEmpty)
            const Text('No variants found.', style: TextStyle(color: AppTheme.textSecondary))
          else ...[
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _variants.map((v) {
                    final isSelected = _selected?.id == v.id;
                    final outOfStock = v.stock <= 0;
                    return GestureDetector(
                      onTap: outOfStock ? null : () => setState(() => _selected = v),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: outOfStock
                              ? AppTheme.slate100
                              : isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: outOfStock
                                ? AppTheme.slate200
                                : isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              v.label,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: outOfStock
                                    ? AppTheme.slate400
                                    : isSelected ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              outOfStock ? 'Out of stock' : '₹${v.price.toStringAsFixed(0)}  •  ${v.stock.toStringAsFixed(0)} left',
                              style: TextStyle(
                                fontSize: 11,
                                color: outOfStock
                                    ? AppTheme.slate400
                                    : isSelected ? Colors.white70 : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Qty:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _selected == null ? null : () {
                    final qty = double.tryParse(_qtyController.text) ?? 1.0;
                    if (qty <= 0) return;
                    if (qty > _selected!.stock) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Only ${_selected!.stock.toStringAsFixed(0)} in stock'),
                        backgroundColor: AppTheme.errorColor,
                      ));
                      return;
                    }
                    Navigator.pop(context, _VariantSelection(
                      variantId: _selected!.id,
                      label: _selected!.label,
                      price: _selected!.price,
                      qty: qty,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
