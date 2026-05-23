import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shimmer_list.dart';

import '../../core/models/sale.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/repositories/analytics_repository.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/refund_provider.dart';
import 'refund_request_screen.dart';
part 'sales_history/sales_history_widgets.dart';
part 'sales_history/sale_detail_screen.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  static final _shortDateFmt = DateFormat('MMM d');
  static final _longDateFmt = DateFormat('EEEE, MMMM d, yyyy');
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
                                : '${_shortDateFmt.format(_startDate!)} - ${_shortDateFmt.format(_endDate!.subtract(const Duration(days: 1)))}',
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
                loading: () => const ShimmerList(),
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
      return _longDateFmt.format(date);
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

      for (final (idx, sale) in items.indexed) {
        list.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: RepaintBoundary(
              child: _SalesHistoryListCard(sale: sale)
                  .animate(key: ValueKey(sale.saleId))
                  .fadeIn(duration: 200.ms, delay: (idx * 30).ms)
                  .slideY(begin: 0.04, curve: Curves.easeOut),
            ),
          ),
        );
      }
    });

    list.add(const SizedBox(height: 100));

    return list;
  }
}

