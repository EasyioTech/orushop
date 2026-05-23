import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import 'receipt_service.dart';

const _whatsAppChannel = MethodChannel('com.orushops/whatsapp_share');

class ReceiptActionService {
  final ReceiptService _receiptService;

  ReceiptActionService(this._receiptService);

  /// Sends image directly into a WhatsApp chat via the native MainActivity channel.
  /// Returns false if WhatsApp is not installed or the channel call fails.
  Future<bool> _nativeShareImageToWhatsApp(String filePath, String phone, {String? message}) async {
    try {
      final result = await _whatsAppChannel.invokeMethod<bool>(
        'shareImageToWhatsApp',
        {'filePath': filePath, 'phone': phone, 'message': message},
      );
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// Opens WhatsApp with [phone] pre-selected and [text] pre-filled (text fallback).
  Future<bool> _isWhatsAppAvailable() =>
      canLaunchUrl(Uri.parse('whatsapp://send?phone=1'));

  /// Opens WhatsApp with [phone] pre-selected and [text] pre-filled.
  Future<void> _deepLinkWhatsApp(String phone, String text) async {
    final encoded = Uri.encodeComponent(text);
    final direct = Uri.parse('whatsapp://send?phone=$phone&text=$encoded');
    if (await canLaunchUrl(direct)) {
      await launchUrl(direct, mode: LaunchMode.externalApplication);
      return;
    }
    final web = Uri.parse('https://wa.me/$phone?text=$encoded');
    if (await canLaunchUrl(web)) {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> saveReceiptAsPdf(
    Sale sale,
    Uint8List receiptImageBytes,
  ) async {
    final pdfBytes = await generateReceiptPdfBytes(receiptImageBytes);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'receipt_${sale.id}.pdf',
    );
  }

  Future<void> printReceipt(
    Sale sale,
    Uint8List receiptImageBytes,
  ) async {
    try {
      final pdfBytes = await generateReceiptPdfBytes(receiptImageBytes);
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: 'Receipt_${sale.id}',
      );
    } catch (e) {
      if (kDebugMode) print('Print error: $e');
      rethrow;
    }
  }

  Future<Uint8List> generateReceiptPdfBytes(
    Uint8List receiptImageBytes,
  ) async {
    final pdf = pw.Document();
    
    final image = pw.MemoryImage(receiptImageBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.fitWidth),
          );
        },
      ),
    );

    return await pdf.save();
  }



  Future<void> shareReceiptImage(
    Sale sale,
    Uint8List receiptImageBytes,
    {String? customerPhone}
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      // Use .png extension to match actual PNG bytes from toImage()
      final file = File('${tempDir.path}/Receipt_${sale.id}.png');
      await file.writeAsBytes(receiptImageBytes);

      if (customerPhone != null && customerPhone.isNotEmpty) {
        String cleanPhone = customerPhone.replaceAll(RegExp(r'\D'), '');
        if (cleanPhone.startsWith('0')) cleanPhone = cleanPhone.substring(1);
        if (cleanPhone.length == 10) cleanPhone = '91$cleanPhone';

        if (cleanPhone.isNotEmpty && await _isWhatsAppAvailable()) {
          if (await _nativeShareImageToWhatsApp(file.path, cleanPhone)) return;
        }
      }


      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
      );
    } catch (e) {
      if (kDebugMode) print('Share Image error: $e');
      rethrow;
    }
  }

  /// Sends the receipt image directly to the customer's WhatsApp chat.
  Future<void> shareToWhatsApp({
    required Sale sale,
    required List<SaleItem> items,
    required String storeName,
    String? customerPhone,
    Uint8List? receiptImageBytes,
  }) async {
    try {
      final receiptText = _receiptService.generateReceiptPlain(sale, items, storeName, '₹');

      if (customerPhone != null && customerPhone.isNotEmpty) {
        String cleanPhone = customerPhone.replaceAll(RegExp(r'\D'), '');
        if (cleanPhone.startsWith('0')) cleanPhone = cleanPhone.substring(1);
        if (cleanPhone.length == 10) cleanPhone = '91$cleanPhone';

        if (cleanPhone.isNotEmpty) {
          if (receiptImageBytes != null) {
            final tempDir = await getTemporaryDirectory();
            final file = File('${tempDir.path}/Receipt_${sale.id}.png');
            await file.writeAsBytes(receiptImageBytes);
            final whatsappMsg = 'Here\'s your receipt from $storeName 🧾\nThank you for shopping with us!';
            if (await _isWhatsAppAvailable() && await _nativeShareImageToWhatsApp(file.path, cleanPhone, message: whatsappMsg)) return;
          }
          // Deep link: opens WhatsApp chat with phone + text pre-filled
          await _deepLinkWhatsApp(cleanPhone, receiptText);
          return;
        }
      }

      // No phone number or WhatsApp not installed — system share sheet with text
      if (receiptImageBytes != null) {
         final tempDir = await getTemporaryDirectory();
         final file = File('${tempDir.path}/Receipt_${sale.id}.png');
         await file.writeAsBytes(receiptImageBytes);
         await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')]);
      } else {
         await Share.share(receiptText);
      }
    } catch (e) {
      if (kDebugMode) print('WhatsApp share error: $e');
      rethrow;
    }
  }

  Future<void> sendReceiptSms(
    Sale sale,
    List<SaleItem> items,
    String storeName,
    String? phoneNumber,
  ) async {
    try {
      String? cleanPhone = phoneNumber?.replaceAll(RegExp(r'\D'), '');
      if (cleanPhone != null && cleanPhone.startsWith('0')) {
        cleanPhone = cleanPhone.substring(1);
      }
      
      // If it's a 10 digit Indian number, we add country code or leave it local for SMS composer
      // Most OS SMS deep links work best with the local 10-digit number or with country code.
      // We keep it clean and let the native SMS app resolve it.

      final receiptText = _receiptService.generateReceiptPlain(
        sale,
        items,
        storeName,
        '₹',
      );
      
      // Use 'smsto:' scheme with LaunchMode.externalNonBrowserApplication
      // This forces Android to open the NATIVE SMS app and bypasses WhatsApp Business
      // which incorrectly claims the generic 'sms:' intent on some devices.
      final Uri smsUri = Uri(
        scheme: 'smsto',
        path: cleanPhone ?? '',
        queryParameters: <String, String>{
          'body': receiptText,
        },
      );

      bool launched = false;
      try {
        launched = await launchUrl(
          smsUri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
      } catch (_) {}

      if (!launched) {
        // smsto: failed — try plain sms: as second attempt
        final Uri fallbackSmsUri = Uri(
          scheme: 'sms',
          path: cleanPhone ?? '',
          queryParameters: <String, String>{'body': receiptText},
        );
        try {
          launched = await launchUrl(
            fallbackSmsUri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
        } catch (_) {}
      }

      if (!launched) {
        // Final fallback: system share sheet so user can pick the SMS app manually
        await Share.share(receiptText);
      }
    } catch (e) {
      if (kDebugMode) print('SMS share error: $e');
      rethrow;
    }
  }

  String generateUpiString(String upiId, String storeName, double amount) {
    return 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(storeName)}&am=$amount&tn=Payment&tr=ORUSHOPS${DateTime.now().millisecondsSinceEpoch}';
  }
}

