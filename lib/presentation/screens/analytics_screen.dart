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

part 'analytics/analytics_helpers.dart';
part 'analytics/alerts_section.dart';

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
          ref.read(analyticsRevisionProvider.notifier).state++;
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
                            color: AppTheme.primaryDark.withValues(alpha: 0.03),
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
}
