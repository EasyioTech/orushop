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

class ReceiptActionService {
  final ReceiptService _receiptService;

  ReceiptActionService(this._receiptService);

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
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Receipt_${sale.id}.jpg');
      await file.writeAsBytes(receiptImageBytes);
      
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/jpeg')],
      );
    } catch (e) {
      if (kDebugMode) print('Share Image error: $e');
      rethrow;
    }
  }

  Future<void> shareToWhatsApp({
    required Sale sale,
    required String storeName,
    required Uint8List receiptImageBytes,
    String? customerPhone,
  }) async {
    try {
      // Save the captured receipt image to a temp file
      final tempDir = await getTemporaryDirectory();
      final imageFile = File('${tempDir.path}/Receipt_${sale.id}.png');
      await imageFile.writeAsBytes(receiptImageBytes);

      // === STEP 1: Try direct WhatsApp via native platform channel (NO share sheet) ===
      // MainActivity.kt fires ACTION_SEND to com.whatsapp.w4b or com.whatsapp directly.
      bool sentViaChannel = false;
      if (Platform.isAndroid) {
        try {
          const channel = MethodChannel('com.orushops/whatsapp_share');
          final bool? result = await channel.invokeMethod<bool>(
            'shareImageToWhatsApp',
            {
              'filePath': imageFile.path,
              'phone': customerPhone,
            },
          );
          sentViaChannel = result == true;
        } catch (e) {
          if (kDebugMode) print('Platform channel error: $e');
        }
      }

      if (!sentViaChannel) {
        // === STEP 2: Fallback — share sheet with image (iOS or channel failed) ===
        // Removed subject/text to ensure WhatsApp treats it purely as an image
        await Share.shareXFiles(
          [XFile(imageFile.path, mimeType: 'image/png')],
        );
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

