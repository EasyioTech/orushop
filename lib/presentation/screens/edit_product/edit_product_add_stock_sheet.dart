part of '../edit_product_screen.dart';

// ── Add Stock Bottom Sheet ──────────────────────────────────────────────────

class _AddStockBottomSheet extends ConsumerStatefulWidget {
  final Product product;
  final VoidCallback? onStockAdded;

  const _AddStockBottomSheet({required this.product, this.onStockAdded});

  @override
  ConsumerState<_AddStockBottomSheet> createState() => _AddStockBottomSheetState();
}

class _AddStockBottomSheetState extends ConsumerState<_AddStockBottomSheet> {
  final _qtyController = TextEditingController();
  final _costController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _imeiController = TextEditingController();
  DateTime? _expiryDate;
  bool _loading = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _costController.dispose();
    _serialNumberController.dispose();
    _imeiController.dispose();
    super.dispose();
  }

  void _incrementQty(double amount) {
    final current = double.tryParse(_qtyController.text) ?? 0.0;
    _qtyController.text = (current + amount).toString();
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _submit() async {
    final qty = double.tryParse(_qtyController.text.trim()) ?? 0.0;
    final cost = double.tryParse(_costController.text.trim()) ?? 0;

    if (qty <= 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter how many items came in')),
      );
      return;
    }
    if (cost <= 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the buy price')),
      );
      return;
    }

    // Serialized template requires IMEI or serial number
    if (widget.product.template == ProductTemplate.serialized) {
      final serial = _serialNumberController.text.trim();
      final imei = _imeiController.text.trim();
      if (serial.isEmpty && imei.isEmpty) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter serial number or IMEI')),
        );
        return;
      }
    }

    final expiry = _expiryDate ?? DateTime.now().add(const Duration(days: 365));

    setState(() => _loading = true);
    try {
      await ProductCrudService().addStock(
        productId: widget.product.id,
        quantity: qty,
        costPrice: cost,
        expiryDate: expiry,
        batchNumber: null,
        template: widget.product.template,
        serialNumber: _serialNumberController.text.trim(),
        imei: _imeiController.text.trim(),
      );

      HapticFeedback.mediumImpact();
      widget.onStockAdded?.call();
      if (!mounted) return;
      ref.invalidate(productsProvider);
      ref.invalidate(paginatedProductsProvider);
      ref.invalidate(expiringBatchesProvider);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$qty items added ✓'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppTheme.slate300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('How many items came in?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
          Text(widget.product.name, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),

          // Quantity
          const Text('Number of items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.slate300),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final amt in [10.0, 50.0, 100.0])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: () => _incrementQty(amt),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text('+${amt.toInt()}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Cost Price
          const Text('Buy Price', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _costController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              hintText: '0.00',
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
          const SizedBox(height: 20),

          // Serial/IMEI fields (serialized products only)
          if (widget.product.template == ProductTemplate.serialized) ...[
            const Text('Serial Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _serialNumberController,
              keyboardType: TextInputType.text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Enter serial number',
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Text('IMEI (if applicable)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _imeiController,
              keyboardType: TextInputType.text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Enter IMEI',
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Expiry Date (optional)
          GestureDetector(
            onTap: _pickExpiry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    _expiryDate == null
                        ? 'Expiry date (not required)'
                        : 'Expires: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _expiryDate == null ? AppTheme.textSecondary : AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (_expiryDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _expiryDate = null),
                      child: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 6,
                shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
              child: _loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Add Stock ✓', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
