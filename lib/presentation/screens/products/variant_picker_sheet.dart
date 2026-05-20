part of '../products_screen.dart';

// ── Variant picker ─────────────────────────────────────────────────────────────

class _VariantSelection {
  final int variantId;
  final String label;
  final double price;
  final double qty;
  const _VariantSelection({
    required this.variantId,
    required this.label,
    required this.price,
    required this.qty,
  });
}

class _VariantPickerSheet extends StatefulWidget {
  final Product product;
  const _VariantPickerSheet({required this.product});

  @override
  State<_VariantPickerSheet> createState() => _VariantPickerSheetState();
}

class _VariantPickerSheetState extends State<_VariantPickerSheet> {
  List<ProductVariant> _variants = [];
  ProductVariant? _selected;
  final _qtyController = TextEditingController(text: '1');
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    VariantRepository().getByProduct(widget.product.id).then((v) {
      if (mounted) setState(() { _variants = v; _loading = false; });
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.slate300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.product.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Choose a variant', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_variants.isEmpty)
            const Text('No variants found.', style: TextStyle(color: AppTheme.textSecondary))
          else ...[
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _variants.map((v) {
                    final isSelected = _selected?.id == v.id;
                    final outOfStock = v.stock <= 0;
                    return GestureDetector(
                      onTap: outOfStock ? null : () => setState(() => _selected = v),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: outOfStock
                              ? AppTheme.slate100
                              : isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: outOfStock
                                ? AppTheme.slate200
                                : isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              v.label,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: outOfStock
                                    ? AppTheme.slate400
                                    : isSelected ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              outOfStock ? 'Out of stock' : '₹${v.price.toStringAsFixed(0)}  •  ${v.stock.toStringAsFixed(0)} left',
                              style: TextStyle(
                                fontSize: 11,
                                color: outOfStock
                                    ? AppTheme.slate400
                                    : isSelected ? Colors.white70 : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Qty:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _selected == null ? null : () {
                    final qty = double.tryParse(_qtyController.text) ?? 1.0;
                    if (qty <= 0) return;
                    if (qty > _selected!.stock) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Only ${_selected!.stock.toStringAsFixed(0)} in stock'),
                        backgroundColor: AppTheme.errorColor,
                      ));
                      return;
                    }
                    Navigator.pop(context, _VariantSelection(
                      variantId: _selected!.id,
                      label: _selected!.label,
                      price: _selected!.price,
                      qty: qty,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
