import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:orushops/core/theme/app_theme.dart';

import '../../core/repositories/analytics_repository.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/auth_provider.dart';
import 'analytics_screen.dart';

part 'home/home_widgets.dart';
part 'home/home_sections.dart';

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
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.read(analyticsRevisionProvider.notifier).state++;
          await Future.delayed(const Duration(milliseconds: 800));
        },
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
            actions: const [],
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
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.1,
              ),
              delegate: SliverChildListDelegate([
                _ActionPill(
                  icon: CupertinoIcons.add_circled_solid,
                  label: 'New Sale',
                  color: AppTheme.accentColor,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.read(navigationIndexProvider.notifier).state = 1;
                  },
                ),
                _ActionPill(
                  icon: CupertinoIcons.cube_box_fill,
                  label: 'Stock',
                  color: const Color(0xFF6366F1),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(navigationIndexProvider.notifier).state = 2;
                  },
                ),
                _ActionPill(
                  icon: CupertinoIcons.book_fill,
                  label: 'Khata',
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(navigationIndexProvider.notifier).state = 3;
                  },
                ),
                _ActionPill(
                  icon: CupertinoIcons.chart_bar_square_fill,
                  label: 'Reports',
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