part of '../khata_screen.dart';

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
      onRefresh: () async {},
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

    final balanceColor = isSettled
        ? AppTheme.textSecondary
        : isReceivable
            ? const Color(0xFF2D9E64)
            : const Color(0xFFD64545);

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
                color: AppTheme.primaryDark.withValues(alpha: 0.02),
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
