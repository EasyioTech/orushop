part of '../analytics_screen.dart';

class _AlertsSection extends ConsumerWidget {
  final String title;
  final int? threshold;
  final int? alertDays;

  const _AlertsSection({
    required this.title,
    this.threshold,
    this.alertDays,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (threshold != null) {
      final lowStockAsync = ref.watch(lowStockProductsProvider(threshold!));
      return lowStockAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return _buildAlertCard(
              context,
              'All products well stocked',
              'Inventory is healthy',
              Icons.check_circle_rounded,
              AppTheme.successColor,
            );
          }
          return _buildAlertCard(
            context,
            title,
            '${products.length} items below threshold',
            Icons.warning_amber_rounded,
            AppTheme.warningColor,
            items: products.take(3).map((p) => '${p.productName} (${p.quantity})').toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Text('Error: $err'),
      );
    } else if (alertDays != null) {
      final expiringAsync = ref.watch(expiringBatchesProvider(alertDays!));
      return expiringAsync.when(
        data: (batches) {
          if (batches.isEmpty) {
            return _buildAlertCard(
              context,
              'No expiry alerts',
              'All batches are fresh',
              Icons.verified_rounded,
              AppTheme.successColor,
            );
          }
          return _buildAlertCard(
            context,
            title,
            '${batches.length} batches expiring soon',
            Icons.event_busy_rounded,
            AppTheme.errorColor,
            items: batches.take(3).map((b) => '${b.productName} (Exp: ${DateFormat('MMM d').format(b.expiryDate)})').toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Text('Error: $err'),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAlertCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    List<String>? items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (items != null && items.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 40),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.5), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}