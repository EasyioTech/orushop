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
part 'receipt/receipt_helpers.dart';
part 'receipt/receipt_widgets.dart';

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
  // Key used to capture the receipt widget as a JPEG image (like Paytm)
  final GlobalKey _receiptKey = GlobalKey();

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

  /// Captures the receipt widget as a high-quality JPEG image.
  /// pixelRatio 4.0 → 4x resolution so it looks crisp on any phone screen.
  Future<Uint8List?> _captureReceiptAsJpeg() async {
    Object? lastError;
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
        // Reduce pixelRatio from 4.0 to 2.5 to avoid layout, dimension or memory allocation exceptions on standard devices
        final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
        // For simplicity we use PNG bytes — WhatsApp recompresses on send anyway
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        if (byteData != null) {
          return byteData.buffer.asUint8List();
        }
      } catch (e) {
        lastError = e;
        if (kDebugMode) print('Capture attempt $i failed: $e');
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    if (lastError != null) {
      throw Exception('Capture failed: $lastError');
    }
    return null;
  }

  void _printReceipt() {
    _handleAction('print', () async {
      final Uint8List? imageBytes = await _captureReceiptAsJpeg();
      if (imageBytes == null) throw Exception('Could not capture receipt image');
      await _actionService.printReceipt(
        widget.sale,
        imageBytes,
      );
    });
  }

  void _shareImage() {
    _handleAction('image', () async {
      final Uint8List? imageBytes = await _captureReceiptAsJpeg();
      if (imageBytes == null) throw Exception('Could not capture receipt image');
      await _actionService.shareReceiptImage(
        widget.sale,
        imageBytes,
      );
    });
  }

  void _sendSms() {
    _handleAction('sms', () => _actionService.sendReceiptSms(
      widget.sale,
      widget.items,
      widget.storeName ?? 'OruShops',
      widget.sale.customerPhone,
    ));
  }

  void _shareToWhatsApp() {
    _handleAction('whatsapp', () async {
      // Capture the receipt widget as an image first
      final Uint8List? imageBytes = await _captureReceiptAsJpeg();
      if (imageBytes == null) throw Exception('Could not capture receipt image');
      await _actionService.shareToWhatsApp(
        sale: widget.sale,
        storeName: widget.storeName ?? 'OruShops',
        receiptImageBytes: imageBytes,
        customerPhone: widget.sale.customerPhone,
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
}
