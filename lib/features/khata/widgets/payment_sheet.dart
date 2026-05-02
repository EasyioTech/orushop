import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/khata_provider.dart';

class PaymentSheet extends ConsumerStatefulWidget {
  final int customerId;
  final String customerName;
  final double currentBalance;

  const PaymentSheet({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.currentBalance,
  });

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _method = 'cash';
  bool _saving = false;

  static const _methods = [
    ('cash', 'Cash', Icons.money_rounded),
    ('upi', 'UPI', Icons.qr_code_rounded),
    ('bank', 'Bank Transfer', Icons.account_balance_rounded),
    ('cheque', 'Cheque', Icons.receipt_long_rounded),
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill with outstanding balance
    if (widget.currentBalance > 0) {
      _amountCtrl.text = widget.currentBalance.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    final ok = await ref.read(khataDetailProvider(widget.customerId).notifier).recordPayment(
          amount: amount,
          paymentMethod: _method,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to record payment')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.payments_rounded, color: AppTheme.successColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Collect Payment',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy900),
                      ),
                      Text(
                        widget.customerName,
                        style: const TextStyle(fontSize: 13, color: AppTheme.slate500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.navy900, letterSpacing: -1),
              decoration: InputDecoration(
                labelText: 'Amount Received',
                labelStyle: const TextStyle(color: AppTheme.slate500, fontSize: 16),
                prefixText: '₹ ',
                prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.slate400),
                filled: true,
                fillColor: AppTheme.slate50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.navy900, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              ),
              validator: (v) {
                final n = double.tryParse(v?.replaceAll(',', '') ?? '');
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 24),

            const Text('Payment Method', 
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy900, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: _methods.map((m) {
                final selected = _method == m.$1;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _method = m.$1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.navy900 : AppTheme.slate50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? AppTheme.navy900 : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(m.$3, size: 20, color: selected ? Colors.white : AppTheme.slate500),
                          const SizedBox(height: 6),
                          Text(
                            m.$2, 
                            style: TextStyle(
                              fontSize: 10, 
                              fontWeight: FontWeight.bold, 
                              color: selected ? Colors.white : AppTheme.slate600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _notesCtrl,
              style: const TextStyle(fontSize: 15, color: AppTheme.navy900),
              decoration: InputDecoration(
                labelText: 'Add Remark (Optional)',
                labelStyle: const TextStyle(color: AppTheme.slate500, fontSize: 14),
                prefixIcon: const Icon(Icons.sticky_note_2_outlined, size: 20, color: AppTheme.slate400),
                filled: true,
                fillColor: AppTheme.slate50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.navy900, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _saving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text(
                        'Confirm Payment',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
