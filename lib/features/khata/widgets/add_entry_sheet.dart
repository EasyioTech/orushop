import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/khata_entry.dart';
import '../../../providers/khata_provider.dart';

class AddEntrySheet extends ConsumerStatefulWidget {
  final int customerId;
  final String customerName;

  const AddEntrySheet({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  ConsumerState<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends ConsumerState<AddEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  KhataEntryType _type = KhataEntryType.credit;
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    final ok = await ref.read(khataDetailProvider(widget.customerId).notifier).addEntry(
          type: _type,
          amount: amount,
          description: _descCtrl.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save entry')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isCredit = _type == KhataEntryType.credit;

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
                const Icon(Icons.edit_note_rounded, color: AppTheme.navy900, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add Entry',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.navy900)),
                      Text(widget.customerName,
                          style: const TextStyle(fontSize: 14, color: AppTheme.slate500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Credit / Debit toggle
            Row(
              children: [
                Expanded(
                  child: _TypeToggle(
                    label: 'Credit',
                    sublabel: 'Gave (Diya)',
                    icon: Icons.upload_rounded,
                    color: AppTheme.successColor,
                    selected: isCredit,
                    onTap: () => setState(() => _type = KhataEntryType.credit),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeToggle(
                    label: 'Debit',
                    sublabel: 'Took (Liya)',
                    icon: Icons.download_rounded,
                    color: AppTheme.errorColor,
                    selected: !isCredit,
                    onTap: () => setState(() => _type = KhataEntryType.debit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.navy900, letterSpacing: -1),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: const TextStyle(color: AppTheme.slate500, fontSize: 16),
                prefixText: '₹ ',
                prefixStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.slate400),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              style: const TextStyle(fontSize: 16, color: AppTheme.navy900),
              decoration: InputDecoration(
                labelText: 'Description / Reason *',
                labelStyle: const TextStyle(color: AppTheme.slate500, fontSize: 14),
                prefixIcon: const Icon(Icons.description_outlined, size: 20, color: AppTheme.slate400),
                filled: true,
                fillColor: AppTheme.slate50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.navy900, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (v) => v!.trim().isEmpty ? 'Description required' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCredit ? AppTheme.successColor : AppTheme.errorColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _saving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text(isCredit ? 'Record Credit' : 'Record Debit',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeToggle({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppTheme.slate50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.2) : AppTheme.slate200,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: selected ? color : AppTheme.slate500, size: 18),
            ),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: selected ? color : AppTheme.navy900)),
            Text(sublabel, style: TextStyle(fontSize: 11, color: selected ? color.withValues(alpha: 0.8) : AppTheme.slate500)),
          ],
        ),
      ),
    );
  }
}
