part of '../sales_history_screen.dart';

class _PaginationButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isForward;

  const _PaginationButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isForward = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: onPressed == null ? Colors.transparent : AppTheme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onPressed == null ? AppTheme.borderColor.withValues(alpha: 0.3) : AppTheme.primaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isForward) Icon(icon, size: 18, color: onPressed == null ? AppTheme.textSecondary : AppTheme.primaryColor),
            if (!isForward) const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: onPressed == null ? AppTheme.textSecondary : AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            if (isForward) const SizedBox(width: 8),
            if (isForward) Icon(icon, size: 18, color: onPressed == null ? AppTheme.textSecondary : AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}

class _RefundHistorySection extends ConsumerWidget {
  final int saleId;

  const _RefundHistorySection({required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refundsAsync = ref.watch(saleRefundsProvider(saleId));

    return refundsAsync.when(
      data: (refunds) {
        if (refunds.isEmpty) {
          return Center(
            child: Text(
              'No refunds',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.slate600,
                  ),
            ),
          );
        }
        return Column(
          children: refunds.map((refund) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.slate50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount: ${CurrencyFormatter.format(refund.refundAmount)}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMM d, h:mm a').format(refund.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.slate600,
                        ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

}

class _SalesHistoryListCard extends StatelessWidget {
  final SalesHistoryItem sale;

  const _SalesHistoryListCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.slate100, 
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SaleDetailScreen(saleId: sale.saleId),
            ),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Bill #${sale.saleId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppTheme.slate900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.slate100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${sale.itemCount} ${sale.itemCount == 1 ? 'item' : 'items'}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.slate600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(sale.createdAt),
                        style: TextStyle(
                          color: AppTheme.slate400,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CurrencyFormatter.format(sale.finalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppTheme.slate900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getPaymentBgColor(sale.paymentMethod),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sale.paymentMethod.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: _getPaymentTextColor(sale.paymentMethod),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded, 
                  color: AppTheme.slate300,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPaymentBgColor(String method) {
    final cleanMethod = method.toLowerCase();
    if (cleanMethod.contains('cash')) {
      return const Color(0xFFE6F4EA);
    } else if (cleanMethod.contains('card') || cleanMethod.contains('credit')) {
      return const Color(0xFFE8F0FE);
    } else if (cleanMethod.contains('upi') || cleanMethod.contains('online')) {
      return const Color(0xFFFEF7E0);
    }
    return AppTheme.slate100;
  }

  Color _getPaymentTextColor(String method) {
    final cleanMethod = method.toLowerCase();
    if (cleanMethod.contains('cash')) {
      return const Color(0xFF137333);
    } else if (cleanMethod.contains('card') || cleanMethod.contains('credit')) {
      return const Color(0xFF1A73E8);
    } else if (cleanMethod.contains('upi') || cleanMethod.contains('online')) {
      return const Color(0xFFB06000);
    }
    return AppTheme.slate600;
  }
}

