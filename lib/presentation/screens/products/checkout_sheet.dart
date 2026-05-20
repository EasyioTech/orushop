part of '../products_screen.dart';

// ── Unified Checkout Sheet ────────────────────────────────────────────────────

class _CheckoutSheet extends ConsumerStatefulWidget {
  final String initialStep;
  const _CheckoutSheet({this.initialStep = 'cart'});

  @override
  ConsumerState<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<_CheckoutSheet> {
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
                  ? _CartStep(
                      key: const ValueKey('cart'),
                      cartItems: cartItems,
                      onProceed: () => setState(() => _step = 'checkout'),
                      bottomPad: bottomPad,
                    )
                  : _CheckoutStep(
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