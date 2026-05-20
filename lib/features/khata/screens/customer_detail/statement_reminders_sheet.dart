part of '../customer_detail_screen.dart';

class _StatementRemindersSheet extends StatefulWidget {
  final KhataCustomer customer;
  final List<Map<String, dynamic>> ledger;
  final String storeName;
  final String storePhone;
  final String storeAddress;
  final String? upiId;

  const _StatementRemindersSheet({
    required this.customer,
    required this.ledger,
    required this.storeName,
    required this.storePhone,
    required this.storeAddress,
    this.upiId,
  });

  @override
  State<_StatementRemindersSheet> createState() => _StatementRemindersSheetState();
}

class _StatementRemindersSheetState extends State<_StatementRemindersSheet> {
  final _actionService = KhataActionService();
  bool _isLoading = false;

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppTheme.navy900,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.customer.balance;
    final isReceivable = balance > 0;
    final balanceStr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(balance.abs());

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.slate300.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.share_rounded, color: AppTheme.navy900, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share Statement / Reminders',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.navy900, letterSpacing: -0.5),
                    ),
                    Text(
                      widget.customer.name,
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary.withValues(alpha: 0.6), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Mini outstanding status card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isReceivable ? const Color(0xFFD64545).withValues(alpha: 0.06) : const Color(0xFF2D9E64).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isReceivable ? const Color(0xFFD64545).withValues(alpha: 0.15) : const Color(0xFF2D9E64).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT OUTSTANDING',
                      style: TextStyle(
                        fontSize: 9, 
                        fontWeight: FontWeight.w900, 
                        color: isReceivable ? const Color(0xFFD64545) : const Color(0xFF2D9E64),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isReceivable ? 'Customer owes you' : balance < 0 ? 'You owe customer' : 'Settled account',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.navy900),
                    ),
                  ],
                ),
                Text(
                  balanceStr,
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.w900, 
                    color: isReceivable ? const Color(0xFFD64545) : const Color(0xFF2D9E64),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppTheme.navy900, strokeWidth: 3),
              ),
            )
          else ...[
            // Quick Send Options
            _reminderActionTile(
              label: 'Direct WhatsApp Reminder',
              subtitle: 'Send instant text message directly to customer',
              icon: Icons.chat_bubble_outline_rounded,
              color: const Color(0xFF2D9E64),
              onTap: () async {
                setState(() => _isLoading = true);
                await _actionService.shareLedgerStatementWhatsApp(
                  customerName: widget.customer.name,
                  customerPhone: widget.customer.phone,
                  currentBalance: balance,
                  storeName: widget.storeName,
                  upiId: widget.upiId,
                );
                if (!context.mounted) return;
                setState(() => _isLoading = false);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _reminderActionTile(
              label: 'Direct SMS Reminder',
              subtitle: 'Send direct template message via cellular network',
              icon: Icons.sms_outlined,
              color: Colors.indigo,
              onTap: () async {
                setState(() => _isLoading = true);
                await _actionService.sendLedgerStatementSms(
                  customerName: widget.customer.name,
                  customerPhone: widget.customer.phone,
                  currentBalance: balance,
                  storeName: widget.storeName,
                  upiId: widget.upiId,
                );
                if (!context.mounted) return;
                setState(() => _isLoading = false);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _reminderActionTile(
              label: 'Share PDF Account Statement',
              subtitle: 'Generate A4 Ledger Statement with running balance',
              icon: Icons.picture_as_pdf_outlined,
              color: Colors.redAccent,
              onTap: () async {
                setState(() => _isLoading = true);
                try {
                  await _actionService.shareLedgerStatementPdf(
                    customerName: widget.customer.name,
                    customerPhone: widget.customer.phone,
                    ledger: widget.ledger,
                    storeName: widget.storeName,
                    storePhone: widget.storePhone,
                    storeAddress: widget.storeAddress,
                    upiId: widget.upiId,
                    currentBalance: balance,
                  );
                } catch (e) {
                  _toast('Failed to share PDF statement: $e');
                }
                if (!context.mounted) return;
                setState(() => _isLoading = false);
                Navigator.pop(context);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _reminderActionTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.navy900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── INDIVIDUAL TRANSACTION ACTION SHEET ──────────────────────────────────────

