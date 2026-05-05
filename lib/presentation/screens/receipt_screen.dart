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
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _actionService = ReceiptActionService(ReceiptService());
  }

  void _printReceipt() async {
    setState(() => _isProcessing = true);
    try {
      await _actionService.printReceipt(
        widget.sale,
        widget.items,
        widget.storeName ?? 'OruShops',
        widget.storePhone ?? '',
        widget.storeAddress ?? '',
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _downloadReceipt() async {
    setState(() => _isProcessing = true);
    try {
      await _actionService.downloadReceipt(
        widget.sale,
        widget.items,
        widget.storeName ?? 'OruShops',
        widget.storePhone ?? '',
        widget.storeAddress ?? '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt downloaded')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _shareReceipt() async {
    setState(() => _isProcessing = true);
    try {
      await _actionService.shareReceipt(
        widget.sale,
        widget.items,
        widget.storeName ?? 'OruShops',
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _shareToWhatsApp() async {
    setState(() => _isProcessing = true);
    try {
      await _actionService.shareToWhatsApp(
        widget.sale,
        widget.items,
        widget.storeName ?? 'OruShops',
        widget.storePhone,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.storeName ?? 'OruShops',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (widget.storeAddress?.isNotEmpty ?? false)
                  Text(
                    widget.storeAddress!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                if (widget.storePhone?.isNotEmpty ?? false)
                  Text(
                    'Ph: ${widget.storePhone}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 16),
                Text(
                  'Receipt #${widget.sale.id}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(widget.sale.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Item #${item.productId}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(item.totalPrice),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          Text(
                            '${item.quantity} × ${CurrencyFormatter.format(item.unitPrice)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          if (item.batchIds.isNotEmpty)
                            Text(
                              'Batch: ${item.batchIds.join(', ')}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      CurrencyFormatter.format(widget.sale.totalAmount),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (widget.sale.discountAmount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Discount',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.warningColor,
                            ),
                      ),
                      Text(
                        '−${CurrencyFormatter.format(widget.sale.discountAmount)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.warningColor,
                            ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      CurrencyFormatter.format(widget.sale.finalAmount),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successColor,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Payment: ${widget.sale.paymentMethod}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (widget.sale.customerPhone?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Customer: ${widget.sale.customerPhone}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (widget.sale.paymentMethod.toLowerCase() == 'upi' && widget.upiId != null) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Scan to Pay',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: QrImageView(
                      data: _actionService.generateUpiString(
                        widget.upiId!,
                        widget.storeName ?? 'OruShops',
                        widget.sale.finalAmount,
                      ),
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'UPI ID: ${widget.upiId}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _downloadReceipt,
                            icon: const Icon(Icons.download),
                            label: const Text('Download'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _printReceipt,
                            icon: const Icon(Icons.print),
                            label: const Text('Print'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing ? null : _shareReceipt,
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing ? null : _shareToWhatsApp,
                            icon: const Icon(Icons.chat),
                            label: const Text('WhatsApp'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}

