// ignore_for_file: invalid_use_of_protected_member
part of '../edit_product_screen.dart';

extension _EditProductVariants on _EditProductScreenState {
  Widget _buildVariantEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.grid_view_rounded, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            _label('Size / Color Variants'),
            const Spacer(),
            Text('${_variants.length} combos', style: TextStyle(fontSize: 12, color: AppTheme.slate500)),
          ],
        ),
        const SizedBox(height: 12),

        if (_variants.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.slate400),
                const SizedBox(width: 8),
                Text('No variants yet. Add below.', style: TextStyle(color: AppTheme.slate500, fontSize: 13)),
              ],
            ),
          )
        else
          ...List.generate(_variants.length, (i) {
            final v = _variants[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('₹${v.price.toStringAsFixed(0)}  ·  ${v.stock % 1 == 0 ? v.stock.toInt() : v.stock.toStringAsFixed(2)} in stock',
                          style: TextStyle(fontSize: 12, color: AppTheme.slate600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor, size: 20),
                    onPressed: () {
                      setState(() {
                        if (v.id > 0) _deletedVariantIds.add(v.id.toString());
                        _variants.removeAt(i);
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Variant', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newVariantSizeCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Size (S, M, L…)',
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _newVariantColorCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Color (Red…)',
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newVariantPriceCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Price',
                        prefixText: '₹ ',
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _newVariantStockCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Stock',
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addNewVariantLocally,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _addNewVariantLocally() {
    final size = _newVariantSizeCtrl.text.trim();
    final color = _newVariantColorCtrl.text.trim();
    if (size.isEmpty && color.isEmpty) return;
    final price = double.tryParse(_newVariantPriceCtrl.text) ?? widget.product.price.toDouble();
    final stock = double.tryParse(_newVariantStockCtrl.text) ?? 0.0;
    final now = DateTime.now();
    final sku = '${widget.product.sku}-${[size, color].where((s) => s.isNotEmpty).join('-')}';
    setState(() {
      _variants.add(ProductVariant(
        id: 0,
        productId: widget.product.id,
        size: size,
        color: color,
        sku: sku,
        price: price,
        stock: stock,
        costPrice: widget.product.costPrice,
        createdAt: now,
        updatedAt: now,
      ));
      _newVariantSizeCtrl.clear();
      _newVariantColorCtrl.clear();
      _newVariantPriceCtrl.clear();
      _newVariantStockCtrl.clear();
    });
  }
}
