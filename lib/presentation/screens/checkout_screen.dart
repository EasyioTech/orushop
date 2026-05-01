import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/models/cart_item.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/batch_provider.dart' show availableBatchesProvider;
import 'receipt_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final List<CartItem> items;
  final int subtotal;
  final String? initialPaymentMethod;
  final int? initialDiscount;

  const CheckoutScreen({
    required this.items,
    required this.subtotal,
    this.initialPaymentMethod,
    this.initialDiscount,
    super.key,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late String _selectedPaymentMethod;
  late int _discountAmount;
  late TextEditingController _discountController;
  late Map<int, int> _selectedBatches;
  bool _batchesInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod = widget.initialPaymentMethod ?? 'Cash';
    _discountAmount = widget.initialDiscount ?? 0;
    _discountController = TextEditingController(text: _discountAmount.toString());
    _selectedBatches = {};
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeAutoFIFOBatches());
  }

  Future<void> _scanQRForSKU() async {
    // TODO: Integrate QR scanner (camera_plugin, qr_code_scanner)
    // For now, show simple dialog to manually enter SKU
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Item by SKU'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Enter or scan SKU'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _initializeAutoFIFOBatches() {
    if (_batchesInitialized) return;
    _batchesInitialized = true;

    for (final item in widget.items) {
      if (_selectedBatches.containsKey(item.productId)) continue;

      final batchesAsync = ref.read(availableBatchesProvider(item.productId));
      batchesAsync.whenData((batches) {
        final availableBatches = batches.where((b) => b.quantity >= item.quantity).toList();
        if (availableBatches.isNotEmpty) {
          availableBatches.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
          if (mounted) {
            setState(() => _selectedBatches[item.productId] = availableBatches.first.id);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  void _applyDiscount() {
    final discount = int.tryParse(_discountController.text) ?? 0;
    if (discount > widget.subtotal) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discount cannot exceed subtotal')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _discountAmount = discount);
    Navigator.pop(context);
  }

  Future<void> _showDiscountDialog() async {
    _discountController.text = _discountAmount.toString();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Discount'),
        content: TextField(
          controller: _discountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Discount Amount',
            hintText: '0',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _applyDiscount,
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSale() async {
    final finalAmount = widget.subtotal - _discountAmount;
    final state = ref.read(checkoutProvider);
    if (state?['loading'] == true) return;

    HapticFeedback.mediumImpact();
    final success = await ref.read(checkoutProvider.notifier).saveSale(
          items: widget.items,
          subtotal: widget.subtotal,
          discountAmount: _discountAmount,
          finalAmount: finalAmount,
          paymentMethod: _selectedPaymentMethod,
          selectedBatches: _selectedBatches,
        );

    if (!mounted) return;

    if (success != null) {
      HapticFeedback.heavyImpact();
      ref.read(cartProvider.notifier).clearCart();
      final sale = success['sale'];
      final items = success['items'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            sale: sale,
            items: items,
          ),
        ),
      );
    } else {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save sale')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);
    final isLoading = checkoutState?['loading'] == true;
    final finalAmount = widget.subtotal - _discountAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanQRForSKU,
            tooltip: 'Scan SKU',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('Order Summary'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Column(
                children: widget.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: Theme.of(context).textTheme.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${item.quantity} × ${CurrencyFormatter.format(item.unitPrice)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              CurrencyFormatter.format(item.quantity * item.unitPrice),
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _BatchSelector(
                          productId: item.productId,
                          quantity: item.quantity,
                          onBatchSelected: (batchId) {
                            setState(() => _selectedBatches[item.productId] = batchId);
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle('Discount'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discount Amount',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(_discountAmount.toDouble()),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _showDiscountDialog,
                    icon: const Icon(Icons.edit),
                    label: const Text('Apply'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle('Payment Method'),
            Row(
              children: [
                Expanded(
                  child: _PaymentButton(
                    label: 'CASH',
                    isSelected: _selectedPaymentMethod == 'Cash',
                    color: AppTheme.primaryColor,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedPaymentMethod = 'Cash');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PaymentButton(
                    label: 'UPI / QR',
                    isSelected: _selectedPaymentMethod == 'UPI',
                    color: AppTheme.primaryColor,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedPaymentMethod = 'UPI');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PaymentButton(
                    label: 'CARD',
                    isSelected: _selectedPaymentMethod == 'Card',
                    color: AppTheme.primaryColor,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedPaymentMethod = 'Card');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        CurrencyFormatter.format(widget.subtotal.toDouble()),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (_discountAmount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Discount',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.warningColor,
                              ),
                        ),
                        Text(
                          '−${CurrencyFormatter.format(_discountAmount.toDouble())}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.warningColor,
                              ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        CurrencyFormatter.format(finalAmount.toDouble()),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _confirmSale,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Confirm Sale'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _PaymentButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _PaymentButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? color : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? color : Colors.grey[300],
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? color : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchSelector extends ConsumerWidget {
  final int productId;
  final int quantity;
  final Function(int) onBatchSelected;

  const _BatchSelector({
    required this.productId,
    required this.quantity,
    required this.onBatchSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(availableBatchesProvider(productId));

    return batchesAsync.when(
      data: (batches) {
        if (batches.isEmpty) {
          return Text(
            'No available batches',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.errorColor),
          );
        }

        final availableBatches = batches.where((b) => b.quantity >= quantity).toList();

        if (availableBatches.isEmpty) {
          return Text(
            'Insufficient quantity in available batches',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.errorColor),
          );
        }

        return DropdownButton<int>(
          isExpanded: true,
          hint: Text(
            'Select batch',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          items: availableBatches.map((batch) {
            final daysUntilExpiry = batch.expiryDate.difference(DateTime.now()).inDays;
            return DropdownMenuItem<int>(
              value: batch.id,
              child: Text(
                'Batch #${batch.id} - Expires in $daysUntilExpiry days (${batch.quantity} available)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }).toList(),
          onChanged: (batchId) {
            if (batchId != null) {
              onBatchSelected(batchId);
            }
          },
        );
      },
      loading: () => const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stack) => Text(
        'Error loading batches',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.errorColor),
      ),
    );
  }
}
