import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/core/models/product.dart';
import 'package:orushops/core/repositories/variant_repository.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';
import 'package:orushops/providers/cart_provider.dart';
import 'package:orushops/providers/products_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class ProductGridCard extends ConsumerStatefulWidget {
  final Product product;
  final bool isRecentlyAdded;
  final void Function(double qty) onAdd;
  final Future<void> Function(Product) onAddLoose;
  final Future<void> Function() onAddVariant;

  const ProductGridCard({
    super.key,
    required this.product,
    required this.isRecentlyAdded,
    required this.onAdd,
    required this.onAddLoose,
    required this.onAddVariant,
  });

  @override
  ConsumerState<ProductGridCard> createState() => _ProductGridCardState();
}

class _ProductGridCardState extends ConsumerState<ProductGridCard> with SingleTickerProviderStateMixin {
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
                                  NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(widget.product.price.toDouble()),
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
                                        NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(widget.product.mrp!.toDouble()),
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
