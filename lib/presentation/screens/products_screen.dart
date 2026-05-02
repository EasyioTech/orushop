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
import 'package:orushops/providers/auth_provider.dart';
import 'package:orushops/providers/held_carts_provider.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'sales_history_screen.dart';

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
              child: _buildCategorySelector(ref),
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
        final allCategories = ['All', 'Fruits', 'Shakes', 'Burger', 'Snacks', ...categories.where((c) => c != 'All')];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 48,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8), // Light grayish-blue capsule background
              borderRadius: BorderRadius.circular(30),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(4),
              itemCount: allCategories.length,
              itemBuilder: (context, index) {
                final cat = allCategories[index];
                final isSelected = selectedCategory == cat;
                return GestureDetector(
                  onTap: () => ref.read(productCategoryProvider.notifier).state = cat,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 15,
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
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
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


