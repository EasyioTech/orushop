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
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import 'receipt_service.dart';

class ReceiptActionService {
  final ReceiptService _receiptService;

  ReceiptActionService(this._receiptService);

  Future<void> saveReceiptAsPdf(
    Sale sale,
    List<SaleItem> items,
    String storeName,
    String storePhone,
    String storeAddress,
    String? upiId,
  ) async {
    final pdfBytes = await generateReceiptPdfBytes(sale, items, storeName, storePhone, storeAddress, upiId);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'receipt_${sale.id}.pdf',
    );
  }

  Future<void> printReceipt(
    Sale sale,
    List<SaleItem> items,
    String storeName,
    String storePhone,
    String storeAddress,
    String? upiId,
  ) async {
    try {
      final pdfBytes = await generateReceiptPdfBytes(sale, items, storeName, storePhone, storeAddress, upiId);
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
    Sale sale,
    List<SaleItem> items,
    String storeName,
    String storePhone,
    String storeAddress,
    String? upiId,
  ) async {
    final pdf = pw.Document();
    
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final symbolFont = await PdfGoogleFonts.notoSansDevanagariRegular();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
          fontFallback: [symbolFont],
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Text(
                storeName.toUpperCase(),
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              if (storeAddress.isNotEmpty) 
                pw.Text(storeAddress, style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
              if (storePhone.isNotEmpty) 
                pw.Text('Ph: $storePhone', style: const pw.TextStyle(fontSize: 7)),
              
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),
              
              // Metadata
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('No: #${sale.id.toString().padLeft(6, '0')}', style: const pw.TextStyle(fontSize: 7)),
                  pw.Text(DateFormatter.formatDateTime(sale.createdAt), style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
              
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 8),
              
              // Items Header
              pw.Row(
                children: [
                  pw.Expanded(child: pw.Text('DESCRIPTION', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                  pw.SizedBox(width: 10, child: pw.Text('QTY', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  pw.SizedBox(width: 40, child: pw.Text('AMOUNT', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.2),
              pw.SizedBox(height: 4),
              
              // Items List
              ...items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(child: pw.Text('Product #${item.productId}', style: const pw.TextStyle(fontSize: 7))),
                    pw.SizedBox(width: 10, child: pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right)),
                    pw.SizedBox(width: 40, child: pw.Text(CurrencyFormatter.format(item.totalPrice), style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right)),
                  ],
                )),
              ),
              
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),
              
              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(CurrencyFormatter.format(sale.totalAmount), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (sale.discountAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('-${CurrencyFormatter.format(sale.discountAmount)}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GRAND TOTAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(CurrencyFormatter.format(sale.finalAmount), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),
              
              // Payment Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Payment: ${sale.paymentMethod}', style: const pw.TextStyle(fontSize: 7)),
                  if (sale.customerPhone?.isNotEmpty ?? false)
                    pw.Text('Cust: ${sale.customerPhone}', style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
              
              // UPI QR Code
              if (sale.paymentMethod.toLowerCase() == 'upi' && upiId != null) ...[
                pw.SizedBox(height: 12),
                pw.Text('SCAN TO PAY', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
                pw.SizedBox(height: 6),
                pw.Container(
                  height: 60,
                  width: 60,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: generateUpiString(upiId, storeName, sale.finalAmount),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(upiId, style: const pw.TextStyle(fontSize: 6)),
              ],
              
              pw.SizedBox(height: 15),
              pw.Text('Thank you for shopping with us!', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
              pw.SizedBox(height: 5),
              pw.Text('--- ORUSHOPS ---', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  Future<void> shareReceiptText(
    Sale sale,
    List<SaleItem> items,
    String storeName,
  ) async {
    try {
      final receiptText = _receiptService.generateReceiptPlain(
        sale,
        items,
        storeName,
        '₹',
      );
      await Share.share(receiptText);
    } catch (e) {
      if (kDebugMode) print('Share error: $e');
      rethrow;
    }
  }

  Future<void> shareReceiptPdf(
    Sale sale,
    List<SaleItem> items,
    String storeName,
    String storePhone,
    String storeAddress,
    String? upiId,
  ) async {
    try {
      final pdfBytes = await generateReceiptPdfBytes(sale, items, storeName, storePhone, storeAddress, upiId);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Receipt_${sale.id}.pdf');
      await file.writeAsBytes(pdfBytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Receipt #${sale.id.toString().padLeft(6, '0')} from $storeName',
        text: 'Thank you for your business! Here is your digital receipt in PDF format.',
      );
    } catch (e) {
      if (kDebugMode) print('Share PDF error: $e');
      rethrow;
    }
  }

  Future<void> shareToWhatsAppWithSmsFallback({
    required Sale sale,
    required List<SaleItem> items,
    required String storeName,
    required String storePhone,
    required String storeAddress,
    required String? upiId,
    required String? customerPhone,
    required Uint8List? receiptImageBytes,   // PNG bytes captured from the widget
    required VoidCallback onRedirectingToSms,
  }) async {
    try {
      if (receiptImageBytes != null) {
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
              {'filePath': imageFile.path},
            );
            sentViaChannel = result == true;
          } catch (e) {
            if (kDebugMode) print('Platform channel error: $e');
          }
        }

        if (!sentViaChannel) {
          // === STEP 2: Fallback — share sheet with image (iOS or channel failed) ===
          await Share.shareXFiles(
            [XFile(imageFile.path, mimeType: 'image/png')],
            subject: 'Receipt from $storeName',
          );
        }
        return;
      }

      // === STEP 3: No image bytes — check WhatsApp via URL scheme ===
      bool isWhatsAppInstalled = false;
      try {
        isWhatsAppInstalled = await canLaunchUrl(Uri.parse('whatsapp://send'));
      } catch (_) {}

      if (isWhatsAppInstalled) {
        // Opens WhatsApp directly to the customer's chat with receipt text pre-filled
        String phone = (customerPhone ?? '').replaceAll(RegExp(r'\D'), '');
        if (phone.startsWith('0')) phone = phone.substring(1);
        if (phone.length == 10) phone = '91$phone';

        final receiptText = _receiptService.generateReceiptPlain(sale, items, storeName, '₹');
        final whatsappUri = Uri(
          scheme: 'whatsapp',
          host: 'send',
          queryParameters: <String, String>{'phone': phone, 'text': receiptText},
        );
        bool launched = false;
        try {
          launched = await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        } catch (_) {}
        if (!launched) {
          onRedirectingToSms();
          await sendReceiptSms(sale, items, storeName, customerPhone);
        }
      } else {
        // WhatsApp not installed — go directly to SMS
        onRedirectingToSms();
        await sendReceiptSms(sale, items, storeName, customerPhone);
      }
    } catch (e) {
      if (kDebugMode) print('WhatsApp share fallback error: $e');
      onRedirectingToSms();
      await sendReceiptSms(sale, items, storeName, customerPhone);
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
