part of '../products_screen.dart';

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