import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/shimmer_list.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/khata_customer.dart';
import '../../../providers/khata_provider.dart';
import 'customer_detail_screen.dart';
import '../widgets/add_customer_sheet.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../core/widgets/error_boundary.dart';

part 'khata_screen/widgets.dart';

class KhataScreen extends ConsumerStatefulWidget {
  const KhataScreen({super.key});

  @override
  ConsumerState<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends ConsumerState<KhataScreen>
    with SingleTickerProviderStateMixin {
  static final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  late final TabController _tabController;
  final _searchController = TextEditingController();
  bool _showSearch = false;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAddCustomer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddCustomerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(khataListProvider);
    final fmt = _fmt;
    final isOffline = ref.watch(isOfflineProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: OfflineBanner(
          isOffline: isOffline,
          child: RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              await ref.read(khataListProvider.notifier).load();
            },
            color: AppTheme.primaryColor,
            child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: innerBoxIsScrolled ? Colors.white : AppTheme.primaryColor,
              foregroundColor: innerBoxIsScrolled ? AppTheme.primaryColor : Colors.white,
              centerTitle: true,
              title: _showSearch
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(
                        color: innerBoxIsScrolled ? AppTheme.textPrimary : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: innerBoxIsScrolled ? AppTheme.primaryColor : Colors.white70,
                      decoration: InputDecoration(
                        hintText: 'Search customers...',
                        hintStyle: TextStyle(
                          color: innerBoxIsScrolled ? AppTheme.textSecondary : Colors.white54,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        filled: false,
                      ),
                      onChanged: (q) => ref.read(khataListProvider.notifier).search(q),
                    )
                  : Text(
                      'Khata Ledger',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: innerBoxIsScrolled ? AppTheme.primaryColor : Colors.white,
                      ),
                    ),
              actions: [
                IconButton(
                  icon: Icon(_showSearch ? Icons.close : Icons.search_rounded, size: 22),
                  onPressed: () {
                    setState(() => _showSearch = !_showSearch);
                    if (!_showSearch) {
                      _searchController.clear();
                      ref.read(khataListProvider.notifier).search('');
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(khataListProvider.notifier).load();
                  },
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: _SummaryHeader(summary: state.summary, fmt: fmt),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  decoration: BoxDecoration(
                    color: innerBoxIsScrolled ? Colors.white : AppTheme.primaryColor,
                    border: innerBoxIsScrolled
                        ? Border(bottom: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.5)))
                        : null,
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.accentColor,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorWeight: 3,
                    labelColor: innerBoxIsScrolled ? AppTheme.primaryColor : Colors.white,
                    unselectedLabelColor: innerBoxIsScrolled ? AppTheme.textSecondary : Colors.white54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'ALL'),
                      Tab(text: 'RECEIVE'),
                      Tab(text: 'PAY'),
                    ],
                    onTap: (_) => HapticFeedback.selectionClick(),
                  ),
                ),
              ),
            ),
          ],
          body: Container(
            color: AppTheme.backgroundColor.withValues(alpha: 0.5),
            child: state.isLoading && state.customers.isEmpty
                ? const ShimmerList()
                : state.error != null
                    ? _ErrorView(
                        error: state.error!,
                        onRetry: () => ref.read(khataListProvider.notifier).load(),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _CustomerList(
                            customers: state.customers,
                            fmt: fmt,
                          ),
                          _CustomerList(
                            customers: state.customers.where((c) => c.balance > 0).toList(),
                            fmt: fmt,
                            emptyLabel: 'No outstanding receivables',
                          ),
                          _CustomerList(
                            customers: state.customers.where((c) => c.balance < 0).toList(),
                            fmt: fmt,
                            emptyLabel: 'No pending payables',
                          ),
                        ],
                      ),
          ),
          ),
        ),
      ),
    floatingActionButton: Padding(
      padding: EdgeInsets.only(bottom: 50.0 + MediaQuery.of(context).padding.bottom),
      child: FloatingActionButton.extended(
          heroTag: 'khata_add_customer_fab',
          onPressed: () {
            HapticFeedback.mediumImpact();
            _openAddCustomer();
          },
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          highlightElevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
          label: const Text(
            'Add Customer',
            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
        ),
      ),
    );
  }

}
