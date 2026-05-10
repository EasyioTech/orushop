import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/utils/currency_formatter.dart';
import '../../providers/analytics_provider.dart';
import '../../core/theme/app_theme.dart';
import 'sales_history_screen.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Default to last 7 days so graphs aren't empty
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 7));
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
      });
    }
  }

  void _resetDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayTotal = ref.watch(dailySalesTotalProvider(todayStart));
    final topProducts = ref.watch(topProductsProvider);

    final periodAnalytics = _startDate != null && _endDate != null
        ? ref.watch(periodAnalyticsProvider((start: _startDate!, end: _endDate!)))
        : null;

    final salesTrend = _startDate != null && _endDate != null
        ? ref.watch(salesTrendProvider((start: _startDate!, end: _endDate!)))
        : null;

    final paymentBreakdown = _startDate != null && _endDate != null
        ? ref.watch(paymentBreakdownProvider((start: _startDate!, end: _endDate!)))
        : null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      // Removed standard AppBar to use Custom Branded Header
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          // Invalidate the entire families to ensure we catch all potential date matches
          ref.invalidate(dailySalesTotalProvider);
          ref.invalidate(topProductsProvider);
          ref.invalidate(lowStockProductsProvider);
          ref.invalidate(expiringBatchesProvider);
          
          if (_startDate != null && _endDate != null) {
            ref.invalidate(periodAnalyticsProvider);
            ref.invalidate(salesTrendProvider);
            ref.invalidate(paymentBreakdownProvider);
          }
          // Optional: Add a small delay for better UX
          await Future.delayed(const Duration(milliseconds: 800));
        },
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Branded Header Section with Gradient
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(CupertinoIcons.back, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Store Analytics',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          icon: Icon(CupertinoIcons.time_solid, color: Colors.white, size: 20),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  todayTotal.when(
                    data: (sales) => _buildTodaySalesHeader(sales),
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                    error: (err, _) => Text('Error loading today\'s sales', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Top 10 Products (Last 30 Days)'),
                  const SizedBox(height: 12),
                  topProducts.when(
                    data: (products) => _buildTopProductsList(products),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Error: $err'),
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle('System Alerts'),
                  const SizedBox(height: 12),
                  const _AlertsSection(
                    title: 'Low Stock Products',
                    threshold: 5,
                  ),
                  const SizedBox(height: 12),
                  const _AlertsSection(
                    title: 'Expiring Soon',
                    alertDays: 30,
                  ),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Custom Period Analysis'),
                      if (_startDate != null)
                        TextButton.icon(
                          onPressed: _resetDateRange,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Reset'),
                          style: TextButton.styleFrom(foregroundColor: AppTheme.primaryLight),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _selectDateRange,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.calendar, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _startDate == null
                                ? 'Select custom date range'
                                : '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!.subtract(const Duration(days: 1)))}',
                            style: TextStyle(
                              color: _startDate == null ? AppTheme.textSecondary : AppTheme.textPrimary,
                              fontWeight: _startDate == null ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),

                  if (_startDate != null && periodAnalytics != null) ...[
                    const SizedBox(height: 24),
                    periodAnalytics.when(
                      data: (analytics) => _buildPeriodMetrics(analytics),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error: $err'),
                    ),
                  ],

                  if (_startDate != null && paymentBreakdown != null) ...[
                    const SizedBox(height: 32),
                    _buildSectionTitle('Payment Distribution'),
                    const SizedBox(height: 12),
                    paymentBreakdown.when(
                      data: (methods) => _buildPaymentBreakdown(methods),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error: $err'),
                    ),
                  ],

                  if (_startDate != null && salesTrend != null) ...[
                    const SizedBox(height: 32),
                    _buildSectionTitle('Daily Sales Trend'),
                    const SizedBox(height: 12),
                    salesTrend.when(
                      data: (trend) => _buildSalesTrend(trend),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error: $err'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildTodaySalesHeader(dynamic sales) {
    return Column(
      children: [
        Text(
          'TOTAL REVENUE TODAY',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            CurrencyFormatter.format(sales.total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                '${sales.count} TRANSACTIONS',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTopProductsList(List<dynamic> products) {
    if (products.isEmpty) {
      return _buildEmptyState('No sales data available yet.');
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: AppTheme.backgroundColor, indent: 20, endIndent: 20),
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            title: Text(
              product.productName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            trailing: Text(
              '${product.unitsSold} units',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodMetrics(dynamic analytics) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Gross Sales',
                CurrencyFormatter.format(analytics.totalSales),
                Icons.payments_rounded,
                AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Net Sales',
                CurrencyFormatter.format(analytics.netSales),
                Icons.account_balance_wallet_rounded,
                AppTheme.primaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Refunds',
                CurrencyFormatter.format(analytics.refundedAmount),
                Icons.assignment_return_rounded,
                AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Avg Ticket',
                CurrencyFormatter.format(analytics.averageTransaction),
                Icons.confirmation_number_rounded,
                AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown(List<dynamic> methods) {
    if (methods.isEmpty) return _buildEmptyState('No payment data for this period.');
    
    final colors = [AppTheme.primaryColor, AppTheme.accentColor, AppTheme.successColor, AppTheme.warningColor];

    return Container(
      height: 240,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: methods.asMap().entries.map((entry) {
                  final i = entry.key;
                  final method = entry.value;
                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: method.totalAmount,
                    title: '',
                    radius: 25,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: methods.asMap().entries.map((entry) {
              final i = entry.key;
              final method = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      method.method,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTrend(List<dynamic> trend) {
    if (trend.isEmpty) return _buildEmptyState('No trend data available.');

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(16, 32, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < 0 || value.toInt() >= trend.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MM/dd').format(trend[value.toInt()].date),
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: trend.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.totalAmount);
              }).toList(),
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor.withValues(alpha: 0.2), AppTheme.primaryColor.withValues(alpha: 0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(CupertinoIcons.chart_bar_alt_fill, size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }
}

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
            color: Colors.black.withValues(alpha: 0.04),
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

