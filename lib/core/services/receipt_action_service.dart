import 'dart:io';
import 'package:flutter/foundation.dart';
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

  Future<void> shareToWhatsApp(
    Sale sale,
    List<SaleItem> items,
    String storeName,
    String? phoneNumber,
  ) async {
    try {
      // Improved sanitization: remove all non-numeric characters
      String? cleanPhone = phoneNumber?.replaceAll(RegExp(r'\D'), '');
      
      if (cleanPhone != null && cleanPhone.isNotEmpty) {
        // If it starts with 0, remove it (common in some regions, but not for international format)
        if (cleanPhone.startsWith('0')) {
          cleanPhone = cleanPhone.substring(1);
        }
        
        // If it's 10 digits, it's a local Indian number, add 91
        if (cleanPhone.length == 10) {
          cleanPhone = '91$cleanPhone';
        } 
        // If it's already 12 digits and starts with 91, it's already correct
        // If it's something else, we leave it as is (might be international)
      }

      final receiptText = _receiptService.generateReceiptPlain(
        sale,
        items,
        storeName,
        '₹',
      );

      final encodedMessage = Uri.encodeComponent(receiptText);
      
      // Try wa.me first (recommended)
      final whatsappUrl =
          cleanPhone != null && cleanPhone.isNotEmpty
              ? 'https://wa.me/$cleanPhone?text=$encodedMessage'
              : 'https://wa.me/?text=$encodedMessage';

      try {
        final launched = await launchUrl(
          Uri.parse(whatsappUrl), 
          mode: LaunchMode.externalApplication
        );
        if (!launched) throw 'Could not launch URL';
      } catch (e) {
        // Fallback for specific schemes or if wa.me fails
        final fallbackUrl = cleanPhone != null && cleanPhone.isNotEmpty
            ? 'whatsapp://send?phone=$cleanPhone&text=$encodedMessage'
            : 'whatsapp://send?text=$encodedMessage';
        
        try {
          await launchUrl(
            Uri.parse(fallbackUrl), 
            mode: LaunchMode.externalNonBrowserApplication
          );
        } catch (_) {
          // If both fail, try generic sharing
          await shareReceiptText(sale, items, storeName);
        }
      }
    } catch (e) {
      if (kDebugMode) print('WhatsApp share error: $e');
      rethrow;
    }
  }

  String generateUpiString(String upiId, String storeName, double amount) {
    return 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(storeName)}&am=$amount&tn=Payment&tr=ORUSHOPS${DateTime.now().millisecondsSinceEpoch}';
  }

  // Deprecated: use saveReceiptAsPdf
  Future<String> downloadReceipt(
    Sale sale,
    List<SaleItem> items,
    String storeName,
    String storePhone,
    String storeAddress,
  ) async {
    final bytes = await generateReceiptPdfBytes(sale, items, storeName, storePhone, storeAddress, null);
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/receipt_${sale.id}.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
