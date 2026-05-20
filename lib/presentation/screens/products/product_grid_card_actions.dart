part of '../products_screen.dart';

/// Cart actions (add/inc/dec) for [_ProductGridCardState]
extension _ProductGridCardActions on _ProductGridCardState {
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
}
