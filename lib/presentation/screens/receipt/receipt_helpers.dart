// ignore_for_file: invalid_use_of_protected_member
part of '../receipt_screen.dart';

extension _ReceiptScreenHelpers on _ReceiptScreenState {
  // ── GST helpers ───────────────────────────────────────────────────────────
  /// Returns the GST-inclusive tax amount for an item (price already includes tax).
  double _itemGst(SaleItem item) {
    if (item.taxRate <= 0) return 0.0;
    return item.totalPrice * item.taxRate / (100 + item.taxRate);
  }

  /// Total GST across all items, pro-rated for any discount applied.
  double _totalGst() {
    final grossGst = widget.items.fold(0.0, (sum, i) => sum + _itemGst(i));
    if (grossGst == 0) return 0.0;
    // Pro-rate GST if a discount was applied
    if (widget.sale.totalAmount > 0 && widget.sale.discountAmount > 0) {
      return grossGst * (widget.sale.finalAmount / widget.sale.totalAmount);
    }
    return grossGst;
  }

  // ── Receipt paper ─────────────────────────────────────────────────────────
  Widget _buildSuccessBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
          const SizedBox(width: 6),
          Text(
            'PAYMENT SUCCESSFUL',
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF16A34A),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPaper(ThemeData theme) {
    final bool hasCustomer = (widget.sale.customerName?.isNotEmpty ?? false) ||
        (widget.sale.customerPhone?.isNotEmpty ?? false);
    final double gst = _totalGst();
    final bool showGst = gst > 0.01;
    final bool showDiscount = widget.sale.discountAmount > 0;

    return CustomPaint(
      painter: ReceiptPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Success badge ────────────────────────────────────────────
            Center(child: _buildSuccessBanner(theme)),
            const SizedBox(height: 18),

            // ── 2. Store header ─────────────────────────────────────────────
            _buildStoreHeader(theme),
            const SizedBox(height: 16),
            _DashedDivider(),
            const SizedBox(height: 12),

            // ── 3. Receipt # and timestamp ─────────────────────────────────
            _buildReceiptMetadata(theme),
            const SizedBox(height: 12),

            // ── 4. Customer (at top, before items) ─────────────────────────
            if (hasCustomer) ...[
              _DashedDivider(),
              const SizedBox(height: 10),
              _buildCustomerSection(theme),
              const SizedBox(height: 10),
            ],

            // ── 5. Items table ──────────────────────────────────────────────
            _DashedDivider(),
            const SizedBox(height: 10),
            _buildItemsHeader(theme),
            const SizedBox(height: 6),
            ...widget.items.asMap().entries.map((e) => _buildItemRow(theme, e.value, e.key + 1)),
            const SizedBox(height: 10),

            // ── 6. Totals section ───────────────────────────────────────────
            _DashedDivider(),
            const SizedBox(height: 12),
            _buildTotalsSection(theme, gst, showGst, showDiscount),
            const SizedBox(height: 16),
            _DashedDivider(),
            const SizedBox(height: 12),

            // ── 7. Payment + UPI QR ─────────────────────────────────────────
            _buildPaymentSection(theme),
            if (widget.sale.paymentMethod.toLowerCase() == 'upi' && widget.upiId != null)
              _buildUpiSection(theme),

            // ── 8. Thank you ────────────────────────────────────────────────
            const SizedBox(height: 28),
            _buildThankYouSection(theme),

            // ── 9. OruShops promo banner ────────────────────────────────────
            const SizedBox(height: 20),
            _buildOruShopsBanner(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.storefront_rounded, size: 22, color: AppTheme.primaryColor),
        ),
        const SizedBox(height: 8),
        Text(
          widget.storeName ?? 'OruShops',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.3, fontSize: 18),
        ),
        if (widget.storeAddress?.isNotEmpty ?? false) ...[
          const SizedBox(height: 3),
          Text(
            widget.storeAddress!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.slate500, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (widget.storePhone?.isNotEmpty ?? false) ...[
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_outlined, size: 11, color: AppTheme.slate400),
              const SizedBox(width: 3),
              Text(
                widget.storePhone!,
                style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.slate500, fontSize: 11),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildReceiptMetadata(ThemeData theme) {
    final dt = widget.sale.createdAt;
    final date = DateFormat('dd MMM yyyy').format(dt);
    final time = DateFormat('hh:mm a').format(dt);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RECEIPT NO', style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, letterSpacing: 1.2, color: AppTheme.slate400, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('#${widget.sale.id.toString().padLeft(6, '0')}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 14)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('DATE & TIME', style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, letterSpacing: 1.2, color: AppTheme.slate400, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(date, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
            Text(time, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.slate500, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerSection(ThemeData theme) {
    final name = widget.sale.customerName;
    final phone = widget.sale.customerPhone;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: const Icon(Icons.person_rounded, size: 16, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BILLED TO', style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, letterSpacing: 1.2, color: AppTheme.slate400, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            if (name?.isNotEmpty ?? false)
              Text(name!, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            if (phone?.isNotEmpty ?? false)
              Text(phone!, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.slate500)),
          ],
        ),
      ],
    );
  }

  // Shared column flex ratios — must match between header and each row.
  // ITEM:5  QTY:2  RATE:3  AMOUNT:3
  static const int _colItem = 5;
  static const int _colQty  = 2;
  static const int _colRate = 3;
  static const int _colAmt  = 3;

  Widget _buildItemsHeader(ThemeData theme) {
    const hStyle = TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppTheme.slate400);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Expanded(flex: _colItem, child: Text('ITEM', style: hStyle)),
          const Expanded(flex: _colQty,  child: Text('QTY',    style: hStyle, textAlign: TextAlign.center)),
          const Expanded(flex: _colRate, child: Text('RATE',   style: hStyle, textAlign: TextAlign.right)),
          const Expanded(flex: _colAmt,  child: Text('AMOUNT', style: hStyle, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildItemRow(ThemeData theme, SaleItem item, int index) {
    final name = item.productName ?? 'Item #$index';
    final qty  = item.quantity % 1 == 0
        ? item.quantity.toInt().toString()
        : item.quantity.toStringAsFixed(2);
    final hsnTag = (item.hsnCode?.isNotEmpty ?? false) ? ' (${item.hsnCode})' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: _colItem,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name$hsnTag',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                if (item.taxRate > 0)
                  Text('GST ${item.taxRate.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 9, color: AppTheme.slate400)),
              ],
            ),
          ),
          Expanded(
            flex: _colQty,
            child: Text(qty,
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                textAlign: TextAlign.center),
          ),
          Expanded(
            flex: _colRate,
            child: Text(CurrencyFormatter.format(item.unitPrice),
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                textAlign: TextAlign.right),
          ),
          Expanded(
            flex: _colAmt,
            child: Text(CurrencyFormatter.format(item.totalPrice),
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection(ThemeData theme, double gst, bool showGst, bool showDiscount) {
    final cgst = gst / 2;
    final sgst = gst / 2;
    return Column(
      children: [
        _SummaryRow(label: 'Subtotal', value: CurrencyFormatter.format(widget.sale.totalAmount)),
        if (showDiscount)
          _SummaryRow(
            label: 'Discount',
            value: '− ${CurrencyFormatter.format(widget.sale.discountAmount)}',
            valueColor: const Color(0xFFE53935),
          ),
        if (showGst) ...[
          _SummaryRow(label: 'CGST', value: CurrencyFormatter.format(cgst), valueColor: AppTheme.slate600),
          _SummaryRow(label: 'SGST', value: CurrencyFormatter.format(sgst), valueColor: AppTheme.slate600),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GRAND TOTAL', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.3)),
              Text(
                CurrencyFormatter.format(widget.sale.finalAmount),
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.primaryColor, fontSize: 22),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection(ThemeData theme) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _InfoChip(label: 'Payment', value: widget.sale.paymentMethod, icon: Icons.payments_outlined),
        if (widget.sale.transactionId?.isNotEmpty ?? false)
          _InfoChip(label: 'Txn ID', value: widget.sale.transactionId!, icon: Icons.receipt_long_outlined),
      ],
    );
  }

  Widget _buildUpiSection(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Text('SCAN TO PAY', style: theme.textTheme.titleSmall?.copyWith(letterSpacing: 2, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.slate200)),
          child: QrImageView(
            data: _actionService.generateUpiString(widget.upiId!, widget.storeName ?? 'OruShops', widget.sale.finalAmount),
            version: QrVersions.auto,
            size: 150.0,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.primaryColor),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.primaryColor),
          ),
        ),
        const SizedBox(height: 10),
        Text(widget.upiId!, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildThankYouSection(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Thank you for shopping with us!',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.slate600),
        ),
        const SizedBox(height: 2),
        Text(
          'Visit us again',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.slate400, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  IconData _getBannerIcon(String? iconName) {
    switch (iconName) {
      case 'shopping_bag': return Icons.shopping_bag_rounded;
      case 'star': return Icons.star_rounded;
      case 'favorite': return Icons.favorite_rounded;
      case 'local_mall': return Icons.local_mall_rounded;
      case 'discount': return Icons.discount_rounded;
      case 'emoji_emotions': return Icons.emoji_emotions_rounded;
      case 'storefront':
      default:
        return Icons.storefront_rounded;
    }
  }

  Widget _buildOruShopsBanner(ThemeData theme) {
    final ownerDetails = ref.read(ownerDetailsStreamProvider).value;
    final title = ownerDetails?['receiptBannerTitle'] ?? 'Powered by OruShops';
    final subtitle = ownerDetails?['receiptBannerSubtitle'] ?? 'Smart POS for Indian Retailers';
    final url = ownerDetails?['receiptBannerUrl'] ?? 'orushops.in';
    final style = ownerDetails?['receiptBannerStyle'] ?? 'classic';
    
    final customColorVal = ownerDetails?['receiptBannerColor'] as int?;
    final customTextColorVal = ownerDetails?['receiptBannerTextColor'] as int?;
    final customIconStr = ownerDetails?['receiptBannerIcon'] as String?;

    final Color primary = customColorVal != null ? Color(customColorVal) : AppTheme.primaryColor;
    final Color? textPrimary = customTextColorVal != null ? Color(customTextColorVal) : null;
    final IconData iconData = _getBannerIcon(customIconStr);

    if (title.toString().trim().isEmpty) return const SizedBox.shrink();

    if (style == 'minimal') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.slate200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppTheme.slate100, shape: BoxShape.circle),
              child: Icon(iconData, color: primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: textPrimary ?? AppTheme.slate900, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.2),
                  ),
                  if (subtitle.toString().trim().isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(color: textPrimary?.withValues(alpha: 0.7) ?? AppTheme.slate500, fontSize: 10),
                    ),
                ],
              ),
            ),
            if (url.toString().trim().isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(url, style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 10)),
              ),
          ],
        ),
      );
    } else if (style == 'dark') {
      final darkBg = customColorVal != null ? primary : const Color(0xFF064E3B);
      final txtColor = textPrimary ?? Colors.white;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: darkBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: txtColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(iconData, color: txtColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: txtColor, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.2),
                  ),
                  if (subtitle.toString().trim().isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(color: txtColor.withValues(alpha: 0.7), fontSize: 10),
                    ),
                ],
              ),
            ),
            if (url.toString().trim().isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: txtColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(url, style: TextStyle(color: txtColor, fontWeight: FontWeight.w700, fontSize: 10)),
              ),
          ],
        ),
      );
    } else if (style == 'accent') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: primary.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(iconData, color: primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: textPrimary ?? primary, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.2),
                  ),
                  if (subtitle.toString().trim().isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(color: (textPrimary ?? primary).withValues(alpha: 0.8), fontSize: 10),
                    ),
                ],
              ),
            ),
            if (url.toString().trim().isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(url, style: TextStyle(color: textPrimary ?? Colors.white, fontWeight: FontWeight.w700, fontSize: 10)),
              ),
          ],
        ),
      );
    }

    // Default to classic
    final txtColor = textPrimary ?? Colors.white;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withValues(alpha: 0.85), primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: txtColor.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(iconData, color: txtColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: txtColor, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.2),
                ),
                if (subtitle.toString().trim().isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(color: txtColor.withValues(alpha: 0.8), fontSize: 10),
                  ),
              ],
            ),
          ),
          if (url.toString().trim().isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: txtColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(url, style: TextStyle(color: txtColor, fontWeight: FontWeight.w700, fontSize: 10)),
            ),
        ],
      ),
    );
  }

  Widget _buildStickyFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -6),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_autoSending) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF25D366))),
                  const SizedBox(width: 10),
                  Text(
                    'Sending receipt to ${widget.sale.customerPhone}…',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF25D366)),
                  ),
                ],
              ),
            ),
          ],
          // --- PRIMARY ACTIONS: WhatsApp & Send SMS ---
          Row(
            children: [
              Expanded(
                child: _PrimaryAction(
                  onPressed: _processingAction == null ? _shareToWhatsApp : null,
                  customIcon: Image.asset('images/WhatsApp_icon.png', height: 20, width: 20, fit: BoxFit.contain),
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  isLoading: _processingAction == 'whatsapp',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PrimaryAction(
                  onPressed: _processingAction == null ? _sendSms : null,
                  customIcon: Image.asset('images/sms.png', height: 20, width: 20, fit: BoxFit.contain),
                  label: 'Send SMS',
                  color: const Color(0xFFF59E0B),
                  isLoading: _processingAction == 'sms',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // --- SECONDARY ACTIONS: Send Image & Print ---
          Row(
            children: [
              Expanded(
                child: _SecondaryAction(
                  onPressed: _processingAction == null ? _shareImage : null,
                  icon: Icons.image_outlined,
                  label: 'Share Image',
                  color: const Color(0xFFE53935),
                  isLoading: _processingAction == 'image',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SecondaryAction(
                  onPressed: _processingAction == null ? _printReceipt : null,
                  icon: Icons.print_rounded,
                  label: 'Print',
                  color: const Color(0xFF4F46E5),
                  isLoading: _processingAction == 'print',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: const Text('BACK TO HOME', style: TextStyle(letterSpacing: 0.8, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
