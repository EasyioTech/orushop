part of '../products_screen.dart';

// ── Checkout Step ─────────────────────────────────────────────────────────────

class _CheckoutStep extends StatelessWidget {
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

  const _CheckoutStep({
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
                  child: _SummaryCol(label: 'Subtotal', value: '₹${subtotal.toStringAsFixed(0)}'),
                ),
                if (quickDiscount > 0) ...[
                  Container(width: 1, height: 28, color: AppTheme.borderColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCol(
                      label: 'Discount',
                      value: '−₹${quickDiscount.toStringAsFixed(0)}',
                      valueColor: AppTheme.successColor,
                    ),
                  ),
                ],
                Container(width: 1, height: 28, color: AppTheme.borderColor),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCol(
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
                _DiscountChip(label: 'None', active: quickDiscount == 0, onTap: () => onDiscountChanged(0.0)),
                const SizedBox(width: 8),
                _DiscountChip(label: '−₹10', active: quickDiscount == 10, onTap: () => onDiscountChanged(quickDiscount == 10 ? 0.0 : 10.0)),
                const SizedBox(width: 8),
                _DiscountChip(label: '−₹50', active: quickDiscount == 50, onTap: () => onDiscountChanged(quickDiscount == 50 ? 0.0 : 50.0)),
                const SizedBox(width: 8),
                _DiscountChip(
                  label: '−5%',
                  active: quickDiscount == (subtotal * 0.05).toInt(),
                  onTap: () {
                    final v = (subtotal * 0.05).toInt();
                    onDiscountChanged(quickDiscount == v ? 0.0 : v.toDouble());
                  },
                ),
                const SizedBox(width: 8),
                _DiscountChip(
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
                _PayBtn(label: 'Cash', icon: Icons.payments_rounded, color: const Color(0xFF16A34A), selected: selectedPaymentMethod == 'Cash', onTap: () => onPaymentSelected('Cash')),
                const SizedBox(width: 8),
                _PayBtn(label: 'UPI', icon: Icons.qr_code_scanner_rounded, color: AppTheme.accentColor, selected: selectedPaymentMethod == 'UPI', onTap: () => onPaymentSelected('UPI')),
                const SizedBox(width: 8),
                _PayBtn(label: 'Card', icon: Icons.credit_card_rounded, color: const Color(0xFF2563EB), selected: selectedPaymentMethod == 'Card', onTap: () => onPaymentSelected('Card')),
                const SizedBox(width: 8),
                _PayBtn(label: 'Khata', icon: Icons.book_rounded, color: const Color(0xFFD97706), selected: selectedPaymentMethod == 'Khata', onTap: () => onPaymentSelected('Khata')),
                const SizedBox(width: 8),
                _PayBtn(label: 'Other', icon: Icons.more_horiz_rounded, color: AppTheme.textSecondary, selected: selectedPaymentMethod == 'Other', onTap: () => onPaymentSelected('Other')),
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

class _SummaryCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _SummaryCol({required this.label, required this.value, this.valueColor, this.bold = false});

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

class _DiscountChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _DiscountChip({required this.label, required this.active, required this.onTap});

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

class _PayBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _PayBtn({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});

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
