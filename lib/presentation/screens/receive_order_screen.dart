import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/order.dart';
import '../../core/models/order_item.dart';
import '../../core/models/product_batch.dart';
import '../../core/repositories/order_repository.dart';
import '../../core/repositories/batch_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/orders_provider.dart';

class ReceiveOrderScreen extends ConsumerStatefulWidget {
  final Order order;

  const ReceiveOrderScreen({super.key, required this.order});

  @override
  ConsumerState<ReceiveOrderScreen> createState() => _ReceiveOrderScreenState();
}

class _ReceiveOrderScreenState extends ConsumerState<ReceiveOrderScreen> {
  late List<OrderItem> _orderItems;
  late List<TextEditingController> _receivedQtyControllers;
  late List<TextEditingController> _expiryControllers;
  late List<TextEditingController> _costPriceControllers;
  late List<DateTime?> _selectedExpiries;

  @override
  void initState() {
    super.initState();
    _loadOrderItems();
  }

  Future<void> _loadOrderItems() async {
    final repo = OrderRepository();
    final items = await repo.getOrderItems(widget.order.id);
    setState(() {
      _orderItems = items;
      _receivedQtyControllers = List.generate(items.length, (_) => TextEditingController());
      _expiryControllers = List.generate(items.length, (_) => TextEditingController());
      _costPriceControllers = List.generate(items.length, (_) => TextEditingController());
      _selectedExpiries = List.filled(items.length, null);
    });
  }

  @override
  void dispose() {
    for (var ctrl in _receivedQtyControllers) {
      ctrl.dispose();
    }
    for (var ctrl in _expiryControllers) {
      ctrl.dispose();
    }
    for (var ctrl in _costPriceControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _selectExpiryDate(int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
    );
    if (picked != null) {
      setState(() {
        _selectedExpiries[index] = picked;
        _expiryControllers[index].text = picked.toString().split(' ')[0];
      });
    }
  }

  Future<void> _receiveOrder() async {
    try {
      final orderRepo = OrderRepository();
      final batchRepo = BatchRepository();

      for (int i = 0; i < _orderItems.length; i++) {
        final receivedQty = int.tryParse(_receivedQtyControllers[i].text) ?? 0;
        final costPrice = double.tryParse(_costPriceControllers[i].text) ?? 0;
        final expiry = _selectedExpiries[i];

        if (receivedQty > 0 && costPrice > 0 && expiry != null) {
          final batch = ProductBatch(
            id: 0,
            productId: _orderItems[i].productId,
            quantity: receivedQty,
            costPrice: costPrice,
            expiryDate: expiry,
            createdAt: DateTime.now(),
          );
          await batchRepo.create(batch);

          final updatedItem = _orderItems[i].copyWith(receivedQuantity: receivedQty);
          await orderRepo.updateOrderItem(updatedItem);
        }
      }

      final allReceived = _orderItems.every((item) =>
          int.tryParse(_receivedQtyControllers[_orderItems.indexOf(item)].text) == item.quantity);

      if (allReceived) {
        final updatedOrder = widget.order.copyWith(
          status: 'received',
          receivedAt: DateTime.now(),
        );
        await orderRepo.update(updatedOrder);
      }

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ref.invalidate(ordersProvider);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order received successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_orderItems.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryColor, AppTheme.primaryLight],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 12,
              right: 20,
              bottom: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Receive Order',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            widget.order.orderNumber,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.textSecondary.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Supplier', widget.order.supplierName),
                        const SizedBox(height: 8),
                        _buildInfoRow('Total Amount', '₹${widget.order.totalAmount.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _buildInfoRow('Expected Delivery', widget.order.expectedDelivery.toString().split(' ')[0]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Order Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(height: 12),
                  ..._orderItems.asMap().entries.map((e) => _buildItemReceiveForm(e.key, e.value)).toList(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _receiveOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('CONFIRM RECEIPT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildItemReceiveForm(int index, OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Ordered: ${item.quantity}', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          _buildReceiveField('Received Qty', _receivedQtyControllers[index], Icons.inventory_2_outlined, TextInputType.number),
          const SizedBox(height: 12),
          _buildReceiveField('Cost Price (₹)', _costPriceControllers[index], Icons.payments_outlined, TextInputType.number),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _selectExpiryDate(index),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expiry Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary.withValues(alpha: 0.7))),
                const SizedBox(height: 6),
                TextField(
                  controller: _expiryControllers[index],
                  enabled: false,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryColor),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiveField(String label, TextEditingController controller, IconData icon, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary.withValues(alpha: 0.7))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppTheme.primaryColor),
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
