part of '../khata_action_service.dart';

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
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final symbolFont = await PdfGoogleFonts.notoSansDevanagariRegular();
    final navyColor = PdfColor.fromHex('#0F172A');

    final bannerText = (receiptBannerTitle != null && receiptBannerTitle.trim().isNotEmpty) 
        ? '$receiptBannerTitle Digital Khata' 
        : 'Powered by OruShops Digital Khata';

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
                      pw.Text(storeName.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: navyColor)),
                      if (storeAddress.isNotEmpty) pw.Text(storeAddress, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      if (storePhone.isNotEmpty) pw.Text('Phone: $storePhone', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
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
                  pw.Text(bannerText, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          // Calculate running balance starting from the oldest to newest
          // The list `ledger` is currently newest first, so we reverse it to compute running balance,
          // then we can render it newest first again!
          final List<Map<String, dynamic>> chronLedger = List.from(ledger.reversed);
          double runBal = 0.0;
          final List<double> chronBalances = [];
          for (final row in chronLedger) {
            final type = row['type'] as String;
            final recordType = row['recordType'] as String;
            final amt = (row['amount'] as num).toDouble();
            final isCredit = type == 'credit';
            final isPayment = recordType == 'payment';

            if (isPayment) {
              runBal -= amt;
            } else if (isCredit) {
              runBal += amt;
            } else {
              runBal -= amt;
            }
            chronBalances.add(runBal);
          }
          final List<double> runningBalances = List.from(chronBalances.reversed);

          return [
            // Customer Profile Details Card
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
                      pw.Text(customerName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: navyColor)),
                      pw.Text('Phone: $customerPhone', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('NET OUTSTANDING BALANCE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '₹${currentBalance.abs().toStringAsFixed(0)}',
                        style: pw.TextStyle(
                          fontSize: 18, 
                          fontWeight: pw.FontWeight.bold,
                          color: currentBalance > 0 ? PdfColors.red900 : currentBalance < 0 ? PdfColors.green900 : PdfColors.grey900,
                        ),
                      ),
                      pw.Text(
                        currentBalance > 0 ? 'YOU RECEIVE (GETTING)' : currentBalance < 0 ? 'YOU PAY (GIVING)' : 'FULLY SETTLED',
                        style: pw.TextStyle(
                          fontSize: 8, 
                          fontWeight: pw.FontWeight.bold,
                          color: currentBalance > 0 ? PdfColors.red700 : currentBalance < 0 ? PdfColors.green700 : PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Ledger Statement Table Title
            pw.Text('TRANSACTION HISTORY', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: navyColor)),
            pw.SizedBox(height: 8),

            // Table of Transactions
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(3), // Date
                1: pw.FlexColumnWidth(5), // Remarks
                2: pw.FlexColumnWidth(2.5), // Gave (Credit)
                3: pw.FlexColumnWidth(2.5), // Got/Took (Debit)
                4: pw.FlexColumnWidth(3), // Balance
              },
              children: [
                // Table Header
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
                // Table Rows
                ...ledger.asMap().entries.map((entry) {
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
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6), 
                        child: pw.Text(
                          isCredit ? '₹${amt.toStringAsFixed(0)}' : '-', 
                          style: pw.TextStyle(fontSize: 7, color: isCredit ? PdfColors.red800 : PdfColors.black, fontWeight: isCredit ? pw.FontWeight.bold : pw.FontWeight.normal),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6), 
                        child: pw.Text(
                          !isCredit || isPayment ? '₹${amt.toStringAsFixed(0)}' : '-', 
                          style: pw.TextStyle(fontSize: 7, color: !isCredit || isPayment ? PdfColors.green800 : PdfColors.black, fontWeight: (!isCredit || isPayment) ? pw.FontWeight.bold : pw.FontWeight.normal),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6), 
                        child: pw.Text(
                          '₹${rBal.abs().toStringAsFixed(0)} ${rBal > 0 ? '(Dr)' : rBal < 0 ? '(Cr)' : ''}', 
                          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: rBal > 0 ? PdfColors.red900 : rBal < 0 ? PdfColors.green900 : PdfColors.black),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 24),

            // Settle Section / QR Code
            if (currentBalance > 0 && upiId != null && upiId.isNotEmpty) ...[
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
                        data: generateUpiString(upiId, storeName, currentBalance),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('UPI ID: $upiId', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ];
        },
      ),
    );

    return await pdf.save();
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
