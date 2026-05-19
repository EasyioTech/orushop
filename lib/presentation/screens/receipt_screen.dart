import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/models/sale.dart';
import '../../core/models/sale_item.dart';
import '../../core/services/receipt_action_service.dart';
import '../../core/services/receipt_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/theme/app_theme.dart';

class ReceiptScreen extends StatefulWidget {
  final Sale sale;
  final List<SaleItem> items;
  final String? storeName;
  final String? storePhone;
  final String? storeAddress;
  final String? upiId;

  const ReceiptScreen({
    required this.sale,
    required this.items,
    this.storeName,
    this.storePhone,
    this.storeAddress,
    this.upiId,
    super.key,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> with WidgetsBindingObserver {
  late final ReceiptActionService _actionService;
  String? _processingAction;
  DateTime? _whatsAppLaunchTime;
  bool _isWaitingForWhatsAppReturn = false;
  // Key used to capture the receipt widget as a JPEG image (like Paytm)
  final GlobalKey _receiptKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _actionService = ReceiptActionService(ReceiptService());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isWaitingForWhatsAppReturn) {
      setState(() {
        _isWaitingForWhatsAppReturn = false;
      });
      final launchTime = _whatsAppLaunchTime;
      if (launchTime != null) {
        final elapsed = DateTime.now().difference(launchTime).inSeconds;
        // If they returned in less than 5 seconds, WhatsApp likely failed or the contact is not registered.
        if (elapsed < 5) {
          _showWhatsAppFallbackPrompt();
        }
      }
    }
  }

  void _showWhatsAppFallbackPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.orangeAccent, size: 28),
            SizedBox(width: 10),
            Text(
              'Not on WhatsApp?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'It seems the customer is not on WhatsApp or the delivery was aborted. '
          'Would you like to send this receipt as a standard SMS instead?',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'NO, THANKS',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendSms();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('SEND SMS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(String action, Future<void> Function() callback) async {
    setState(() => _processingAction = action);
    try {
      await callback();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingAction = null);
    }
  }

  void _printReceipt() {
    _handleAction('print', () => _actionService.printReceipt(
      widget.sale,
      widget.items,
      widget.storeName ?? 'OruShops',
      widget.storePhone ?? '',
      widget.storeAddress ?? '',
      widget.upiId,
    ));
  }

  void _sharePdf() {
    _handleAction('pdf', () => _actionService.shareReceiptPdf(
      widget.sale,
      widget.items,
      widget.storeName ?? 'OruShops',
      widget.storePhone ?? '',
      widget.storeAddress ?? '',
      widget.upiId,
    ));
  }

  void _sendSms() {
    _handleAction('sms', () => _actionService.sendReceiptSms(
      widget.sale,
      widget.items,
      widget.storeName ?? 'OruShops',
      widget.sale.customerPhone,
    ));
  }

  /// Captures the receipt widget as a high-quality JPEG image.
  /// pixelRatio 4.0 → 4x resolution so it looks crisp on any phone screen.
  Future<Uint8List?> _captureReceiptAsJpeg() async {
    for (int i = 0; i < 5; i++) {
      try {
        final RenderRepaintBoundary? boundary =
            _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null) {
          await Future.delayed(const Duration(milliseconds: 50));
          continue;
        }
        // Wait a frame if the widget is still rendering
        if (boundary.debugNeedsPaint) {
          await Future.delayed(const Duration(milliseconds: 100));
          continue;
        }
        final ui.Image image = await boundary.toImage(pixelRatio: 4.0);
        // For simplicity we use PNG bytes — WhatsApp recompresses on send anyway
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        if (byteData != null) {
          return byteData.buffer.asUint8List();
        }
      } catch (e) {
        if (kDebugMode) print('Capture attempt $i failed: $e');
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    return null;
  }

  void _shareToWhatsAppWithFallback() {
    setState(() {
      _isWaitingForWhatsAppReturn = true;
      _whatsAppLaunchTime = DateTime.now();
    });
    _handleAction('whatsapp', () async {
      // Capture the receipt widget as an image first
      final Uint8List? imageBytes = await _captureReceiptAsJpeg();
      await _actionService.shareToWhatsAppWithSmsFallback(
        sale: widget.sale,
        items: widget.items,
        storeName: widget.storeName ?? 'OruShops',
        storePhone: widget.storePhone ?? '',
        storeAddress: widget.storeAddress ?? '',
        upiId: widget.upiId,
        customerPhone: widget.sale.customerPhone,
        receiptImageBytes: imageBytes,
        onRedirectingToSms: () {
          if (mounted) {
            setState(() {
              _isWaitingForWhatsAppReturn = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('WhatsApp is not installed. Redirecting to SMS...'),
                backgroundColor: AppTheme.primaryColor,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: const Text('Digital Receipt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  children: [
                    // RepaintBoundary allows us to capture this widget as a JPEG image
                    RepaintBoundary(
                      key: _receiptKey,
                      child: _buildReceiptPaper(theme),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _buildStickyFooter(theme),
          ],
        ),
      ),
    );
  }

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

  Widget _buildOruShopsBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withValues(alpha: 0.85), AppTheme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Powered by OruShops',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.2),
                ),
                Text(
                  'Smart POS for Indian Retailers',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text('orushops.in', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10)),
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
          // --- PRIMARY ACTIONS: WhatsApp & Send SMS ---
          Row(
            children: [
              Expanded(
                child: _PrimaryAction(
                  onPressed: _processingAction == null ? _shareToWhatsAppWithFallback : null,
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
          // --- SECONDARY ACTIONS: Send PDF & Print ---
          Row(
            children: [
              Expanded(
                child: _SecondaryAction(
                  onPressed: _processingAction == null ? _sharePdf : null,
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'Send PDF',
                  color: const Color(0xFFE53935),
                  isLoading: _processingAction == 'pdf',
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





// PRIMARY ACTION — tall, solid filled, prominent
class _PrimaryAction extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? customIcon;
  final String label;
  final Color color;
  final bool isLoading;

  const _PrimaryAction({
    required this.onPressed,
    this.icon,
    this.customIcon,
    required this.label,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    final Color buttonColor = isEnabled ? color : color.withValues(alpha: 0.5);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: isEnabled
            ? [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 4))]
            : null,
      ),
      child: Material(
        color: buttonColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              else if (customIcon != null)
                customIcon!
              else if (icon != null)
                Icon(icon!, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.1)),
            ],
          ),
        ),
      ),
    );
  }
}

// SECONDARY ACTION — shorter, outlined style, less prominent
class _SecondaryAction extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? customIcon;
  final String label;
  final Color color;
  final bool isLoading;

  const _SecondaryAction({
    required this.onPressed,
    this.icon,
    this.customIcon,
    required this.label,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    final Color activeColor = isEnabled ? color : color.withValues(alpha: 0.4);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: activeColor, width: 1.5),
        color: activeColor.withValues(alpha: 0.06),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  height: 15, width: 15,
                  child: CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation<Color>(activeColor)),
                )
              else if (customIcon != null)
                customIcon!
              else if (icon != null)
                Icon(icon!, size: 16, color: activeColor),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: activeColor, letterSpacing: 0.1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.slate500)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.slate400, letterSpacing: 1)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primaryColor),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(30, (index) => Expanded(
        child: Container(color: index % 2 == 0 ? AppTheme.slate200 : Colors.transparent, height: 1),
      )),
    );
  }
}

class ReceiptPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);

    double x = size.width;
    double y = size.height;
    double toothWidth = 12;
    double toothHeight = 6;

    while (x > 0) {
      path.lineTo(x - toothWidth / 2, y - toothHeight);
      x -= toothWidth;
      path.lineTo(x, y);
    }

    path.lineTo(0, size.height);
    path.close();

    canvas.drawShadow(path.shift(const Offset(0, 4)), Colors.black.withOpacity(0.1), 10.0, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


