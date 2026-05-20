part of '../customer_detail_screen.dart';

class _EditCustomerSheet extends ConsumerStatefulWidget {
  final KhataCustomer customer;
  const _EditCustomerSheet({required this.customer});

  @override
  ConsumerState<_EditCustomerSheet> createState() => _EditCustomerSheetState();
}

class _EditCustomerSheetState extends ConsumerState<_EditCustomerSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _limitCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.customer.name);
    _phoneCtrl = TextEditingController(text: widget.customer.phone);
    _addressCtrl = TextEditingController(text: widget.customer.address ?? '');
    _notesCtrl = TextEditingController(text: widget.customer.notes ?? '');
    _limitCtrl = TextEditingController(text: widget.customer.creditLimit > 0 ? widget.customer.creditLimit.toStringAsFixed(0) : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _addressCtrl.dispose();
    _notesCtrl.dispose(); _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final updated = widget.customer.copyWith(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      creditLimit: double.tryParse(_limitCtrl.text) ?? 0,
    );
    final ok = await ref.read(khataListProvider.notifier).updateCustomer(updated);
    if (!mounted) return;
    if (ok) {
      ref.read(khataDetailProvider(widget.customer.id).notifier).load();
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
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
          const Row(
            children: [
              Icon(Icons.edit_rounded, color: AppTheme.navy900, size: 24),
              SizedBox(width: 12),
              Text(
                'Edit Customer Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy900),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          _field(_nameCtrl, 'Customer Name', Icons.person_outline_rounded),
          const SizedBox(height: 16),
          _field(_phoneCtrl, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _field(_limitCtrl, 'Credit Limit ₹', Icons.credit_card_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 16),
          _field(_addressCtrl, 'Location Address', Icons.location_on_outlined),
          const SizedBox(height: 16),
          _field(_notesCtrl, 'Internal Notes', Icons.note_outlined, maxLines: 2),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navy900,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _saving
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Update Account', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.navy900),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.slate500, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: AppTheme.slate400),
        filled: true,
        fillColor: AppTheme.slate50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.navy900, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── STATEMENT & REMINDERS SHEET ──────────────────────────────────────────────

