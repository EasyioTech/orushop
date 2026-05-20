part of '../analytics_screen.dart';

extension _AnalyticsHelpers on _AnalyticsScreenState {
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
    
    return Column(
      children: products.map((product) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.slate100),
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_rounded, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product #${product.productId}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.slate900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.count} Sold',
                      style: const TextStyle(color: AppTheme.slate500, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(product.totalRevenue),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryColor),
                  ),
                  const Text(
                    'REVENUE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.slate400, letterSpacing: 0.5),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPeriodMetrics(dynamic analytics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.slate100),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMetricPill(
            icon: Icons.receipt_long_rounded,
            label: 'Total Transactions',
            value: '${analytics.count}',
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 12),
          _buildMetricPill(
            icon: Icons.payments_rounded,
            label: 'Total Revenue',
            value: CurrencyFormatter.format(analytics.total),
            color: AppTheme.successColor,
          ),
          const SizedBox(height: 12),
          _buildMetricPill(
            icon: Icons.trending_up_rounded,
            label: 'Average Sale',
            value: CurrencyFormatter.format(analytics.average),
            color: Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: AppTheme.slate600, fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16),
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
            color: AppTheme.primaryDark.withValues(alpha: 0.04),
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
            color: AppTheme.primaryDark.withValues(alpha: 0.04),
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