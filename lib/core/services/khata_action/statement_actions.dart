part of '../khata_action_service.dart';

// ── PDF isolate data + worker ────────────────────────────────────────────────

class _PdfParams {
  final Uint8List fontBytes;
  final Uint8List boldFontBytes;
  final Uint8List symbolFontBytes;
  final String customerName;
  final String customerPhone;
  final List<Map<String, dynamic>> ledger;
  final String storeName;
  final String storePhone;
  final String storeAddress;
  final String? upiId;
  final double currentBalance;
  final String bannerText;

  const _PdfParams({
    required this.fontBytes,
    required this.boldFontBytes,
    required this.symbolFontBytes,
    required this.customerName,
    required this.customerPhone,
    required this.ledger,
    required this.storeName,
    required this.storePhone,
    required this.storeAddress,
    required this.upiId,
    required this.currentBalance,
    required this.bannerText,
  });
}

Future<Uint8List> _buildPdfInIsolate(_PdfParams p) async {
  final font = pw.Font.ttf(ByteData.view(p.fontBytes.buffer));
  final boldFont = pw.Font.ttf(ByteData.view(p.boldFontBytes.buffer));
  final symbolFont = pw.Font.ttf(ByteData.view(p.symbolFontBytes.buffer));
  final navyColor = PdfColor.fromHex('#0F172A');

  final pdf = pw.Document();

  final List<Map<String, dynamic>> chronLedger = List.from(p.ledger.reversed);
  double runBal = 0.0;
  final List<double> chronBalances = [];
  for (final row in chronLedger) {
    final type = row['type'] as String;
    final recordType = row['recordType'] as String;
    final amt = (row['amount'] as num).toDouble();
    if (recordType == 'payment') {
      runBal -= amt;
    } else if (type == 'credit') {
      runBal += amt;
    } else {
      runBal -= amt;
    }
    chronBalances.add(runBal);
  }
  final List<double> runningBalances = List.from(chronBalances.reversed);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      theme: pw.ThemeData.withFont(
        base: font,
        bold: boldFont,
        fontFallback: [symbolFont],
      ),
      header: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(p.storeName.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: navyColor)),
                    if (p.storeAddress.isNotEmpty) pw.Text(p.storeAddress, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    if (p.storePhone.isNotEmpty) pw.Text('Phone: ${p.storePhone}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('ACCOUNT STATEMENT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: navyColor)),
                    pw.Text('Generated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1, color: navyColor),
            pw.SizedBox(height: 12),
          ],
        );
      },
      footer: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Divider(thickness: 0.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(p.bannerText, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
              ],
            ),
          ],
        );
      },
      build: (pw.Context context) {
        return [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('CUSTOMER DETAILS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                    pw.SizedBox(height: 4),
                    pw.Text(p.customerName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: navyColor)),
                    pw.Text('Phone: ${p.customerPhone}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('NET OUTSTANDING BALANCE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '₹${p.currentBalance.abs().toStringAsFixed(0)}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: p.currentBalance > 0 ? PdfColors.red900 : p.currentBalance < 0 ? PdfColors.green900 : PdfColors.grey900,
                      ),
                    ),
                    pw.Text(
                      p.currentBalance > 0 ? 'YOU RECEIVE (GETTING)' : p.currentBalance < 0 ? 'YOU PAY (GIVING)' : 'FULLY SETTLED',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: p.currentBalance > 0 ? PdfColors.red700 : p.currentBalance < 0 ? PdfColors.green700 : PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('TRANSACTION HISTORY', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: navyColor)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(5),
              2: pw.FlexColumnWidth(2.5),
              3: pw.FlexColumnWidth(2.5),
              4: pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: navyColor),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('DATE & TIME', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('REMARKS / DETAILS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('GAVE (CREDIT) (+)', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.right)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('TOOK (DEBIT) (-)', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.right)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('BALANCE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.right)),
                ],
              ),
              ...p.ledger.asMap().entries.map((entry) {
                final idx = entry.key;
                final row = entry.value;
                final type = row['type'] as String;
                final recordType = row['recordType'] as String;
                final amt = (row['amount'] as num).toDouble();
                final note = row['note'] as String;
                final dt = DateTime.parse(row['createdAt'] as String);
                final isCredit = type == 'credit';
                final isPayment = recordType == 'payment';
                final rBal = runningBalances[idx];
                final dateStr = DateFormat('dd MMM yyyy\nhh:mm a').format(dt);
                return pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(dateStr, style: const pw.TextStyle(fontSize: 7))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(note.isEmpty ? (isPayment ? 'Payment' : 'General Entry') : note, style: const pw.TextStyle(fontSize: 7))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(isCredit ? '₹${amt.toStringAsFixed(0)}' : '-', style: pw.TextStyle(fontSize: 7, color: isCredit ? PdfColors.red800 : PdfColors.black, fontWeight: isCredit ? pw.FontWeight.bold : pw.FontWeight.normal), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(!isCredit || isPayment ? '₹${amt.toStringAsFixed(0)}' : '-', style: pw.TextStyle(fontSize: 7, color: !isCredit || isPayment ? PdfColors.green800 : PdfColors.black, fontWeight: (!isCredit || isPayment) ? pw.FontWeight.bold : pw.FontWeight.normal), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('₹${rBal.abs().toStringAsFixed(0)} ${rBal > 0 ? '(Dr)' : rBal < 0 ? '(Cr)' : ''}', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: rBal > 0 ? PdfColors.red900 : rBal < 0 ? PdfColors.green900 : PdfColors.black), textAlign: pw.TextAlign.right)),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 24),
          if (p.currentBalance > 0 && p.upiId != null && p.upiId!.isNotEmpty) ...[
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(
                children: [
                  pw.Text('PAY OUTSTANDING BALANCE EASILY', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: navyColor)),
                  pw.SizedBox(height: 2),
                  pw.Text('Scan using any UPI app like PhonePe, Paytm, GooglePay to pay outstanding amount', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    height: 80,
                    width: 80,
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: 'upi://pay?pa=${p.upiId}&pn=${Uri.encodeComponent(p.storeName)}&am=${p.currentBalance}&tn=KhataPayment&tr=ORUSHOPSKHATA${DateTime.now().millisecondsSinceEpoch}',
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('UPI ID: ${p.upiId}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ],
        ];
      },
    ),
  );

  return pdf.save();
}

// ── Extension ────────────────────────────────────────────────────────────────

extension KhataStatementActions on KhataActionService {
  Future<void> sendLedgerStatementSms({
    required String customerName,
    required String customerPhone,
    required double currentBalance,
    required String storeName,
    String? upiId,
  }) async {
    try {
      String? cleanPhone = customerPhone.replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.startsWith('0')) {
        cleanPhone = cleanPhone.substring(1);
      }

      final text = generateStatementReminderText(
        customerName: customerName,
        customerPhone: customerPhone,
        currentBalance: currentBalance,
        storeName: storeName,
        upiId: upiId,
      );

      final Uri smsUri = Uri(
        scheme: 'smsto',
        path: cleanPhone,
        queryParameters: <String, String>{'body': text},
      );

      bool launched = false;
      try {
        launched = await launchUrl(smsUri, mode: LaunchMode.externalNonBrowserApplication);
      } catch (_) {}

      if (!launched) {
        final Uri fallbackSmsUri = Uri(
          scheme: 'sms',
          path: cleanPhone,
          queryParameters: <String, String>{'body': text},
        );
        try {
          launched = await launchUrl(fallbackSmsUri, mode: LaunchMode.externalNonBrowserApplication);
        } catch (_) {}
      }

      if (!launched) {
        await Share.share(text);
      }
    } catch (e) {
      if (kDebugMode) print('SMS statement error: $e');
      rethrow;
    }
  }

  Future<void> shareLedgerStatementWhatsApp({
    required String customerName,
    required String customerPhone,
    required double currentBalance,
    required String storeName,
    String? upiId,
  }) async {
    try {
      bool isWhatsAppInstalled = false;
      try {
        isWhatsAppInstalled = await canLaunchUrl(Uri.parse('whatsapp://send'));
      } catch (_) {}

      final text = generateStatementReminderText(
        customerName: customerName,
        customerPhone: customerPhone,
        currentBalance: currentBalance,
        storeName: storeName,
        upiId: upiId,
      );

      if (isWhatsAppInstalled) {
        String phone = customerPhone.replaceAll(RegExp(r'\D'), '');
        if (phone.startsWith('0')) phone = phone.substring(1);
        if (phone.length == 10) phone = '91$phone';

        final whatsappUri = Uri(
          scheme: 'whatsapp',
          host: 'send',
          queryParameters: <String, String>{'phone': phone, 'text': text},
        );
        bool launched = false;
        try {
          launched = await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        } catch (_) {}
        if (!launched) {
          await sendLedgerStatementSms(
            customerName: customerName,
            customerPhone: customerPhone,
            currentBalance: currentBalance,
            storeName: storeName,
            upiId: upiId,
          );
        }
      } else {
        await sendLedgerStatementSms(
          customerName: customerName,
          customerPhone: customerPhone,
          currentBalance: currentBalance,
          storeName: storeName,
          upiId: upiId,
        );
      }
    } catch (e) {
      if (kDebugMode) print('WhatsApp statement error: $e');
      await sendLedgerStatementSms(
        customerName: customerName,
        customerPhone: customerPhone,
        currentBalance: currentBalance,
        storeName: storeName,
        upiId: upiId,
      );
    }
  }

  Future<Uint8List> generateLedgerStatementPdfBytes({
    required String customerName,
    required String customerPhone,
    required List<Map<String, dynamic>> ledger,
    required String storeName,
    required String storePhone,
    required String storeAddress,
    required String? upiId,
    required double currentBalance,
    String? receiptBannerTitle,
  }) async {
    // Try to get pre-warmed bytes from cache; fall back to downloading if needed.
    Future<Uint8List> getCachedBytes(String key, Future<pw.Font> Function() loader) async {
      final cached = await PdfBaseCache.defaultCache.get(key);
      if (cached != null) return cached;
      await loader();
      return (await PdfBaseCache.defaultCache.get(key))!;
    }

    final fontBytes   = await getCachedBytes('NotoSans-Regular',             PdfGoogleFonts.notoSansRegular);
    final boldBytes   = await getCachedBytes('NotoSans-Bold',                PdfGoogleFonts.notoSansBold);
    final symbolBytes = await getCachedBytes('NotoSansDevanagari-Regular',   PdfGoogleFonts.notoSansDevanagariRegular);

    final bannerText = (receiptBannerTitle != null && receiptBannerTitle.trim().isNotEmpty)
        ? '$receiptBannerTitle Digital Khata'
        : 'Powered by OruShops Digital Khata';

    return compute(_buildPdfInIsolate, _PdfParams(
      fontBytes: fontBytes,
      boldFontBytes: boldBytes,
      symbolFontBytes: symbolBytes,
      customerName: customerName,
      customerPhone: customerPhone,
      ledger: ledger,
      storeName: storeName,
      storePhone: storePhone,
      storeAddress: storeAddress,
      upiId: upiId,
      currentBalance: currentBalance,
      bannerText: bannerText,
    ));
  }

  Future<void> shareLedgerStatementPdf({
    required String customerName,
    required String customerPhone,
    required List<Map<String, dynamic>> ledger,
    required String storeName,
    required String storePhone,
    required String storeAddress,
    required String? upiId,
    required double currentBalance,
    String? receiptBannerTitle,
  }) async {
    try {
      final pdfBytes = await generateLedgerStatementPdfBytes(
        customerName: customerName,
        customerPhone: customerPhone,
        ledger: ledger,
        storeName: storeName,
        storePhone: storePhone,
        storeAddress: storeAddress,
        upiId: upiId,
        currentBalance: currentBalance,
        receiptBannerTitle: receiptBannerTitle,
      );
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Ledger_Statement_${customerName.replaceAll(' ', '_')}.pdf');
      await file.writeAsBytes(pdfBytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Account Statement - $customerName',
        text: 'Hello, please find attached your digital ledger account statement.',
      );
    } catch (e) {
      if (kDebugMode) print('Share statement PDF error: $e');
      rethrow;
    }
  }
}
