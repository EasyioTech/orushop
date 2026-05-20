part of '../products_screen.dart';

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