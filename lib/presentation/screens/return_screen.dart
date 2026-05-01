import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/sale.dart';
import '../../core/models/sale_item.dart';
import '../../core/models/return.dart';
import '../../core/models/return_item.dart';
import '../../core/repositories/sale_repository.dart';
import '../../core/repositories/return_repository.dart';
import '../../core/utils/currency_formatter.dart';

class ReturnScreen extends ConsumerStatefulWidget {
  const ReturnScreen({super.key});

  @override
  ConsumerState<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends ConsumerState<ReturnScreen> {
  final SaleRepository _saleRepository = SaleRepository();
  final ReturnRepository _returnRepository = ReturnRepository();
  
  Sale? _selectedSale;
  Map<int, int> _returnQuantities = {};
  String _returnReason = 'Defective';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectSale() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final sales = await _saleRepository.getByDateRange(thirtyDaysAgo, DateTime.now());

    if (!mounted) return;

    final selected = await showDialog<Sale>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Sale'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              return ListTile(
                title: Text('Sale #${sale.id}'),
                subtitle: Text(sale.createdAt.toString()),
                onTap: () => Navigator.pop(context, sale),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedSale = selected;
        _returnQuantities = {};
      });
    }
  }

  Future<void> _processReturn() async {
    if (_selectedSale == null || _returnQuantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select sale and items to return')),
      );
      return;
    }

    try {
      final saleItems = await _saleRepository.getSaleItems(_selectedSale!.id);
      double refundAmount = 0;
      final batchRestoration = <Map<int, int>>[];

      for (final returnQty in _returnQuantities.entries) {
        final item = saleItems.firstWhere((i) => i.id == returnQty.key);
        refundAmount += (item.unitPrice * returnQty.value);

        for (final batchId in item.batchIds) {
          batchRestoration.add({batchId: returnQty.value});
        }
      }

      final return_ = Return(
        id: 0,
        saleId: _selectedSale!.id,
        refundAmount: refundAmount,
        reason: _returnReason,
        createdAt: DateTime.now(),
      );

      final returnId = await _returnRepository.createReturn(return_);

      for (final returnQty in _returnQuantities.entries) {
        final returnItem = ReturnItem(
          id: 0,
          returnId: returnId,
          saleItemId: returnQty.key,
          quantity: returnQty.value,
        );
        await _returnRepository.addReturnItem(returnItem);
      }

      await _returnRepository.restoreInventory(batchRestoration);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Return processed. Refund: ${CurrencyFormatter.format(refundAmount)}')),
      );

      setState(() {
        _selectedSale = null;
        _returnQuantities = {};
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Process Return'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('Select Sale'),
            Card(
              child: ListTile(
                title: _selectedSale == null
                    ? const Text('No sale selected')
                    : Text('Sale #${_selectedSale!.id}'),
                subtitle: _selectedSale == null
                    ? null
                    : Text('${CurrencyFormatter.format(_selectedSale!.totalAmount)} - ${_selectedSale!.createdAt}'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: _selectSale,
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedSale != null) ...[
              _SectionTitle('Select Items to Return'),
              FutureBuilder<List<SaleItem>>(
                future: _saleRepository.getSaleItems(_selectedSale!.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = snapshot.data!;
                  return Column(
                    children: items.map((item) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
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
                                          'Item #${item.id}',
                                          style: Theme.of(context).textTheme.titleSmall,
                                        ),
                                        Text(
                                          'Qty: ${item.quantity}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(item.unitPrice),
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Slider(
                                min: 0,
                                max: item.quantity.toDouble(),
                                divisions: item.quantity,
                                value: (_returnQuantities[item.id] ?? 0).toDouble(),
                                label: (_returnQuantities[item.id] ?? 0).toString(),
                                onChanged: (value) {
                                  setState(() {
                                    if (value == 0) {
                                      _returnQuantities.remove(item.id);
                                    } else {
                                      _returnQuantities[item.id] = value.toInt();
                                    }
                                  });
                                },
                              ),
                              Text(
                                'Return: ${_returnQuantities[item.id] ?? 0} items',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              _SectionTitle('Return Reason'),
              DropdownButton<String>(
                isExpanded: true,
                value: _returnReason,
                items: ['Defective', 'Changed Mind', 'Wrong Item', 'Damaged', 'Other']
                    .map((reason) => DropdownMenuItem(
                          value: reason,
                          child: Text(reason),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _returnReason = value ?? _returnReason);
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _processReturn,
                      child: const Text('Process Return'),
                    ),
                  ),
                ],
              ),
            ],
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
