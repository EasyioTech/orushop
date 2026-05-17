import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orushops/core/models/cart_item.dart';
import 'package:orushops/core/models/customer.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/products_provider.dart';
import 'package:orushops/providers/cart_provider.dart';
import 'package:orushops/providers/checkout_provider.dart';
import 'package:orushops/providers/sale_provider.dart' show customerRepositoryProvider;
import 'package:orushops/core/repositories/owner_provider.dart';

import '../../receipt_screen.dart';

class CheckoutSheet extends ConsumerStatefulWidget {
  final String initialStep;
  const CheckoutSheet({super.key, this.initialStep = 'cart'});

  @override
  ConsumerState<CheckoutSheet> createState() => CheckoutSheetState();
}

class CheckoutSheetState extends ConsumerState<CheckoutSheet> {
  late String _step; // 'cart' | 'checkout'
  String? _selectedPaymentMethod;
  String? _customerPhone;
  String? _customerName;
  double _quickDiscount = 0;
  double _amountPaid = 0;
  String _receivedPaymentMode = 'Cash';


  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
  }

  Future<void> _processSale(double subtotal, List<CartItem> items) async {
    final finalAmount = subtotal - _quickDiscount;

    // MANDATORY: Customer validation before sale
    if (_customerPhone == null || _customerPhone!.trim().length < 10) {
      HapticFeedback.heavyImpact();
      _showCustomerDialog(() => _processSale(subtotal, items));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer mobile number is required to proceed'),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final checkoutState = ref.read(checkoutProvider);
    if (checkoutState.isLoading) return;

    // Unfocus keyboard before processing to avoid IME layout issues and warnings
    FocusScope.of(context).unfocus();

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
      // Note: analytics revision and stock decrement are now handled globally in checkoutProvider
      ref.read(productSearchQueryProvider.notifier).state = '';
      ref.read(cartProvider.notifier).clearCart();

      Map<String, dynamic>? ownerDetails;
      try {
        ownerDetails = await ref.read(ownerDetailsProvider.future);
      } catch (_) {
        ownerDetails = null;
      }
      if (!mounted) return;
      Navigator.pop(context); // close sheet
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
      final error = ref.read(checkoutProvider).error;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to save sale'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showCustomerDialog(VoidCallback onSaved) {
    final phoneCtrl = TextEditingController(text: _customerPhone);
    final nameCtrl = TextEditingController(text: _customerName);
    final customerRepo = ref.read(customerRepositoryProvider);
    final phoneFocusNode = FocusNode();
    List<Customer> suggestions = [];

    Future.delayed(const Duration(milliseconds: 350), () {
      if (phoneFocusNode.canRequestFocus) {
        phoneFocusNode.requestFocus();
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final double bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset > 0 ? bottomInset + 16 : 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.borderColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Header Title & Close button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.person_add_rounded, color: AppTheme.primaryColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer Lookup',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Search existing or add new details',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.slate100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Phone Number Field Block
                  const Text(
                    'MOBILE NUMBER *',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.slate500,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneCtrl,
                    focusNode: phoneFocusNode,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, letterSpacing: 1.0),
                    decoration: InputDecoration(
                      hintText: '00000 00000',
                      hintStyle: TextStyle(color: AppTheme.slate300, letterSpacing: 1.0),
                      prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppTheme.primaryColor, size: 20),
                      prefixText: '+91 ',
                      prefixStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 16),
                      filled: true,
                      fillColor: AppTheme.slate50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.slate200, width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2.0),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: (val) async {
                      if (val.length >= 3) {
                        final results = await customerRepo.searchByQuery(val);
                        setD(() => suggestions = results);
                      } else {
                        setD(() => suggestions = []);
                      }
                    },
                  ),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15), width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: suggestions.length,
                          separatorBuilder: (_, index) => const Divider(height: 1, thickness: 0.5, color: AppTheme.slate100),
                          itemBuilder: (ctx, i) {
                            final c = suggestions[i];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
                                child: Text(
                                  c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              title: Text(
                                c.name,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.slate900),
                              ),
                              subtitle: Text(
                                c.phone,
                                style: const TextStyle(fontSize: 11, color: AppTheme.slate500, fontWeight: FontWeight.w500),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppTheme.slate300),
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                setD(() {
                                  String p = c.phone.replaceAll(RegExp(r'\D'), '');
                                  if (p.length > 10 && p.startsWith('91')) p = p.substring(2);
                                  phoneCtrl.text = p;
                                  nameCtrl.text = c.name;
                                  suggestions = [];
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // 4. Customer Name Field Block
                  const Text(
                    'CUSTOMER NAME (OPTIONAL)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.slate500,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    decoration: InputDecoration(
                      hintText: 'e.g. John Doe',
                      hintStyle: TextStyle(color: AppTheme.slate300),
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.slate400, size: 20),
                      filled: true,
                      fillColor: AppTheme.slate50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.slate200, width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2.0),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),

                   // 6. Action Button (Only show when keyboard is closed to prevent float & squeeze)
                  if (bottomInset == 0) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          String phone = phoneCtrl.text.trim();
                          final name = nameCtrl.text.trim();

                          phone = phone.replaceAll(RegExp(r'\D'), '');
                          if (phone.length == 12 && phone.startsWith('91')) {
                            phone = phone.substring(2);
                          }

                          if (phone.length != 10) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid 10-digit mobile number'),
                                backgroundColor: AppTheme.errorColor,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            _customerPhone = phone;
                            _customerName = name.isEmpty ? null : name;
                          });
                          Navigator.pop(context);
                          onSaved();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          shadowColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('PROCEED TO PAYMENT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_ios_rounded, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final isLoading = ref.watch(checkoutProvider).isLoading;
    final finalAmount = subtotal - _quickDiscount;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),

          // Header row with step indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
            child: Row(
              children: [
                if (_step == 'checkout')
                  GestureDetector(
                    onTap: () => setState(() => _step = 'cart'),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
                    ),
                  ),
                Text(
                  _step == 'cart' ? 'Cart  (${cartItems.length} items)' : 'Checkout',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          // Body — animated step switch
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(
                  begin: _step == 'checkout'
                      ? const Offset(1, 0)
                      : const Offset(-1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: _step == 'cart'
                  ? CartStep(
                      key: const ValueKey('cart'),
                      cartItems: cartItems,
                      onProceed: () => setState(() => _step = 'checkout'),
                      bottomPad: bottomPad,
                    )
                  : CheckoutStep(
                      key: const ValueKey('checkout'),
                      cartItems: cartItems,
                      subtotal: subtotal,
                      finalAmount: finalAmount,
                      isLoading: isLoading,
                      quickDiscount: _quickDiscount,
                      selectedPaymentMethod: _selectedPaymentMethod,
                      customerName: _customerName,
                      customerPhone: _customerPhone,
                      receivedPaymentMode: _receivedPaymentMode,
                      amountPaid: _amountPaid,
                      bottomPad: bottomPad,
                      onDiscountChanged: (v) => setState(() => _quickDiscount = v),
                      onPaymentSelected: (method) {
                        setState(() => _selectedPaymentMethod = method);
                        _showCustomerDialog(() {
                          if (_selectedPaymentMethod != null) {
                            _processSale(subtotal, cartItems);
                          }
                        });
                      },
                      onConfirm: () => _processSale(subtotal, cartItems),
                      onAmountPaidChanged: (v) => setState(() => _amountPaid = v),
                      onReceivedModeChanged: (v) => setState(() => _receivedPaymentMode = v),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cart Step ─────────────────────────────────────────────────────────────────

class CartStep extends ConsumerWidget {
  final List<CartItem> cartItems;
  final VoidCallback onProceed;
  final double bottomPad;

  const CartStep({
    super.key,
    required this.cartItems,
    required this.onProceed,
    required this.bottomPad,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cartItems.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 48, color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              const SizedBox(height: 12),
              const Text('Cart is empty', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Item list
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: cartItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => SheetCartItem(item: cartItems[i]),
          ),
        ),

        // Total + Proceed button
        Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.5))),
          ),
          child: Row(
            children: [
              Consumer(
                builder: (_, ref, _) {
                  final subtotal = ref.watch(cartSubtotalProvider);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Subtotal', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                      Text(
                        '₹${subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.5),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onProceed,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Proceed to Checkout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Cart Item Row inside sheet ─────────────────────────────────────────────────

class SheetCartItem extends ConsumerWidget {
  final CartItem item;
  const SheetCartItem({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartNotifier = ref.read(cartProvider.notifier);
    final maxStock = ref.watch(productByIdProvider(item.productId)).value?.displayQuantity ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${item.unitPrice.toStringAsFixed(0)} / unit',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Qty stepper
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StepBtn(
                icon: item.quantity <= 1 ? Icons.delete_outline_rounded : Icons.remove,
                color: item.quantity <= 1 ? AppTheme.errorColor : AppTheme.textPrimary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (item.quantity <= 1) {
                    cartNotifier.removeItem(item.productId);
                  } else {
                    cartNotifier.updateQuantity(item.productId, item.quantity - 1);
                  }
                },
              ),
              SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    item.quantity == item.quantity.truncateToDouble()
                        ? '${item.quantity.toInt()}'
                        : item.quantity.toStringAsFixed(2),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              StepBtn(
                icon: Icons.add,
                color: item.quantity < maxStock ? AppTheme.primaryColor : AppTheme.textSecondary,
                onTap: item.quantity < maxStock
                    ? () {
                        HapticFeedback.lightImpact();
                        cartNotifier.updateQuantity(item.productId, item.quantity + 1);
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(width: 10),
          Text(
            '₹${item.totalPrice.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

class StepBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const StepBtn({super.key, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: onTap != null ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: onTap != null
              ? [BoxShadow(color: AppTheme.primaryDark.withValues(alpha: 0.06), blurRadius: 4)]
              : null,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Checkout Step ─────────────────────────────────────────────────────────────

class CheckoutStep extends StatelessWidget {
  final List<CartItem> cartItems;
  final double subtotal;
  final double finalAmount;
  final bool isLoading;
  final double quickDiscount;
  final String? selectedPaymentMethod;
  final String? customerName;
  final String? customerPhone;
  final String receivedPaymentMode;
  final double amountPaid;
  final double bottomPad;
  final ValueChanged<double> onDiscountChanged;
  final ValueChanged<String> onPaymentSelected;
  final VoidCallback onConfirm;
  final ValueChanged<double> onAmountPaidChanged;
  final ValueChanged<String> onReceivedModeChanged;

  const CheckoutStep({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.finalAmount,
    required this.isLoading,
    required this.quickDiscount,
    required this.selectedPaymentMethod,
    required this.customerName,
    required this.customerPhone,
    required this.receivedPaymentMode,
    required this.amountPaid,
    required this.bottomPad,
    required this.onDiscountChanged,
    required this.onPaymentSelected,
    required this.onConfirm,
    required this.onAmountPaidChanged,
    required this.onReceivedModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bill summary card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SummaryCol(label: 'Subtotal', value: '₹${subtotal.toStringAsFixed(0)}'),
                ),
                if (quickDiscount > 0) ...[
                  Container(width: 1, height: 28, color: AppTheme.borderColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCol(
                      label: 'Discount',
                      value: '−₹${quickDiscount.toStringAsFixed(0)}',
                      valueColor: AppTheme.successColor,
                    ),
                  ),
                ],
                Container(width: 1, height: 28, color: AppTheme.borderColor),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCol(
                    label: 'Total',
                    value: '₹${finalAmount.toStringAsFixed(0)}',
                    valueColor: AppTheme.accentColor,
                    bold: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Discount
          const Text('Quick Discount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                DiscountChip(label: 'None', active: quickDiscount == 0, onTap: () => onDiscountChanged(0.0)),
                const SizedBox(width: 8),
                DiscountChip(label: '−₹10', active: quickDiscount == 10, onTap: () => onDiscountChanged(quickDiscount == 10 ? 0.0 : 10.0)),
                const SizedBox(width: 8),
                DiscountChip(label: '−₹50', active: quickDiscount == 50, onTap: () => onDiscountChanged(quickDiscount == 50 ? 0.0 : 50.0)),
                const SizedBox(width: 8),
                DiscountChip(
                  label: '−5%',
                  active: quickDiscount == (subtotal * 0.05).toInt(),
                  onTap: () {
                    final v = (subtotal * 0.05).toInt();
                    onDiscountChanged(quickDiscount == v ? 0.0 : v.toDouble());
                  },
                ),
                const SizedBox(width: 8),
                DiscountChip(
                  label: '−10%',
                  active: quickDiscount == (subtotal * 0.10).toInt(),
                  onTap: () {
                    final v = (subtotal * 0.10).toInt();
                    onDiscountChanged(quickDiscount == v ? 0.0 : v.toDouble());
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Payment Mode
          const Text('Select Payment Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          const Text(
            'Tap a payment mode to open customer details and confirm the sale.',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                PayBtn(label: 'Cash', icon: Icons.payments_rounded, color: const Color(0xFF16A34A), selected: selectedPaymentMethod == 'Cash', onTap: () => onPaymentSelected('Cash')),
                const SizedBox(width: 8),
                PayBtn(label: 'UPI', icon: Icons.qr_code_scanner_rounded, color: AppTheme.accentColor, selected: selectedPaymentMethod == 'UPI', onTap: () => onPaymentSelected('UPI')),
                const SizedBox(width: 8),
                PayBtn(label: 'Card', icon: Icons.credit_card_rounded, color: const Color(0xFF2563EB), selected: selectedPaymentMethod == 'Card', onTap: () => onPaymentSelected('Card')),
                const SizedBox(width: 8),
                PayBtn(label: 'Khata', icon: Icons.book_rounded, color: const Color(0xFFD97706), selected: selectedPaymentMethod == 'Khata', onTap: () => onPaymentSelected('Khata')),
                const SizedBox(width: 8),
                PayBtn(label: 'Other', icon: Icons.more_horiz_rounded, color: AppTheme.textSecondary, selected: selectedPaymentMethod == 'Other', onTap: () => onPaymentSelected('Other')),
              ],
            ),
          ),

          // Khata partial payment section
          if (selectedPaymentMethod == 'Khata') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Amount Received Today?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                  const SizedBox(height: 10),
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (v) => onAmountPaidChanged(double.tryParse(v) ?? 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: receivedPaymentMode,
                              isExpanded: true,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                              items: ['Cash', 'UPI', 'Card', 'Other']
                                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                                  .toList(),
                              onChanged: (v) { if (v != null) onReceivedModeChanged(v); },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Remaining', style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                          Text(
                            '₹${finalAmount - amountPaid}',
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

          const SizedBox(height: 20),

          // Customer display (if set)
          if (customerPhone != null || customerName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, color: AppTheme.accentColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      [customerName, customerPhone].where((v) => v != null && v.isNotEmpty).join(' · '),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

          // Pay Now button (only if payment already selected)
          if (selectedPaymentMethod != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        'Pay ₹$finalAmount  →',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class SummaryCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const SummaryCol({super.key, required this.label, required this.value, this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class DiscountChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const DiscountChip({super.key, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.successColor.withValues(alpha: 0.1) : AppTheme.backgroundColor,
          border: Border.all(color: active ? AppTheme.successColor : Colors.transparent),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? AppTheme.successColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class PayBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const PayBtn({super.key, required this.label, required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.mediumImpact(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppTheme.borderColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? Colors.white : color.withValues(alpha: 0.8), size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
