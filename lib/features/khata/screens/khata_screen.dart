import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/khata_customer.dart';
import '../../../providers/khata_provider.dart';
import 'customer_detail_screen.dart';
import '../widgets/add_customer_sheet.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../core/widgets/error_boundary.dart';

class KhataScreen extends ConsumerStatefulWidget {
  const KhataScreen({super.key});

  @override
  ConsumerState<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends ConsumerState<KhataScreen>
    with SingleTickerProviderStateMixin {
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
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isOffline = ref.watch(isOfflineProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: OfflineBanner(
        isOffline: isOffline,
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
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor, strokeWidth: 3))
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
    floatingActionButton: FloatingActionButton.extended(
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
    );
  }

}

// ── Summary header ────────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  final Map<String, double> summary;
  final NumberFormat fmt;

  const _SummaryHeader({required this.summary, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final receivable = summary['totalReceivable'] ?? 0;
    final payable = summary['totalPayable'] ?? 0;
    
    return Container(
      color: AppTheme.primaryColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  _SummaryItem(
                    label: 'You Will Get',
                    amount: fmt.format(receivable),
                    color: Colors.white,
                    subColor: AppTheme.successColor,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  _SummaryItem(
                    label: 'You Will Give',
                    amount: fmt.format(payable.abs()),
                    color: Colors.white,
                    subColor: const Color(0xFFFF6B6B),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final Color subColor;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_upward_rounded, size: 14, color: subColor),
            ],
          ),
        ],
      ),
    );
  }
}


// ── Customer list ─────────────────────────────────────────────────────────────

class _CustomerList extends StatelessWidget {
  final List<KhataCustomer> customers;
  final NumberFormat fmt;
  final String emptyLabel;

  const _CustomerList({
    required this.customers,
    required this.fmt,
    this.emptyLabel = 'No customers found',
  });

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_search_rounded, size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.2)),
            ),
            const SizedBox(height: 16),
            Text(emptyLabel, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.accentColor,
      backgroundColor: Colors.white,
      onRefresh: () async {
        // Handled by parent or manual refresh
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: customers.length,
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _CustomerTile(customer: customers[i], fmt: fmt),
      ),
    );
  }
}

class _CustomerTile extends ConsumerWidget {
  final KhataCustomer customer;
  final NumberFormat fmt;

  const _CustomerTile({required this.customer, required this.fmt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = customer.balance;
    final isReceivable = balance > 0;
    final isSettled = balance == 0;
    
    // Muted premium colors instead of generic red/green
    final balanceColor = isSettled
        ? AppTheme.textSecondary
        : isReceivable
            ? const Color(0xFF2D9E64) // Forest Green
            : const Color(0xFFD64545); // Deep Coral

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(customerId: customer.id),
            ),
          ).then((_) => ref.read(khataListProvider.notifier).load());
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _Avatar(name: customer.name),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.history_rounded, size: 13, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          customer.lastTransactionAt != null 
                            ? _timeAgo(customer.lastTransactionAt!)
                            : 'No transactions yet',
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt.format(balance.abs()),
                    style: TextStyle(
                      color: balanceColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: balanceColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isSettled ? 'SETTLED' : isReceivable ? 'GETTING' : 'GIVING',
                      style: TextStyle(
                        color: balanceColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        firstLetter,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 40),
            const SizedBox(height: 16),
            Text(
              error, 
              textAlign: TextAlign.center, 
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: onRetry, 
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

