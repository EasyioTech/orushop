import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

import '../../core/models/sale.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/repositories/analytics_repository.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/refund_provider.dart';
import 'refund_request_screen.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  int _offset = 0;
  final int _limit = 50;
  DateTime? _startDate;
  DateTime? _endDate;

  void _resetFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _offset = 0;
    });
  }

  void _nextPage() {
    setState(() => _offset += _limit);
  }

  void _previousPage() {
    setState(() => _offset = (_offset - _limit).clamp(0, _offset));
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end.add(const Duration(days: 1));
        _offset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(salesHistoryProvider((
      limit: _limit,
      offset: _offset,
      startDate: _startDate,
      endDate: _endDate,
    )));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
          children: [
            // 1. Branded Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                bottom: 32,
              ),
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
                    const Text(
                      'Sales History',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 40), // Balance back button
                  ],
                ),
                const SizedBox(height: 24),
                // Date Filter Bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: InkWell(
                    onTap: _selectDateRange,
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _startDate == null
                                ? 'Filter by Date Range'
                                : '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!.subtract(const Duration(days: 1)))}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (_startDate != null)
                          GestureDetector(
                            onTap: _resetFilters,
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                          )
                        else
                          const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Sales List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                ref.invalidate(salesHistoryProvider((
                  limit: _limit,
                  offset: _offset,
                  startDate: _startDate,
                  endDate: _endDate,
                )));
                await ref.read(salesHistoryProvider((
                  limit: _limit,
                  offset: _offset,
                  startDate: _startDate,
                  endDate: _endDate,
                )).future);
              },
              color: AppTheme.primaryColor,
              child: historyAsync.when(
                data: (sales) {
                  if (sales.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        _buildEmptyState(),
                      ],
                    );
                  }
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _buildGroupedSalesList(sales),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Center(child: Text('Error: $err', style: TextStyle(color: AppTheme.errorColor))),
                  ],
                ),
              ),
            ),
          ),
          
          // 3. Pagination Controls
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryDark.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PaginationButton(
                  onPressed: _offset > 0 ? _previousPage : null,
                  icon: Icons.chevron_left_rounded,
                  label: 'Prev',
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Page ${(_offset ~/ _limit) + 1}',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                _PaginationButton(
                  onPressed: historyAsync.whenOrNull(data: (items) => items.length >= _limit ? _nextPage : null),
                  icon: Icons.chevron_right_rounded,
                  label: 'Next',
                  isForward: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No sales records found',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<SalesHistoryItem>> _groupSalesByDate(List<SalesHistoryItem> sales) {
    final Map<String, List<SalesHistoryItem>> grouped = {};
    for (final sale in sales) {
      final dateStr = _getGroupDateString(sale.createdAt);
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(sale);
    }
    return grouped;
  }

  String _getGroupDateString(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final saleDate = DateTime(date.year, date.month, date.day);

    if (saleDate == today) {
      return 'Today';
    } else if (saleDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM d, yyyy').format(date);
    }
  }

  List<Widget> _buildGroupedSalesList(List<SalesHistoryItem> sales) {
    final grouped = _groupSalesByDate(sales);
    final List<Widget> list = [];

    grouped.forEach((dateStr, items) {
      list.add(
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.slate900,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Text(
                '${items.length} ${items.length == 1 ? 'sale' : 'sales'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate400,
                ),
              ),
            ],
          ),
        ),
      );

      for (final sale in items) {
        list.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: _SalesHistoryListCard(sale: sale),
          ),
        );
      }
    });

    list.add(const SizedBox(height: 100));

    return list;
  }
}

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
