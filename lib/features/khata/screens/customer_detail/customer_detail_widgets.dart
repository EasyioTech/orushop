part of '../customer_detail_screen.dart';

class _BigAvatar extends StatelessWidget {
  final String name;
  const _BigAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value, 
          style: TextStyle(
            color: color, 
            fontWeight: FontWeight.w900, 
            fontSize: 20,
            letterSpacing: -0.5,
          )
        ),
        const SizedBox(height: 2),
        Text(
          label, 
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5), 
            fontSize: 10, 
            fontWeight: FontWeight.w800, 
            letterSpacing: 0.5,
          )
        ),
      ],
    );
  }
}

class _ModernActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModernActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 10, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _ModernLedgerTile extends StatelessWidget {
  static final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  final Map<String, dynamic> record;
  final KhataCustomer customer;
  final String storeName;
  final String storePhone;
  final String storeAddress;
  final String? upiId;

  const _ModernLedgerTile({
    required this.record,
    required this.customer,
    required this.storeName,
    required this.storePhone,
    required this.storeAddress,
    this.upiId,
  });

  void _showTransactionActions(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionActionSheet(
        record: record,
        customer: customer,
        storeName: storeName,
        storePhone: storePhone,
        storeAddress: storeAddress,
        upiId: upiId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = record['type'] as String;
    final recordType = record['recordType'] as String;
    final amount = (record['amount'] as num).toDouble();
    final note = record['note'] as String;
    final createdAt = DateTime.parse(record['createdAt'] as String);
    final isCredit = type == 'credit';
    final isPayment = recordType == 'payment';
    
    final color = isCredit ? const Color(0xFF2D9E64) : const Color(0xFFD64545);

    return InkWell(
      onTap: () => _showTransactionActions(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPayment ? Icons.account_balance_wallet_rounded : isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.isEmpty ? (isPayment ? 'Payment' : 'General Entry') : note, 
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, h:mm a').format(createdAt),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmt.format(amount),
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPayment ? 'PAYMENT' : isCredit ? 'CREDIT' : 'DEBIT',
                    style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

