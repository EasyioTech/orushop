part of '../khata_action_service.dart';

extension KhataEntryPdfActions on KhataActionService {
  Future<Uint8List> generateLedgerEntryPdfBytes({
    required String customerName,
    required String customerPhone,
    required double amount,
    required String recordType,
    required String type,
    required String note,
    required DateTime createdAt,
    required String storeName,
    required String storePhone,
    required String storeAddress,
    required String? upiId,
    required double currentBalance,
  }) async {
    final pdf = pw.Document();
    
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final symbolFont = await PdfGoogleFonts.notoSansDevanagariRegular();

    final isCredit = type == 'credit';
    final isPayment = recordType == 'payment';
    final balanceStr = currentBalance.abs().toStringAsFixed(0);

    String actionLabel = '';
    if (isPayment) {
      actionLabel = 'RECEIVED PAYMENT';
    } else if (isCredit) {
      actionLabel = 'GAVE CREDIT';
    } else {
      actionLabel = 'DEBITED';
    }

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
              pw.Text(
                storeName.toUpperCase(),
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              if (storeAddress.isNotEmpty) 
                pw.Text(storeAddress, style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
              if (storePhone.isNotEmpty) 
                pw.Text('Ph: $storePhone', style: const pw.TextStyle(fontSize: 7)),
              
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),

              pw.Text(
                'TRANSACTION VOUCHER',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(createdAt),
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
              ),

              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 6),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Customer:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  pw.Text(customerName, style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Phone:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  pw.Text(customerPhone, style: const pw.TextStyle(fontSize: 7)),
                ],
              ),

              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: isCredit ? PdfColors.red50 : PdfColors.green50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      actionLabel,
                      style: pw.TextStyle(
                        fontSize: 8, 
                        fontWeight: pw.FontWeight.bold, 
                        color: isCredit ? PdfColors.red900 : PdfColors.green900,
                      ),
                    ),
                    pw.Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: pw.TextStyle(
                        fontSize: 10, 
                        fontWeight: pw.FontWeight.bold,
                        color: isCredit ? PdfColors.red900 : PdfColors.green900,
                      ),
                    ),
                  ],
                ),
              ),

              if (note.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Note: ', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                    pw.Expanded(child: pw.Text(note, style: const pw.TextStyle(fontSize: 7))),
                  ],
                ),
              ],

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Outstanding Balance:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(
                    '₹$balanceStr ${currentBalance > 0 ? '(Pending)' : currentBalance < 0 ? '(Advance)' : '(Settled)'}',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: currentBalance > 0 ? PdfColors.red900 : currentBalance < 0 ? PdfColors.green900 : PdfColors.grey800,
                    ),
                  ),
                ],
              ),

              if (currentBalance > 0 && upiId != null && upiId.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Text('SCAN TO PAY OUTSTANDING', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
                pw.SizedBox(height: 4),
                pw.Container(
                  height: 50,
                  width: 50,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: generateUpiString(upiId, storeName, currentBalance),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(upiId, style: const pw.TextStyle(fontSize: 5)),
              ],

              pw.SizedBox(height: 12),
              pw.Text('OruShops Digital Khata - Smart business tool', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  Future<void> shareLedgerEntryPdf({
    required String customerName,
    required String customerPhone,
    required double amount,
    required String recordType,
    required String type,
    required String note,
    required DateTime createdAt,
    required String storeName,
    required String storePhone,
    required String storeAddress,
    required String? upiId,
    required double currentBalance,
  }) async {
    try {
      final pdfBytes = await generateLedgerEntryPdfBytes(
        customerName: customerName,
        customerPhone: customerPhone,
        amount: amount,
        recordType: recordType,
        type: type,
        note: note,
        createdAt: createdAt,
        storeName: storeName,
        storePhone: storePhone,
        storeAddress: storeAddress,
        upiId: upiId,
        currentBalance: currentBalance,
      );
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Khata_Voucher_${createdAt.millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(pdfBytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Khata Entry Receipt - $customerName',
        text: 'Thank you! Here is your digital transaction receipt in PDF format.',
      );
    } catch (e) {
      if (kDebugMode) print('Share entry PDF error: $e');
      rethrow;
    }
  }

  Future<void> printLedgerEntry({
    required String customerName,
    required String customerPhone,
    required double amount,
    required String recordType,
    required String type,
    required String note,
    required DateTime createdAt,
    required String storeName,
    required String storePhone,
    required String storeAddress,
    required String? upiId,
    required double currentBalance,
  }) async {
    try {
      final pdfBytes = await generateLedgerEntryPdfBytes(
        customerName: customerName,
        customerPhone: customerPhone,
        amount: amount,
        recordType: recordType,
        type: type,
        note: note,
        createdAt: createdAt,
        storeName: storeName,
        storePhone: storePhone,
        storeAddress: storeAddress,
        upiId: upiId,
        currentBalance: currentBalance,
      );
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: 'Khata_Voucher_${createdAt.millisecondsSinceEpoch}',
      );
    } catch (e) {
      if (kDebugMode) print('Print entry error: $e');
      rethrow;
    }
  }

  // ── Full Ledger Statement Actions ──────────────────────────────────────────

}
