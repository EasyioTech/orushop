import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/sale.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/refund_provider.dart';

class RefundRequestScreen extends ConsumerStatefulWidget {
  final Sale sale;

  const RefundRequestScreen({
    required this.sale,
    super.key,
  });

  @override
  ConsumerState<RefundRequestScreen> createState() => _RefundRequestScreenState();
}

class _RefundRequestScreenState extends ConsumerState<RefundRequestScreen> {
  late TextEditingController _amountController;
  late TextEditingController _reasonController;
  late TextEditingController _notesController;
  String? _selectedReason;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.sale.finalAmount.toStringAsFixed(0));
    _reasonController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitRefund() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final reason = _selectedReason ?? _reasonController.text;

    if (amount <= 0 || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (amount > widget.sale.finalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refund amount cannot exceed sale amount')),
      );
      return;
    }

    final result = await ref.read(refundProvider.notifier).createRefund(
          saleId: widget.sale.id,
          refundAmount: amount,
          reason: reason,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refund request created successfully')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create refund request')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final refundState = ref.watch(refundProvider);
    final isLoading = refundState?['loading'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refund Request'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sale Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sale ID', style: Theme.of(context).textTheme.bodySmall),
                        Text('#${widget.sale.id}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sale Amount', style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          CurrencyFormatter.format(widget.sale.finalAmount),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Refund Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Refund Amount *',
                hintText: '0',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedReason,
              decoration: const InputDecoration(
                labelText: 'Reason *',
                border: OutlineInputBorder(),
              ),
              items: [
                'Defective Product',
                'Changed Mind',
                'Wrong Item',
                'Quality Issues',
                'Other',
              ]
                  .map((reason) => DropdownMenuItem(
                        value: reason,
                        child: Text(reason),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedReason = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Additional Details',
                hintText: 'Enter custom reason or details',
                border: const OutlineInputBorder(),
                enabled: _selectedReason == 'Other',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Additional notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
                    onPressed: isLoading ? null : _submitRefund,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit Refund'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

