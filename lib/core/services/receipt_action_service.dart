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

  Future<String> generateReceiptPdf(
    Sale sale,
    List<SaleItem> items,
    String storeName,
    String storePhone,
    String storeAddress,
  ) async {
    final pdf = pw.Document();
    
    // Load font for Rupee symbol support
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final symbolFont = await PdfGoogleFonts.notoSansDevanagariRegular();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
          fontFallback: [symbolFont],
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                storeName,
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              if (storeAddress.isNotEmpty) pw.Text(storeAddress),
              if (storePhone.isNotEmpty) pw.Text('Ph: $storePhone'),
              pw.SizedBox(height: 16),
              pw.Text('Receipt #${sale.id}'),
              pw.Text(DateFormatter.formatDateTime(sale.createdAt)),
              pw.Divider(),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('Item'),
                      pw.Text('Qty'),
                      pw.Text('Rate'),
                      pw.Text('Amount'),
                    ],
                  ),
                  ...items.map((item) {
                    return pw.TableRow(
                      children: [
                        pw.Text('Item #${item.productId}'),
                        pw.Text('${item.quantity}'),
                        pw.Text(CurrencyFormatter.format(item.unitPrice)),
                        pw.Text(CurrencyFormatter.format(item.totalPrice)),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:'),
                  pw.Text(CurrencyFormatter.format(sale.totalAmount)),
                ],
              ),
              if (sale.discountAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount:'),
                    pw.Text('-${CurrencyFormatter.format(sale.discountAmount)}'),
                  ],
                ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(CurrencyFormatter.format(sale.finalAmount),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text('Payment: ${sale.paymentMethod}'),
              if (sale.customerPhone?.isNotEmpty ?? false)
                pw.Text('Customer: ${sale.customerPhone}'),
              pw.SizedBox(height: 24),
              pw.Text('Thank You!', style: pw.TextStyle(fontSize: 14)),
            ],
          );
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/receipt_${sale.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  Future<void> printReceipt(
    Sale sale,
    List<SaleItem> items,
    String storeName,
    String storePhone,
    String storeAddress,
  ) async {
    try {
      final pdfPath = await generateReceiptPdf(sale, items, storeName, storePhone, storeAddress);
      final pdfFile = File(pdfPath);
      await Printing.layoutPdf(
        onLayout: (_) => pdfFile.readAsBytes(),
      );
    } catch (e) {
      if (kDebugMode) print('Print error: $e');
    }
  }

  Future<void> downloadReceipt(
    Sale sale,
    List<SaleItem> items,
    String storeName,
    String storePhone,
    String storeAddress,
  ) async {
    try {
      await generateReceiptPdf(sale, items, storeName, storePhone, storeAddress);
    } catch (e) {
      if (kDebugMode) print('Download error: $e');
    }
  }

  Future<void> shareReceipt(
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
    }
  }

  Future<void> shareToWhatsApp(
    Sale sale,
    List<SaleItem> items,
    String storeName,
    String? phoneNumber,
  ) async {
    try {
      final receiptText = _receiptService.generateReceiptPlain(
        sale,
        items,
        storeName,
        '₹',
      );

      final encodedMessage = Uri.encodeComponent(receiptText);
      final whatsappUrl =
          phoneNumber != null && phoneNumber.isNotEmpty
              ? 'https://wa.me/$phoneNumber?text=$encodedMessage'
              : 'https://wa.me/?text=$encodedMessage';

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (kDebugMode) print('WhatsApp share error: $e');
    }
  }

  String generateUpiString(String upiId, String storeName, double amount) {
    return 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(storeName)}&am=$amount&tn=Payment&tr=ORUSHOPS${DateTime.now().millisecondsSinceEpoch}';
  }
}
