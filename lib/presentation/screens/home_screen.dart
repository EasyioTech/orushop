import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:orushops/core/theme/app_theme.dart';

import '../../core/repositories/analytics_repository.dart';
import '../../core/router/app_router.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
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
          // ── Main Dashboard Hero (Full Width, Attached to Top) ─────────────
          SliverToBoxAdapter(
            child: todayTotal.when(
              data: (data) {
                final prev = yesterdayTotal.valueOrNull?.total ?? 0.0;
                final growth = prev == 0 ? (data.total > 0 ? 100.0 : 0.0) : ((data.total - prev) / prev) * 100;
                return _SalesHeroCard(
                  revenue: data.total,
                  count: data.count,
                  growth: growth,
                  greeting: greeting,
                  name: name,
                  date: todayStr,
                );
              },
              loading: () => const _HeroSkeleton(),
              error: (e, _) => const SizedBox.shrink(),
            ),
          ),


          // ── Core Action Grid ──────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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
                  subtitle: 'Create Bill',
                  color: const Color(0xFF1D4ED8),
                  backgroundColor: const Color(0xFFEFF6FF),
                  borderColor: const Color(0xFFDBEAFE),
                  iconBgColor: const Color(0xFFDBEAFE),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.go(AppRoutes.pos);
                  },
                ),
                _ActionPill(
                  icon: CupertinoIcons.cube_box_fill,
                  label: 'Stock',
                  subtitle: 'Manage Items',
                  color: const Color(0xFF6D28D9),
                  backgroundColor: const Color(0xFFF5F3FF),
                  borderColor: const Color(0xFFEDE9FE),
                  iconBgColor: const Color(0xFFEDE9FE),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.go(AppRoutes.stock);
                  },
                ),
                _ActionPill(
                  icon: CupertinoIcons.book_fill,
                  label: 'Khata',
                  subtitle: 'Udhar Ledger',
                  color: const Color(0xFFB45309),
                  backgroundColor: const Color(0xFFFFFBEB),
                  borderColor: const Color(0xFFFEF3C7),
                  iconBgColor: const Color(0xFFFEF3C7),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.go(AppRoutes.khata);
                  },
                ),
                _ActionPill(
                  icon: CupertinoIcons.chart_bar_square_fill,
                  label: 'Reports',
                  subtitle: 'Earnings Info',
                  color: const Color(0xFF047857),
                  backgroundColor: const Color(0xFFECFDF5),
                  borderColor: const Color(0xFFD1FAE5),
                  iconBgColor: const Color(0xFFD1FAE5),
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