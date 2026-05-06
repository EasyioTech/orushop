import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/core/models/cart_item.dart';
import 'package:orushops/providers/cart_provider.dart';
import 'package:orushops/providers/checkout_provider.dart';
import 'package:orushops/providers/held_carts_provider.dart';
import 'package:orushops/providers/products_provider.dart';
import 'package:orushops/providers/navigation_provider.dart';
import 'package:orushops/core/repositories/owner_provider.dart';
import 'package:orushops/core/models/khata_customer.dart';
import 'package:orushops/providers/khata_provider.dart';
import 'receipt_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  String? _selectedPaymentMethod;
  String? _customerPhone;
  String? _customerName;
  int _quickDiscount = 0;
  bool _isDiscountExpanded = false;
    double _amountPaid = 0;
  String _receivedPaymentMode = 'Cash';
  List<KhataCustomer> _customerSuggestions = [];

  void _confirmSale(int subtotal, List<CartItem> items) async {
    if (items.isEmpty) return;

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment mode to complete checkout'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_selectedPaymentMethod == 'Khata' && (_customerPhone == null || _customerPhone!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer phone and name are required for Khata payment'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      _showCustomerDetailsDialog();
      return;
    }

    await _processSale(subtotal, items);
  }



  void _showCustomerDetailsDialog() {
    final phoneController = TextEditingController(text: _customerPhone);
    final nameController = TextEditingController(text: _customerName);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter customer details to track this sale.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g. 9876543210',
                    prefixIcon: const Icon(Icons.phone_android_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (val) async {
                    if (val.length >= 3) {
                      final repo = ref.read(khataRepositoryProvider);
                      final results = await repo.getAllCustomers(search: val);
                      setDialogState(() {
                        _customerSuggestions = results;
                      });
                    } else {
                      setDialogState(() {
                        _customerSuggestions = [];
                      });
                    }
                  },
                ),
                if (_customerSuggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _customerSuggestions.length,
                      itemBuilder: (context, index) {
                        final customer = _customerSuggestions[index];
                        return ListTile(
                          dense: true,
                          title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(customer.phone),
                          onTap: () {
                            phoneController.text = customer.phone;
                            nameController.text = customer.name;
                            setDialogState(() {
                              _customerSuggestions = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Customer Name',
                    hintText: 'e.g. John Doe',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _customerPhone = phoneController.text;
                  _customerName = nameController.text;
                  _customerSuggestions = [];
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Details'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processSale(int subtotal, List<CartItem> items) async {
    final finalAmount = subtotal - _quickDiscount;
    final state = ref.read(checkoutProvider);
    if (state.isLoading) return;

    HapticFeedback.mediumImpact();
    final success = await ref.read(checkoutProvider.notifier).saveSale(
          items: items,
          subtotal: subtotal,
          discountAmount: _quickDiscount,
          finalAmount: finalAmount,
          paymentMethod: _selectedPaymentMethod!,
          selectedBatches: {},
          customerPhone: _customerPhone,
          customerName: _customerName,
          amountPaid: _selectedPaymentMethod == 'Khata' ? _amountPaid : null,
          receivedPaymentMode: _selectedPaymentMethod == 'Khata' ? _receivedPaymentMode : null,
        );

    if (!mounted) return;

    if (success != null) {
      HapticFeedback.heavyImpact();
      
      // Update local stock immediately
      final soldItems = {for (var item in items) item.productId: item.quantity};
      ref.read(paginatedProductsProvider.notifier).decrementStock(soldItems);
      
      // Clear search so items with 0 stock (now filtered) don't confuse search
      ref.read(productSearchQueryProvider.notifier).state = '';
      
      ref.read(cartProvider.notifier).clearCart();
      Map<String, dynamic>? ownerDetails;
      try {
        ownerDetails = await ref.read(ownerDetailsProvider.future);
      } catch (e) {
        ownerDetails = null;
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            sale: success['sale'],
            items: success['items'],
            storeName: ownerDetails?['storeName'] as String?,
            storePhone: ownerDetails?['phoneNumber'] as String?,
            storeAddress: ownerDetails?['address'] as String?,
            upiId: ownerDetails?['upiId'] as String?,
          ),
        ),
      );
    } else {
      HapticFeedback.heavyImpact();
      final error = ref.read(checkoutProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to save sale'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _holdCart(List<CartItem> items) {
    if (items.isEmpty) return;
    HapticFeedback.mediumImpact();
    ref.read(heldCartsProvider.notifier).holdCart(items);
    ref.read(cartProvider.notifier).clearCart();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Bill saved successfully', style: TextStyle(fontSize: 16, color: Colors.white)),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final checkoutState = ref.watch(checkoutProvider);
    final isLoading = checkoutState.isLoading;

    // Stock validation is now handled inside _processSale on button click
    // This allows the user to see the checkout button even if there are potential stock issues

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      bottomNavigationBar: cartItems.isEmpty ? null : _buildBottomActions(subtotal, cartItems, isLoading, false),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 80,
            floating: true,
            pinned: true,
            backgroundColor: AppTheme.backgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Checkout',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
            ),
            actions: [
              if (cartItems.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _holdCart(cartItems),
                  icon: const Icon(Icons.pause_circle_outline_rounded, size: 20),
                  label: const Text('Pause', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              const SizedBox(width: 8),
            ],
            bottom: null,
          ),

          // Content
          if (cartItems.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Cart is empty',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Switch to Shop tab (index 0)
                        ref.read(navigationIndexProvider.notifier).state = 0;
                        
                        // If this screen was pushed as a separate route, pop it
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('Go to Home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(child: _buildCustomerSection(context)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = cartItems[index];
                    return _CartItemTile(item: item);
                  },
                  childCount: cartItems.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerSection(BuildContext context) {
    final hasCustomer = _customerPhone != null && _customerPhone!.isNotEmpty;
    final displayName = _customerName != null && _customerName!.isNotEmpty 
        ? _customerName 
        : (hasCustomer ? 'Customer' : 'Walk-in Customer');

    return InkWell(
      onTap: _showCustomerDetailsDialog,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasCustomer
                ? AppTheme.primaryColor.withValues(alpha: 0.3)
                : AppTheme.borderColor.withValues(alpha: 0.3)
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hasCustomer
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasCustomer
                    ? Icons.person_rounded 
                    : Icons.person_outline_rounded, 
                color: AppTheme.primaryColor, 
                size: 20
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (hasCustomer)
                    Text(
                      _customerPhone!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    hasCustomer
                        ? 'Tap to edit details'
                        : 'Tap to add customer details',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_rounded, size: 18, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(int subtotal, List<CartItem> cartItems, bool isLoading, bool hasStockError) {
    final finalAmount = subtotal - _quickDiscount;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Horizontal Bill Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Subtotal', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('₹$subtotal', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
                if (_quickDiscount > 0) ...[
                  Container(width: 1, height: 24, color: AppTheme.borderColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Discount', style: TextStyle(color: AppTheme.successColor, fontSize: 11, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('−₹$_quickDiscount', style: const TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Discount Chips (Dropdown)
          _buildExpandableSection(
            title: 'Quick Discount',
            isExpanded: _isDiscountExpanded,
            onToggle: () => setState(() => _isDiscountExpanded = !_isDiscountExpanded),
            selectedValue: _quickDiscount > 0 ? '−₹$_quickDiscount' : 'None',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickDiscountChip(label: 'None', value: 0, isActive: _quickDiscount == 0, onTap: () => setState(() { _quickDiscount = 0; _isDiscountExpanded = false; })),
                  const SizedBox(width: 8),
                  _QuickDiscountChip(label: '−₹10', value: 10, isActive: _quickDiscount == 10, onTap: () => setState(() { _quickDiscount = _quickDiscount == 10 ? 0 : 10; _isDiscountExpanded = false; })),
                  const SizedBox(width: 8),
                  _QuickDiscountChip(label: '−₹50', value: 50, isActive: _quickDiscount == 50, onTap: () => setState(() { _quickDiscount = _quickDiscount == 50 ? 0 : 50; _isDiscountExpanded = false; })),
                  const SizedBox(width: 8),
                  _QuickDiscountChip(label: '−5%', value: (subtotal * 0.05).toInt(), isActive: _quickDiscount == (subtotal * 0.05).toInt(), onTap: () => setState(() { _quickDiscount = _quickDiscount == (subtotal * 0.05).toInt() ? 0 : (subtotal * 0.05).toInt(); _isDiscountExpanded = false; })),
                  const SizedBox(width: 8),
                  _QuickDiscountChip(label: '−10%', value: (subtotal * 0.10).toInt(), isActive: _quickDiscount == (subtotal * 0.10).toInt(), onTap: () => setState(() { _quickDiscount = _quickDiscount == (subtotal * 0.10).toInt() ? 0 : (subtotal * 0.10).toInt(); _isDiscountExpanded = false; })),
                ],
              ),
            ),
          ),
          
          Divider(color: AppTheme.borderColor.withValues(alpha: 0.3), height: 16),

          // 3. Payment Mode (Always visible)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Payment Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _PaymentButton(
                      label: 'Cash',
                      icon: Icons.payments_rounded,
                      activeColor: const Color(0xFF16A34A),
                      isSelected: _selectedPaymentMethod == 'Cash',
                      onTap: () => setState(() => _selectedPaymentMethod = 'Cash'),
                    ),
                    const SizedBox(width: 8),
                    _PaymentButton(
                      label: 'UPI',
                      icon: Icons.qr_code_scanner_rounded,
                      isSelected: _selectedPaymentMethod == 'UPI',
                      onTap: () => setState(() => _selectedPaymentMethod = 'UPI'),
                    ),
                    const SizedBox(width: 8),
                    _PaymentButton(
                      label: 'Card',
                      icon: Icons.credit_card_rounded,
                      activeColor: const Color(0xFF2563EB),
                      isSelected: _selectedPaymentMethod == 'Card',
                      onTap: () => setState(() => _selectedPaymentMethod = 'Card'),
                    ),
                    const SizedBox(width: 8),
                    _PaymentButton(
                      label: 'Khata',
                      icon: Icons.book_rounded,
                      activeColor: const Color(0xFFD97706),
                      isSelected: _selectedPaymentMethod == 'Khata',
                      onTap: () {
                        setState(() => _selectedPaymentMethod = 'Khata');
                        if (_customerPhone == null || _customerPhone!.isEmpty) {
                          _showCustomerDetailsDialog();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _PaymentButton(
                      label: 'Other',
                      icon: Icons.more_horiz_rounded,
                      activeColor: AppTheme.textSecondary,
                      isSelected: _selectedPaymentMethod == 'Other',
                      onTap: () => setState(() => _selectedPaymentMethod = 'Other'),
                    ),
                  ],
                ),
              ),
              if (_selectedPaymentMethod == 'Khata') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payments_outlined, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Amount Received Today?',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: '0',
                                prefixText: '₹ ',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (val) {
                                setState(() {
                                  _amountPaid = double.tryParse(val) ?? 0;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _receivedPaymentMode,
                                  isExpanded: true,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                  items: ['Cash', 'UPI', 'Card', 'Other'].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _receivedPaymentMode = val);
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Remaining', style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                              Text(
                                '₹${finalAmount - _amountPaid}',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.errorColor, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // 3. Action Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total to Pay', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    '₹$finalAmount',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      color: AppTheme.primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _holdCart(cartItems),
                    icon: const Icon(Icons.pause_circle_outline_rounded, color: AppTheme.textSecondary, size: 22),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.backgroundColor,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: isLoading ? null : () => _confirmSale(subtotal, cartItems),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('Checkout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
    String? selectedValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                    if (selectedValue != null && selectedValue.isNotEmpty && !isExpanded) ...[
                      const SizedBox(height: 2),
                      Text(selectedValue, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
                    ]
                  ],
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
            child: child,
          ),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class _PaymentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color? activeColor;
  final VoidCallback onTap;

  const _PaymentButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveActiveColor = activeColor ?? AppTheme.primaryColor;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? effectiveActiveColor : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? effectiveActiveColor : AppTheme.borderColor.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              color: isSelected 
                ? Colors.white 
                : (activeColor?.withValues(alpha: 0.8) ?? AppTheme.textSecondary), 
              size: 18
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary, 
                fontWeight: FontWeight.w700, 
                fontSize: 13
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickDiscountChip extends StatelessWidget {
  final String label;
  final int value;
  final bool isActive;
  final VoidCallback onTap;

  const _QuickDiscountChip({
    required this.label,
    required this.value,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.successColor.withValues(alpha: 0.1) : AppTheme.backgroundColor,
          border: Border.all(
            color: isActive ? AppTheme.successColor : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? AppTheme.successColor : AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartNotifier = ref.read(cartProvider.notifier);

    final productAsync = ref.watch(productByIdProvider(item.productId));
    // Default to 0 instead of null to prevent adding more if product data is missing or loading
    final maxStock = productAsync.value?.displayQuantity ?? 0;

    return Dismissible(
      key: ValueKey(item.productId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        cartNotifier.removeItem(item.productId);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            _CartItemImage(productId: item.productId, productName: item.productName),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '₹${item.unitPrice.toStringAsFixed(0)} / unit',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ...[
                        const SizedBox(width: 8),
                        Text(
                          '($maxStock in stock)',
                          style: TextStyle(
                            color: (item.quantity > maxStock) ? AppTheme.errorColor : AppTheme.textSecondary.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _QuantityControl(
              quantity: item.quantity,
              maxStock: maxStock,
              onChanged: (newQuantity) {
                if (newQuantity > maxStock) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Only $maxStock units available'),
                      backgroundColor: AppTheme.errorColor,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                  return;
                }
                cartNotifier.updateQuantity(item.productId, newQuantity);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final int? maxStock;
  final Function(int) onChanged;

  const _QuantityControl({
    required this.quantity,
    this.maxStock,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: quantity > 1
                ? () {
                    HapticFeedback.lightImpact();
                    onChanged(quantity - 1);
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: quantity > 1 ? Colors.white : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: quantity > 1
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                    : null,
              ),
              child: Icon(Icons.remove, size: 16, color: quantity > 1 ? AppTheme.textPrimary : AppTheme.textSecondary.withValues(alpha: 0.3)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              quantity.toString(),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
          GestureDetector(
            onTap: (maxStock == null || quantity < maxStock!)
                ? () {
                    HapticFeedback.lightImpact();
                    onChanged(quantity + 1);
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (maxStock == null || quantity < maxStock!) ? Colors.white : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: (maxStock == null || quantity < maxStock!)
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                    : null,
              ),
              child: Icon(
                Icons.add, 
                size: 16, 
                color: (maxStock == null || quantity < maxStock!) 
                  ? AppTheme.textPrimary 
                  : AppTheme.textSecondary.withValues(alpha: 0.3)
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemImage extends ConsumerWidget {
  final int productId;
  final String productName;

  const _CartItemImage({
    required this.productId,
    required this.productName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(
      productsProvider.select(
        (state) => state.whenData(
          (products) => products.firstWhere(
            (p) => p.id == productId,
            orElse: () => throw Exception('Product not found'),
          ),
        ),
      ),
    );

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: productAsync.when(
        data: (product) {
          final String? imageUrl = product.imageUrl;
          final String? imagePath = product.imagePath;

          if (imageUrl != null && imageUrl.isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: 48,
                height: 48,
                errorBuilder: (context, error, stackTrace) => _buildInitial(productName),
              ),
            );
          } else if (imagePath != null && imagePath.isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                width: 48,
                height: 48,
                errorBuilder: (context, error, stackTrace) => _buildInitial(productName),
              ),
            );
          }

          return _buildInitial(productName);
        },
        loading: () => _buildInitial(productName),
        error: (_, _) => _buildInitial(productName),
      ),
    );
  }

  Widget _buildInitial(String name) {
    return Center(
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 18,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

