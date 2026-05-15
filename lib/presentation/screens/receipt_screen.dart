import 'package:flutter/material.dart';
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

class _ReceiptScreenState extends State<ReceiptScreen> {
  late final ReceiptActionService _actionService;
  String? _processingAction;

  @override
  void initState() {
    super.initState();
    _actionService = ReceiptActionService(ReceiptService());
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

  void _downloadReceipt() {
    _handleAction('download', () async {
      await _actionService.saveReceiptAsPdf(
        widget.sale,
        widget.items,
        widget.storeName ?? 'OruShops',
        widget.storePhone ?? '',
        widget.storeAddress ?? '',
        widget.upiId,
      );
    });
  }

  void _shareReceipt() {
    _handleAction('share', () => _actionService.shareReceiptText(
      widget.sale,
      widget.items,
      widget.storeName ?? 'OruShops',
    ));
  }

  void _shareToWhatsApp() {
    _handleAction('whatsapp', () => _actionService.shareToWhatsApp(
      widget.sale,
      widget.items,
      widget.storeName ?? 'OruShops',
      widget.sale.customerPhone,
    ));
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
                    _buildReceiptPaper(theme),
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

  Widget _buildSuccessBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppTheme.successColor, size: 14),
          const SizedBox(width: 6),
          Text(
            'SALE SUCCESSFUL',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.successColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPaper(ThemeData theme) {
    return CustomPaint(
      painter: ReceiptPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          children: [
            _buildSuccessBanner(theme),
            const SizedBox(height: 12),
            _buildStoreHeader(theme),
            const SizedBox(height: 20),
            _DashedDivider(),
            const SizedBox(height: 12),
            _buildReceiptMetadata(theme),
            const SizedBox(height: 20),
            _DashedDivider(),
            const SizedBox(height: 12),
            ...widget.items.map((item) => _buildItemRow(theme, item)),
            const SizedBox(height: 12),
            _DashedDivider(),
            const SizedBox(height: 12),
            _buildTotalsSection(theme),
            const SizedBox(height: 20),
            _DashedDivider(),
            const SizedBox(height: 12),
            _buildInfoSection(),
            if (widget.sale.paymentMethod.toLowerCase() == 'upi' && widget.upiId != null)
              _buildUpiSection(theme),
            const SizedBox(height: 32),
            Text(
              'Thank you for your business!',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppTheme.slate400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.storefront_outlined, size: 20, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.storeName ?? 'OruShops',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              if (widget.storeAddress?.isNotEmpty ?? false)
                Text(
                  widget.storeAddress!,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.slate500, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptMetadata(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RECEIPT NO', style: theme.textTheme.titleSmall?.copyWith(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
            Text('#${widget.sale.id.toString().padLeft(6, '0')}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('DATE', style: theme.textTheme.titleSmall?.copyWith(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
            Text(DateFormat('MMM dd, yyyy HH:mm').format(widget.sale.createdAt), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildItemRow(ThemeData theme, SaleItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Product #${item.productId}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text('${item.quantity} × ${CurrencyFormatter.format(item.unitPrice)}', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.slate500)),
              ],
            ),
          ),
          Text(CurrencyFormatter.format(item.totalPrice), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTotalsSection(ThemeData theme) {
    return Column(
      children: [
        _SummaryRow(label: 'Subtotal', value: CurrencyFormatter.format(widget.sale.totalAmount)),
        if (widget.sale.discountAmount > 0)
          _SummaryRow(label: 'Discount', value: '-${CurrencyFormatter.format(widget.sale.discountAmount)}', valueColor: AppTheme.errorColor),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TOTAL', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            Text(
              CurrencyFormatter.format(widget.sale.finalAmount),
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _InfoChip(label: 'Payment', value: widget.sale.paymentMethod, icon: Icons.payments_outlined),
        if (widget.sale.customerPhone != null)
          _InfoChip(label: 'Customer', value: widget.sale.customerPhone!, icon: Icons.person_outline),
      ],
    );
  }

  Widget _buildUpiSection(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Text('SCAN TO PAY', style: theme.textTheme.titleSmall?.copyWith(letterSpacing: 2, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.slate200)),
          child: QrImageView(
            data: _actionService.generateUpiString(widget.upiId!, widget.storeName ?? 'OruShops', widget.sale.finalAmount),
            version: QrVersions.auto,
            size: 160.0,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.primaryColor),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.primaryColor),
          ),
        ),
        const SizedBox(height: 12),
        Text(widget.upiId!, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStickyFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.8,
            children: [
              _FooterAction(
                onPressed: _processingAction == null ? _downloadReceipt : null, 
                icon: Icons.file_download_rounded, 
                label: 'Save PDF', 
                color: Colors.blueAccent,
                isLoading: _processingAction == 'download',
              ),
              _FooterAction(
                onPressed: _processingAction == null ? _printReceipt : null, 
                icon: Icons.print_rounded, 
                label: 'Print', 
                color: Colors.indigoAccent,
                isLoading: _processingAction == 'print',
              ),
              _FooterAction(
                onPressed: _processingAction == null ? _shareReceipt : null, 
                icon: Icons.share_rounded, 
                label: 'Share', 
                color: AppTheme.slate600,
                isLoading: _processingAction == 'share',
              ),
              _FooterAction(
                onPressed: _processingAction == null ? _shareToWhatsApp : null, 
                icon: Icons.chat_rounded, 
                label: 'WhatsApp', 
                color: const Color(0xFF25D366),
                isLoading: _processingAction == 'whatsapp',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor, 
                foregroundColor: Colors.white, 
                elevation: 0, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('BACK TO HOME', style: TextStyle(letterSpacing: 1, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterAction extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;

  const _FooterAction({
    required this.onPressed, 
    required this.icon, 
    required this.label, 
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.15), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  height: 16, 
                  width: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: color)
                )
              else
                Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label, 
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.w800, 
                  color: color,
                  letterSpacing: -0.2,
                ),
              ),
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


