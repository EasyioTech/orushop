part of '../products_screen.dart';

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
              _buildImageStack(
                inCart: inCart,
                outOfStock: outOfStock,
                qtyDisplay: qtyDisplay,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
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
}
