import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

import '../../core/theme/app_theme.dart';
import '../../core/repositories/analytics_repository.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/auth_provider.dart';
import 'analytics_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    
    final user = ref.watch(currentUserProvider);
    final todayTotal = ref.watch(dailySalesTotalProvider(todayStart));
    final yesterdayTotal = ref.watch(dailySalesTotalProvider(yesterdayStart));
    final lowStock = ref.watch(lowStockProductsProvider(5));
    final topProducts = ref.watch(topProductsProvider);

    final greeting = _greeting();
    final name = user?.displayName?.split(' ').first ?? 'Partner';
    final todayStr = DateFormat('EEE, d MMM').format(now);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Elegant Top Bar ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 0,
            toolbarHeight: 75,
            pinned: true,
            backgroundColor: AppTheme.backgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            titleSpacing: 20,
            title: Row(
              children: [
                _ProfileAvatar(name: name),
                const SizedBox(width: 14),
                _GreetingTitle(greeting: greeting, name: name, date: todayStr),
              ],
            ),
            actions: const [
              _NotificationButton(),
              SizedBox(width: 12),
            ],
          ),

          // ── Main Dashboard Hero ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: todayTotal.when(
                data: (data) {
                  final prev = yesterdayTotal.valueOrNull?.total ?? 0.0;
                  final growth = prev == 0 ? (data.total > 0 ? 100.0 : 0.0) : ((data.total - prev) / prev) * 100;
                  return _SalesHeroCard(revenue: data.total, count: data.count, growth: growth);
                },
                loading: () => const _HeroSkeleton(),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ),
          ),

          // ── Core Action Grid ──────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.05,
              ),
              delegate: SliverChildListDelegate([
                _ActionCard(
                  icon: CupertinoIcons.add_circled_solid,
                  label: 'New Sale',
                  subtitle: 'Start Billing',
                  color: AppTheme.accentColor,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.read(navigationIndexProvider.notifier).state = 1;
                  },
                ),
                _ActionCard(
                  icon: CupertinoIcons.cube_box_fill,
                  label: 'Stock',
                  subtitle: 'Inventory',
                  color: const Color(0xFF6366F1),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(navigationIndexProvider.notifier).state = 2;
                  },
                ),
                _ActionCard(
                  icon: CupertinoIcons.book_fill,
                  label: 'Khata',
                  subtitle: 'Ledger Book',
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(navigationIndexProvider.notifier).state = 3;
                  },
                ),
                _ActionCard(
                  icon: CupertinoIcons.chart_bar_square_fill,
                  label: 'Reports',
                  subtitle: 'Shop Insights',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                    );
                  },
                ),
              ]),
            ),
          ),

          // ── Analytics Section: Top Products ───────────────────────────────
          SliverToBoxAdapter(
            child: topProducts.when(
              data: (products) => products.isEmpty ? const SizedBox.shrink() : _TopProductsSection(products: products),
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
            ),
          ),

          // ── Critical Alerts ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: lowStock.when(
              data: (items) => items.isEmpty ? const SizedBox.shrink() : _AlertSection(items: items),
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

// ── SUB-COMPONENTS ───────────────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  final String name;
  const _ProfileAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'P',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
    );
  }
}

class _GreetingTitle extends StatelessWidget {
  final String greeting;
  final String name;
  final String date;

  const _GreetingTitle({required this.greeting, required this.name, required this.date});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $name',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: -0.8,
          ),
        ),
        Text(
          date,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(CupertinoIcons.bell_fill, size: 20, color: AppTheme.textPrimary),
      ),
    );
  }
}

// ── SALES HERO CARD ──────────────────────────────────────────────────────────

class _SalesHeroCard extends StatelessWidget {
  final double revenue;
  final int count;
  final double growth;

  const _SalesHeroCard({required this.revenue, required this.count, required this.growth});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: _HeroDecorations()),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeroBadge(),
                const SizedBox(height: 24),
                Text(
                  fmt.format(revenue),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2.0,
                  ),
                ),
                const SizedBox(height: 30),
                _HeroStatsRow(count: count, growth: growth),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDecorations extends StatelessWidget {
  const _HeroDecorations();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: -60,
          top: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: -40,
          child: Icon(
            CupertinoIcons.graph_circle_fill,
            size: 150,
            color: Colors.white.withValues(alpha: 0.03),
          ),
        ),
      ],
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(CupertinoIcons.sparkles, color: Colors.white, size: 14),
              SizedBox(width: 8),
              Text(
                'TODAY\'S PERFORMANCE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const Icon(CupertinoIcons.ellipsis, color: Colors.white54, size: 24),
      ],
    );
  }
}

class _HeroStatsRow extends StatelessWidget {
  final int count;
  final double growth;

  const _HeroStatsRow({required this.count, required this.growth});

  @override
  Widget build(BuildContext context) {
    final isUp = growth >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          _HeroStatItem(
            icon: CupertinoIcons.shopping_cart,
            label: 'Total Orders',
            value: '$count',
          ),
          Container(
            width: 1,
            height: 35,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            color: Colors.white.withValues(alpha: 0.15),
          ),
          _HeroStatItem(
            icon: isUp ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_right,
            label: 'Growth Rate',
            value: '${isUp ? '+' : ''}${growth.toStringAsFixed(1)}%',
            valueColor: isUp ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
          ),
        ],
      ),
    );
  }
}

class _HeroStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _HeroStatItem({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54, size: 14),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ACTION CARD ──────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.8), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── TOP PRODUCTS SECTION ─────────────────────────────────────────────────────

class _TopProductsSection extends StatelessWidget {
  final List<TopProduct> products;
  const _TopProductsSection({required this.products});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Sellers',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.8),
              ),
              Icon(CupertinoIcons.bolt_fill, color: Color(0xFFF59E0B), size: 18),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: products.length > 5 ? 5 : products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _TopProductCard(product: product, index: index);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopProductCard extends StatelessWidget {
  final TopProduct product;
  final int index;
  const _TopProductCard({required this.product, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.slate100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#${index + 1}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.slate600),
            ),
          ),
          const Spacer(),
          Text(
            product.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            '${product.unitsSold} units',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.accentColor),
          ),
        ],
      ),
    );
  }
}

// ── ALERT SECTION ────────────────────────────────────────────────────────────

class _AlertSection extends StatelessWidget {
  final List<LowStockProduct> items;
  const _AlertSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final displayCount = items.length > 3 ? 3 : items.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stock Alerts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.8),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              children: List.generate(displayCount, (i) {
                final item = items[i];
                return _AlertTile(item: item, isOut: item.quantity == 0, isLast: i == (displayCount - 1));
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final LowStockProduct item;
  final bool isOut;
  final bool isLast;

  const _AlertTile({required this.item, required this.isOut, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isOut ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              isOut ? CupertinoIcons.exclamationmark_triangle_fill : CupertinoIcons.tag_fill,
              color: isOut ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
              size: 22,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.5),
                ),
                Text(
                  isOut ? 'Critical: Out of Stock' : 'Low Stock: ${item.quantity} remaining',
                  style: TextStyle(
                    fontSize: 13,
                    color: isOut ? const Color(0xFFEF4444) : AppTheme.textSecondary,
                    fontWeight: isOut ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(CupertinoIcons.chevron_right, size: 16, color: AppTheme.slate300),
        ],
      ),
    );
  }
}

// ── SKELETONS ────────────────────────────────────────────────────────────────

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
      ),
      child: const Center(child: CupertinoActivityIndicator()),
    );
  }
}
