part of '../inventory_screen.dart';

class _AddStockBottomSheet extends ConsumerStatefulWidget {
  final dynamic product;
  const _AddStockBottomSheet({required this.product});

  @override
  ConsumerState<_AddStockBottomSheet> createState() =>
      _AddStockBottomSheetState();
}

class _AddStockBottomSheetState extends ConsumerState<_AddStockBottomSheet> {
  final _qtyController = TextEditingController();
  final _costController = TextEditingController();
  final _batchController = TextEditingController();
  final _qtyFocusNode = FocusNode();
  DateTime _expiry = DateTime.now().add(const Duration(days: 365));

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _costController.dispose();
    _batchController.dispose();
    _qtyFocusNode.dispose();
    super.dispose();
  }

  void _incrementQty(int amount) {
    final current = int.tryParse(_qtyController.text) ?? 0;
    _qtyController.text = (current + amount).toString();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24,
        right: 24,
        top: 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add Stock: ${widget.product.name}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QUANTITY',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: AppTheme.slate500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _qtyController,
                        focusNode: _qtyFocusNode,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          filled: true,
                          fillColor: AppTheme.slate50,
                          contentPadding: const EdgeInsets.symmetric(vertical: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: AppTheme.slate200, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COST PRICE',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: AppTheme.slate500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _costController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.successColor,
                        ),
                        decoration: InputDecoration(
                          prefixText: '₹',
                          prefixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          hintText: '0',
                          filled: true,
                          fillColor: AppTheme.slate50,
                          contentPadding: const EdgeInsets.symmetric(vertical: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: AppTheme.slate200, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: AppTheme.successColor, width: 2.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _QuickAddButton(
                    label: '+10',
                    onTap: () => _incrementQty(10),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickAddButton(
                    label: '+50',
                    onTap: () => _incrementQty(50),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickAddButton(
                    label: '+100',
                    onTap: () => _incrementQty(100),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Batch Number',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _batchController,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter batch number',
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    prefixIcon: const Icon(Icons.tag_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Expiry Date',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _expiry,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (date != null) setState(() => _expiry = date);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      DateFormat('MMMM d, yyyy').format(_expiry),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'CONFIRM ADD STOCK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    final cost = double.tryParse(_costController.text) ?? 0;

    if (qty <= 0 || cost <= 0) {
      HapticFeedback.heavyImpact();
      return;
    }

    try {
      final service = ProductCrudService();
      await service.addStock(
        productId: widget.product.id,
        quantity: qty,
        costPrice: cost,
        expiryDate: _expiry,
        batchNumber: _batchController.text.trim().isEmpty ? null : _batchController.text.trim(),
      );

      HapticFeedback.mediumImpact();
      if (mounted) {
        ref.invalidate(productsProvider);
        ref.invalidate(lowStockProductsProvider);
        ref.invalidate(expiringBatchesProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

