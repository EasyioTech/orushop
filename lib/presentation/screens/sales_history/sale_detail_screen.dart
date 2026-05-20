part of '../sales_history_screen.dart';

class SaleDetailScreen extends ConsumerWidget {
  final int saleId;

  const SaleDetailScreen({required this.saleId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(saleDetailProvider(saleId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Detail'),
        elevation: 0,
      ),
      body: detailAsync.when(
        data: (detail) {
          if (detail == null) {
            return Center(
              child: Text(
                'Sale not found',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.slate100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'SALE #${detail.saleId}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.slate500, letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          CurrencyFormatter.format(detail.finalAmount),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _DetailInfo(label: 'PAYMENT', value: detail.paymentMethod, icon: Icons.payments_outlined),
                            const SizedBox(width: 12),
                            _DetailInfo(label: 'DATE', value: DateFormat('MMM d, h:mm a').format(detail.createdAt), icon: Icons.calendar_today_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...detail.items.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.slate100),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.slate900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.quantity} × ${CurrencyFormatter.format(item.unitPrice)}',
                                style: TextStyle(fontSize: 12, color: AppTheme.slate500, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(item.unitPrice * item.quantity),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.slate900),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Text(
                  'Refunds',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _RefundHistorySection(saleId: detail.saleId),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              CurrencyFormatter.format(
                                detail.finalAmount + detail.discountAmount,
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        if (detail.discountAmount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Discount',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.warningColor,
                                    ),
                              ),
                              Text(
                                '−${CurrencyFormatter.format(detail.discountAmount)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.warningColor,
                                    ),
                              ),
                            ],
                          ),
                        ],
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              CurrencyFormatter.format(detail.finalAmount),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.successColor,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              final sale = Sale(
                                id: detail.saleId,
                                totalAmount: detail.finalAmount + detail.discountAmount,
                                discountAmount: detail.discountAmount,
                                finalAmount: detail.finalAmount,
                                paymentMethod: detail.paymentMethod,
                                status: 'completed',
                                createdAt: detail.createdAt,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RefundRequestScreen(
                                    sale: sale,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Request Refund'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}


class _DetailInfo extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailInfo({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.slate50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.slate100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: AppTheme.slate400),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.slate400, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.slate900),
            ),
          ],
        ),
      ),
    );
  }
}
