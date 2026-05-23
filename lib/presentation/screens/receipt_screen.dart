import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/models/sale.dart';
import '../../core/models/sale_item.dart';
import '../../core/repositories/owner_provider.dart';
import '../../core/services/receipt_action_service.dart';
import '../../core/services/receipt_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/theme/app_theme.dart';
part 'receipt/receipt_helpers.dart';
part 'receipt/receipt_widgets.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
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
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  late final ReceiptActionService _actionService;
  String? _processingAction;
  bool _autoSending = false;
  // Key used to capture the receipt widget as a JPEG image (like Paytm)
  final GlobalKey _receiptKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _actionService = ReceiptActionService(ReceiptService());

    final phone = widget.sale.customerPhone;
    if (phone != null && phone.isNotEmpty) {
      // Auto-send receipt to customer via WhatsApp after receipt renders
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        setState(() => _autoSending = true);
        try {
          final bannerTitle = ref.read(ownerDetailsStreamProvider).valueOrNull?['receiptBannerTitle'] as String?;
          final Uint8List? imageBytes = await _captureReceiptAsJpeg();
          await _actionService.shareToWhatsApp(
            sale: widget.sale,
            items: widget.items,
            storeName: widget.storeName ?? 'OruShops',
            customerPhone: phone,
            receiptImageBytes: imageBytes,
            receiptBannerTitle: bannerTitle,
          );
        } catch (_) {
          // Silent fail — user can retry manually
        } finally {
          if (mounted) setState(() => _autoSending = false);
        }
      });
    }
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

  /// Captures the receipt widget as a PNG image.
  Future<Uint8List?> _captureReceiptAsJpeg() async {
    // Wait for the current frame to fully paint before capturing.
    // debugNeedsPaint always returns false in release mode so we cannot rely on it.
    await WidgetsBinding.instance.endOfFrame;

    Object? lastError;
    for (int i = 0; i < 5; i++) {
      try {
        final RenderRepaintBoundary? boundary =
            _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null) {
          await Future.delayed(const Duration(milliseconds: 100));
          continue;
        }
        final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        if (byteData != null) {
          return byteData.buffer.asUint8List();
        }
      } catch (e) {
        lastError = e;
        if (kDebugMode) print('Capture attempt $i failed: $e');
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }
    if (lastError != null) throw Exception('Capture failed: $lastError');
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
        customerPhone: widget.sale.customerPhone,
      );
    });
  }

  void _sendSms() {
    final bannerTitle = ref.read(ownerDetailsStreamProvider).valueOrNull?['receiptBannerTitle'] as String?;
    _handleAction('sms', () => _actionService.sendReceiptSms(
      widget.sale,
      widget.items,
      widget.storeName ?? 'OruShops',
      widget.sale.customerPhone,
      receiptBannerTitle: bannerTitle,
    ));
  }

  void _shareToWhatsApp() {
    final bannerTitle = ref.read(ownerDetailsStreamProvider).valueOrNull?['receiptBannerTitle'] as String?;
    _handleAction('whatsapp', () async {
      final Uint8List? imageBytes = await _captureReceiptAsJpeg();
      // Even if imageBytes is null, we can still fall back to text,
      // but ideally it's captured successfully.
      await _actionService.shareToWhatsApp(
        sale: widget.sale,
        items: widget.items,
        storeName: widget.storeName ?? 'OruShops',
        customerPhone: widget.sale.customerPhone,
        receiptImageBytes: imageBytes,
        receiptBannerTitle: bannerTitle,
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
