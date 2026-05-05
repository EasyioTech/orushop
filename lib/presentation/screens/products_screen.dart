import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';

import 'package:orushops/core/models/cart_item.dart';
import 'package:orushops/core/models/product.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/core/utils/currency_formatter.dart';
import 'package:orushops/providers/products_provider.dart';
import 'package:orushops/providers/cart_provider.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';
import 'package:orushops/providers/auth_provider.dart';
import 'package:orushops/providers/held_carts_provider.dart';
import 'package:orushops/core/models/khata_customer.dart';
import 'package:orushops/providers/khata_provider.dart';
import 'package:orushops/providers/checkout_provider.dart';
import 'package:orushops/core/repositories/owner_provider.dart';
import 'cart_screen.dart';
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

  void _addToCart(Product product) {
    HapticFeedback.mediumImpact();

    final cartItems = ref.read(cartProvider);
    final currentInCart = cartItems
        .where((i) => i.productId == product.id)
        .fold(0, (sum, i) => sum + i.quantity);

    if (currentInCart + 1 > product.displayQuantity) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only ${product.displayQuantity} units of "${product.name}" available'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final cartItem = CartItem(
      productId: product.id,
      productName: product.name,
      quantity: 1,
      unitPrice: product.price.toDouble(),
      selectedBatchIds: [],
    );

    ref.read(cartProvider.notifier).addItem(cartItem);
    
    // Explicitly unfocus to prevent keyboard from popping up if it was triggered
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _recentlyAddedIds.add(product.id);
    });

    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _recentlyAddedIds.remove(product.id);
        });
      }
    });
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
                      final items = ref.read(heldCartsProvider.notifier).recallCart(cart.id);
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
                          
                          int finalQty = item.quantity;
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
                            backgroundColor: (adjustedCount > 0 || removedCount > 0) ? Colors.orange : AppTheme.primaryColor,
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
                              color: Colors.black.withValues(alpha: 0.05),
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
                                  color: (hasHeldCarts ? AppTheme.primaryColor : Colors.black).withValues(alpha: 0.05),
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
                        Icon(Icons.search, color: Colors.grey[400], size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            autofocus: false, // Explicitly disable autofocus
                            style: const TextStyle(fontSize: 17),
                            decoration: InputDecoration(
                              hintText: 'Search products by name...',
                              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 17, fontWeight: FontWeight.w400),
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
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];
                          final isRecentlyAdded = _recentlyAddedIds.contains(product.id);

                          return _ProductGridCard(
                            product: product,
                            isRecentlyAdded: isRecentlyAdded,
                            onAdd: () => _addToCart(product),
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
                        color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
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
                        color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.5) : Colors.grey[300]!,
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
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No products found matching "$searchQuery"',
            style: TextStyle(color: Colors.grey[600]),
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
                                        color: Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Remove',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red,
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

  Widget _buildSummaryBar(int total, int count) {
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
              color: Colors.black.withValues(alpha: 0.05),
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
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.red, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count Items',
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
  final VoidCallback onAdd;

  const _ProductGridCard({
    required this.product,
    required this.isRecentlyAdded,
    required this.onAdd,
  });

  @override
  ConsumerState<_ProductGridCard> createState() => _ProductGridCardState();
}

class _ProductGridCardState extends ConsumerState<_ProductGridCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _showQuantityPicker() async {
    final currentCartQty = ref.read(cartProvider)
        .where((i) => i.productId == widget.product.id)
        .fold(0, (sum, i) => sum + i.quantity);
    
    _quantity = 1;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Quantity'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _quantity.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _quantity + currentCartQty < widget.product.displayQuantity
                        ? () => setState(() => _quantity++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _quantity = 1;
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _addWithAnimation();
                      },
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addWithAnimation() {
    for (int i = 0; i < _quantity; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        widget.onAdd();
      });
    }
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    _quantity = 1;
  }

  void _addOne() {
    final currentCartQty = ref.read(cartProvider)
        .where((i) => i.productId == widget.product.id)
        .fold(0, (sum, i) => sum + i.quantity);
    
    if (currentCartQty >= widget.product.displayQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient stock for ${widget.product.name}'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    _quantity = 1;
    _addWithAnimation();
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

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        tagValues.join(' • '),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary.withValues(alpha: 0.6),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartQty = cartItems
        .where((i) => i.productId == widget.product.id)
        .fold(0, (sum, i) => sum + i.quantity);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _addOne();
      },
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder / Checkmark
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Hero(
                      tag: 'product_image_${widget.product.id}',
                      child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
                          ? Image.network(
                              widget.product.imageUrl!,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              alignment: Alignment.center,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                            )
                          : widget.product.imagePath != null && widget.product.imagePath!.isNotEmpty
                              ? Image.file(
                                  File(widget.product.imagePath!),
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                  alignment: Alignment.center,
                                  errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                                )
                              : _buildPlaceholderIcon(),
                      ),
                    ),
                  ),
                ),
                if (cartQty > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$cartQty',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (widget.product.displayQuantity <= 0)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'OUT OF STOCK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Info and action
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                ref.watch(shopCategoriesProvider).when(
                  data: (categories) => _buildMiniTags(widget.product, categories),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      CurrencyFormatter.format(widget.product.price.toDouble()),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.product.displayQuantity <= 0 ? null : () {
                          HapticFeedback.mediumImpact();
                          _showQuantityPicker();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.product.displayQuantity <= 0 
                                ? Colors.grey[300] 
                                : AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: widget.product.displayQuantity <= 0 
                                ? Colors.grey[500] 
                                : Colors.white,
                            size: 16,
                          ),
                        ),
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
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 40,
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 4),
          Text(
            'NO IMAGE',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: AppTheme.textSecondary.withValues(alpha: 0.3),
              letterSpacing: 1,
            ),
          ),
        ],
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
  int _quickDiscount = 0;
  double _amountPaid = 0;
  String _receivedPaymentMode = 'Cash';
  List<KhataCustomer> _customerSuggestions = [];

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
  }

  Future<void> _processSale(int subtotal, List<CartItem> items) async {
    final finalAmount = subtotal - _quickDiscount;
    final checkoutState = ref.read(checkoutProvider);
    if (checkoutState.isLoading) return;

    HapticFeedback.mediumImpact();
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
      final soldItems = {for (var item in items) item.productId: item.quantity};
      ref.read(paginatedProductsProvider.notifier).decrementStock(soldItems);
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
    List<KhataCustomer> suggestions = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Optional — helps track the sale.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '9876543210',
                    prefixIcon: const Icon(Icons.phone_android_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (val) async {
                    if (val.length >= 3) {
                      final repo = ref.read(khataRepositoryProvider);
                      final results = await repo.getAllCustomers(search: val);
                      setD(() => suggestions = results);
                    } else {
                      setD(() => suggestions = []);
                    }
                  },
                ),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 130),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: suggestions.length,
                      itemBuilder: (_, i) {
                        final c = suggestions[i];
                        return ListTile(
                          dense: true,
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(c.phone),
                          onTap: () {
                            phoneCtrl.text = c.phone;
                            nameCtrl.text = c.name;
                            setD(() => suggestions = []);
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Customer Name',
                    hintText: 'John Doe',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Skip', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _customerPhone = phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim();
                  _customerName = nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim();
                  _customerSuggestions = [];
                });
                Navigator.pop(ctx);
                onSaved();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm'),
            ),
          ],
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
            separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                builder: (_, ref, __) {
                  final subtotal = ref.watch(cartSubtotalProvider);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Subtotal', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                      Text(
                        '₹$subtotal',
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
                icon: item.quantity == 1 ? Icons.delete_outline_rounded : Icons.remove,
                color: item.quantity == 1 ? AppTheme.errorColor : AppTheme.textPrimary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (item.quantity == 1) {
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
                    '${item.quantity}',
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
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)]
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
  final int subtotal;
  final int finalAmount;
  final bool isLoading;
  final int quickDiscount;
  final String? selectedPaymentMethod;
  final String? customerName;
  final String? customerPhone;
  final String receivedPaymentMode;
  final double amountPaid;
  final double bottomPad;
  final ValueChanged<int> onDiscountChanged;
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
                  child: _SummaryCol(label: 'Subtotal', value: '₹$subtotal'),
                ),
                if (quickDiscount > 0) ...[
                  Container(width: 1, height: 28, color: AppTheme.borderColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCol(
                      label: 'Discount',
                      value: '−₹$quickDiscount',
                      valueColor: AppTheme.successColor,
                    ),
                  ),
                ],
                Container(width: 1, height: 28, color: AppTheme.borderColor),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCol(
                    label: 'Total',
                    value: '₹$finalAmount',
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
                _DiscountChip(label: 'None', active: quickDiscount == 0, onTap: () => onDiscountChanged(0)),
                const SizedBox(width: 8),
                _DiscountChip(label: '−₹10', active: quickDiscount == 10, onTap: () => onDiscountChanged(quickDiscount == 10 ? 0 : 10)),
                const SizedBox(width: 8),
                _DiscountChip(label: '−₹50', active: quickDiscount == 50, onTap: () => onDiscountChanged(quickDiscount == 50 ? 0 : 50)),
                const SizedBox(width: 8),
                _DiscountChip(
                  label: '−5%',
                  active: quickDiscount == (subtotal * 0.05).toInt(),
                  onTap: () {
                    final v = (subtotal * 0.05).toInt();
                    onDiscountChanged(quickDiscount == v ? 0 : v);
                  },
                ),
                const SizedBox(width: 8),
                _DiscountChip(
                  label: '−10%',
                  active: quickDiscount == (subtotal * 0.10).toInt(),
                  onTap: () {
                    final v = (subtotal * 0.10).toInt();
                    onDiscountChanged(quickDiscount == v ? 0 : v);
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
                      [customerName, customerPhone].where((v) => v != null && v!.isNotEmpty).join(' · '),
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
            color: Colors.black.withValues(alpha: 0.5),
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


