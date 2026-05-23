part of '../customer_detail_screen.dart';

class _TransactionActionSheet extends StatefulWidget {
  final Map<String, dynamic> record;
  final KhataCustomer customer;
  final String storeName;
  final String storePhone;
  final String storeAddress;
  final String? upiId;

  const _TransactionActionSheet({
    required this.record,
    required this.customer,
    required this.storeName,
    required this.storePhone,
    required this.storeAddress,
    this.upiId,
  });

  @override
  State<_TransactionActionSheet> createState() => _TransactionActionSheetState();
}

class _TransactionActionSheetState extends State<_TransactionActionSheet> {
  static final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final _dateFmt = DateFormat('MMMM d, yyyy • h:mm a');

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
    final recordType = widget.record['recordType'] as String;
    final type = widget.record['type'] as String;
    final amount = (widget.record['amount'] as num).toDouble();
    final note = widget.record['note'] as String;
    final createdAt = DateTime.parse(widget.record['createdAt'] as String);

    final isCredit = type == 'credit';
    final isPayment = recordType == 'payment';
    final color = isCredit ? const Color(0xFF2D9E64) : const Color(0xFFD64545);
    final amtStr = _fmt.format(amount);

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
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isPayment ? Icons.account_balance_wallet_rounded : isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
                  color: color, size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.isEmpty ? (isPayment ? 'Payment Received' : 'General Entry') : note,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.navy900, letterSpacing: -0.5),
                    ),
                    Text(
                      _dateFmt.format(createdAt),
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Text(
                amtStr,
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 20),
              ),
            ],
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
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    label: 'WhatsApp',
                    icon: Icons.chat_bubble_outline_rounded,
                    color: const Color(0xFF2D9E64),
                    onTap: () async {
                      setState(() => _isLoading = true);
                      await _actionService.shareLedgerEntryToWhatsAppWithSmsFallback(
                        customerName: widget.customer.name,
                        customerPhone: widget.customer.phone,
                        amount: amount,
                        recordType: recordType,
                        type: type,
                        note: note,
                        createdAt: createdAt,
                        storeName: widget.storeName,
                        storePhone: widget.storePhone,
                        storeAddress: widget.storeAddress,
                        upiId: widget.upiId,
                        currentBalance: widget.customer.balance,
                        receiptImageBytes: null,
                        onRedirectingToSms: () => _toast('Opening SMS fallback...'),
                      );
                      if (!context.mounted) return;
                      setState(() => _isLoading = false);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    label: 'SMS Text',
                    icon: Icons.sms_outlined,
                    color: Colors.indigo,
                    onTap: () async {
                      setState(() => _isLoading = true);
                      await _actionService.sendLedgerEntrySms(
                        customerName: widget.customer.name,
                        customerPhone: widget.customer.phone,
                        amount: amount,
                        recordType: recordType,
                        type: type,
                        note: note,
                        createdAt: createdAt,
                        storeName: widget.storeName,
                        currentBalance: widget.customer.balance,
                      );
                      if (!context.mounted) return;
                      setState(() => _isLoading = false);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    label: 'Share PDF',
                    icon: Icons.picture_as_pdf_outlined,
                    color: Colors.redAccent,
                    onTap: () async {
                      setState(() => _isLoading = true);
                      try {
                        await _actionService.shareLedgerEntryPdf(
                          customerName: widget.customer.name,
                          customerPhone: widget.customer.phone,
                          amount: amount,
                          recordType: recordType,
                          type: type,
                          note: note,
                          createdAt: createdAt,
                          storeName: widget.storeName,
                          storePhone: widget.storePhone,
                          storeAddress: widget.storeAddress,
                          upiId: widget.upiId,
                          currentBalance: widget.customer.balance,
                        );
                      } catch (e) {
                        _toast('Failed to generate PDF: $e');
                      }
                      if (!context.mounted) return;
                      setState(() => _isLoading = false);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    label: 'Print Voucher',
                    icon: Icons.print_rounded,
                    color: AppTheme.navy900,
                    onTap: () async {
                      setState(() => _isLoading = true);
                      try {
                        await _actionService.printLedgerEntry(
                          customerName: widget.customer.name,
                          customerPhone: widget.customer.phone,
                          amount: amount,
                          recordType: recordType,
                          type: type,
                          note: note,
                          createdAt: createdAt,
                          storeName: widget.storeName,
                          storePhone: widget.storePhone,
                          storeAddress: widget.storeAddress,
                          upiId: widget.upiId,
                          currentBalance: widget.customer.balance,
                        );
                      } catch (e) {
                        _toast('Failed to print: $e');
                      }
                      if (!context.mounted) return;
                      setState(() => _isLoading = false);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 12, letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
