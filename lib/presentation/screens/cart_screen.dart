import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/held_carts_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final totalQuantity = ref.watch(cartTotalQuantityProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // 1. Branded Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryLight,
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Cart (${cartItems.length} items)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (cartItems.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 24),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Clear Cart?'),
                              content: const Text('Remove all items from cart'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ref.read(cartProvider.notifier).clearCart();
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Clear', style: TextStyle(color: AppTheme.errorColor)),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ],
            ),
          ),

          if (cartItems.isEmpty)
            Expanded(
              child: Center(
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
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Cart is empty',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Start Shopping'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _buildCustomerSection(context),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return _CartItemTile(item: item);
                },
              ),
            ),
            _CartSummary(
              items: cartItems,
              subtotal: subtotal,
              totalQuantity: totalQuantity,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Walk-in Customer',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Tap to change or add details',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.search_rounded, size: 20, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartNotifier = ref.read(cartProvider.notifier);

    return Dismissible(
      key: ValueKey(item.productId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        cartNotifier.removeItem(item.productId);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  item.productName[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.unitPrice.toStringAsFixed(0)} / unit',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _QuantityControl(
                  quantity: item.quantity,
                  onChanged: (newQuantity) {
                    cartNotifier.updateQuantity(item.productId, newQuantity);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${item.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final Function(int) onChanged;

  const _QuantityControl({
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: quantity > 1
                ? () {
                    HapticFeedback.lightImpact();
                    onChanged(quantity - 1);
                  }
                : null,
            iconSize: 20,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          SizedBox(
            width: 40,
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              HapticFeedback.lightImpact();
              onChanged(quantity + 1);
            },
            iconSize: 20,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }
}

class _CartSummary extends ConsumerStatefulWidget {
  final List<CartItem> items;
  final int subtotal;
  final int totalQuantity;

  const _CartSummary({
    required this.items,
    required this.subtotal,
    required this.totalQuantity,
  });

  @override
  ConsumerState<_CartSummary> createState() => _CartSummaryState();
}

class _CartSummaryState extends ConsumerState<_CartSummary> {
  int _quickDiscount = 0;

  void _navigateToCheckout(String paymentMethod) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          items: widget.items,
          subtotal: widget.subtotal,
          initialPaymentMethod: paymentMethod,
          initialDiscount: _quickDiscount,
        ),
      ),
    );
  }

  void _holdCart() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hold This Cart?'),
        content: const Text('You can resume this cart later'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(heldCartsProvider.notifier).holdCart(widget.items);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Bill saved successfully', style: TextStyle(fontSize: 16, color: Colors.white)),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
            child: const Text('Hold'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gst = (widget.subtotal * 0.18);
    final totalWithTax = widget.subtotal + gst - _quickDiscount;
    final roundOff = totalWithTax - totalWithTax.roundToDouble();
    final finalAmount = totalWithTax.round();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSummaryRow('Items Total', '₹${widget.subtotal}'),
          _buildSummaryRow('GST (18%)', '₹${gst.toStringAsFixed(2)}', color: AppTheme.textSecondary.withValues(alpha: 0.7)),
          if (_quickDiscount > 0)
            _buildSummaryRow('Discount', '−₹$_quickDiscount', color: AppTheme.successColor),
          _buildSummaryRow('Round Off', '${roundOff > 0 ? "+" : ""}₹${(-roundOff).toStringAsFixed(2)}', color: AppTheme.textSecondary.withValues(alpha: 0.5)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppTheme.borderColor),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary),
              ),
              Text(
                '₹$finalAmount',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  color: AppTheme.primaryColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _QuickDiscountChip(label: '−₹10', value: 10, isActive: _quickDiscount == 10, onTap: () => setState(() => _quickDiscount = _quickDiscount == 10 ? 0 : 10)),
                const SizedBox(width: 8),
                _QuickDiscountChip(label: '−₹50', value: 50, isActive: _quickDiscount == 50, onTap: () => setState(() => _quickDiscount = _quickDiscount == 50 ? 0 : 50)),
                const SizedBox(width: 8),
                _QuickDiscountChip(label: '−5%', value: (widget.subtotal * 0.05).toInt(), isActive: _quickDiscount == (widget.subtotal * 0.05).toInt(), onTap: () => setState(() => _quickDiscount = _quickDiscount == (widget.subtotal * 0.05).toInt() ? 0 : (widget.subtotal * 0.05).toInt())),
                const SizedBox(width: 8),
                _QuickDiscountChip(label: '−10%', value: (widget.subtotal * 0.10).toInt(), isActive: _quickDiscount == (widget.subtotal * 0.10).toInt(), onTap: () => setState(() => _quickDiscount = _quickDiscount == (widget.subtotal * 0.10).toInt() ? 0 : (widget.subtotal * 0.10).toInt())),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _PaymentButton(
                label: 'Cash',
                icon: Icons.payments_rounded,
                color: AppTheme.primaryColor,
                onTap: () => _navigateToCheckout('Cash'),
              ),
              const SizedBox(width: 12),
              _PaymentButton(
                label: 'UPI',
                icon: Icons.qr_code_scanner_rounded,
                color: AppTheme.primaryColor,
                onTap: () => _navigateToCheckout('UPI'),
              ),
              const SizedBox(width: 12),
              _PaymentButton(
                label: 'Hold',
                icon: Icons.pause_circle_outline_rounded,
                color: AppTheme.textSecondary,
                onTap: _holdCart,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color ?? AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(color: color ?? AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _PaymentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PaymentButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickDiscountChip extends StatelessWidget {
  final String label;
  final int value;
  final bool isActive;
  final VoidCallback onTap;

  const _QuickDiscountChip({
    required this.label,
    required this.value,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor.withValues(alpha: 0.08) : AppTheme.surfaceColor,
          border: Border.all(
            color: isActive ? AppTheme.primaryColor : AppTheme.borderColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
