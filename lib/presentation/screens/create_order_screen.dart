import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/order.dart';
import '../../core/models/order_item.dart';
import '../../core/repositories/order_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/orders_provider.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  late TextEditingController _supplierController;
  late TextEditingController _expectedDeliveryController;
  late TextEditingController _notesController;

  final List<_OrderItemEntry> _items = [];
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _supplierController = TextEditingController();
    _expectedDeliveryController = TextEditingController();
    _notesController = TextEditingController();
    _selectedDate = DateTime.now().add(const Duration(days: 7));
    _expectedDeliveryController.text = _selectedDate.toString().split(' ')[0];
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _expectedDeliveryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _expectedDeliveryController.text = picked.toString().split(' ')[0];
      });
    }
  }

  Future<void> _createOrder() async {
    final supplier = _supplierController.text.trim();

    if (supplier.isEmpty || _items.isEmpty || _selectedDate == null) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all fields and add items'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    try {
      final totalAmount = _items.fold<double>(0, (sum, item) => sum + (item.quantity * item.unitPrice));
      final orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      final order = Order(
        id: 0,
        orderNumber: orderNumber,
        supplierName: supplier,
        totalAmount: totalAmount,
        status: 'pending',
        expectedDelivery: _selectedDate!,
        createdAt: DateTime.now(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      final items = _items
          .asMap()
          .entries
          .map((e) => OrderItem(
                id: 0,
                orderId: 0,
                productId: e.value.productId,
                productName: e.value.productName,
                quantity: e.value.quantity,
                unitPrice: e.value.unitPrice,
                totalPrice: e.value.quantity * e.value.unitPrice,
              ))
          .toList();

      final repo = OrderRepository();
      await repo.create(order, items);

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ref.invalidate(ordersProvider);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order created successfully'),
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
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'New Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
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
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField('Supplier Name', _supplierController, Icons.business_outlined),
                        const SizedBox(height: 20),
                        _buildDateField(),
                        const SizedBox(height: 20),
                        _buildField('Notes (Optional)', _notesController, Icons.notes_outlined, maxLines: 3),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add Item'),
                              onPressed: () => _showAddItemDialog(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_items.isEmpty)
                          Center(
                            child: Text('No items added', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          )
                        else
                          Column(
                            children: _items.asMap().entries.map((e) => _buildItemTile(e.key)).toList(),
                          ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _createOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('CREATE ORDER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
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

  Widget _buildField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary.withValues(alpha: 0.7))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryColor),
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Expected Delivery', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary.withValues(alpha: 0.7))),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: TextField(
            controller: _expectedDeliveryController,
            enabled: false,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.calendar_today, size: 20, color: AppTheme.primaryColor),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddItemDialog() {
    final productNameCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: productNameCtrl,
              decoration: const InputDecoration(labelText: 'Product Name', hintText: 'e.g., Sugar 5kg'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity', hintText: 'e.g., 100'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Unit Price (₹)', hintText: 'e.g., 45.50'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final name = productNameCtrl.text.trim();
              final qty = int.tryParse(quantityCtrl.text) ?? 0;
              final price = double.tryParse(priceCtrl.text) ?? 0;

              if (name.isEmpty || qty <= 0 || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please fill all fields correctly'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }

              setState(() {
                _items.add(_OrderItemEntry(
                  productId: 0,
                  productName: name,
                  quantity: qty,
                  unitPrice: price,
                ));
              });
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(int index) {
    final item = _items[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text('${item.quantity} × ₹${item.unitPrice.toStringAsFixed(2)} = ₹${(item.quantity * item.unitPrice).toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: () => setState(() => _items.removeAt(index)),
          ),
        ],
      ),
    );
  }
}

class _OrderItemEntry {
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  _OrderItemEntry({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });
}

