import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

part 'khata_action/entry_pdf_actions.dart';
part 'khata_action/statement_actions.dart';
class KhataActionService {
  KhataActionService();

  // ── Text/SMS Formatter Helpers ─────────────────────────────────────────────

  String generateEntryText({
    required String customerName,
    required String customerPhone,
    required double amount,
    required String recordType,
    required String type,
    required String note,
    required DateTime createdAt,
    required String storeName,
    required double currentBalance,
  }) {
    final buffer = StringBuffer();
    final isCredit = type == 'credit';
    final isPayment = recordType == 'payment';
    final balanceStr = currentBalance.abs().toStringAsFixed(0);
    
    String actionLabel = '';
    if (isPayment) {
      actionLabel = 'RECEIVED PAYMENT (Liya) 🟢';
    } else if (isCredit) {
      actionLabel = 'GAVE CREDIT (Diya) 🔴';
    } else {
      actionLabel = 'GOT PAYMENT / DEBITED 🟢';
    }

    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);

    buffer.writeln('📜 *TRANSACTION VOUCHER*');
    buffer.writeln('---------------------------------------');
    buffer.writeln('*Store*: $storeName');
    buffer.writeln('*Customer*: $customerName ($customerPhone)');
    buffer.writeln('---------------------------------------');
    buffer.writeln('*Action*: $actionLabel');
    buffer.writeln('*Amount*: ₹${amount.toStringAsFixed(0)}');
    buffer.writeln('*Date*: $dateStr');
    if (note.isNotEmpty) {
      buffer.writeln('*Note*: $note');
    }
    buffer.writeln('---------------------------------------');
    
    if (currentBalance == 0) {
      buffer.writeln('*Current Balance*: ₹0 (Fully Settled) 🎉');
    } else if (currentBalance > 0) {
      buffer.writeln('*Pending Outstanding*: ₹$balanceStr (You owe us) 🔴');
    } else {
      buffer.writeln('*Advance Balance*: ₹$balanceStr (We owe you) 🟢');
    }
    buffer.writeln('---------------------------------------');
    buffer.writeln('Thank you! Powered by *OruShops* Digital Khata 🙏');
    
    return buffer.toString();
  }

  String generateStatementReminderText({
    required String customerName,
    required String customerPhone,
    required double currentBalance,
    required String storeName,
    String? upiId,
  }) {
    final buffer = StringBuffer();
    final balanceStr = currentBalance.abs().toStringAsFixed(0);

    buffer.writeln('🔔 *PAYMENT REMINDER*');
    buffer.writeln('---------------------------------------');
    buffer.writeln('*From*: $storeName');
    buffer.writeln('*To*: $customerName');
    buffer.writeln('---------------------------------------');
    buffer.writeln('Dear customer, this is a friendly reminder to settle your outstanding balance.');
    buffer.writeln('');
    
    if (currentBalance > 0) {
      buffer.writeln('*Total Outstanding*: ₹$balanceStr (Pending) 🔴');
    } else if (currentBalance < 0) {
      buffer.writeln('*Advance Balance*: ₹$balanceStr (We owe you) 🟢');
    } else {
      buffer.writeln('*Outstanding Balance*: ₹0 (Settle/Cleared) 🎉');
    }
    
    if (currentBalance > 0 && upiId != null && upiId.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('*Scan & Pay Instantly via UPI*:');
      buffer.writeln(generateUpiString(upiId, storeName, currentBalance));
    }
    
    buffer.writeln('---------------------------------------');
    buffer.writeln('Thank you for your business! *OruShops* 🙏');
    
    return buffer.toString();
  }

  // ── UPI Generator ──────────────────────────────────────────────────────────

  String generateUpiString(String upiId, String storeName, double amount) {
    return 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(storeName)}&am=$amount&tn=KhataPayment&tr=ORUSHOPSKHATA${DateTime.now().millisecondsSinceEpoch}';
  }

  // ── Single Entry Actions ───────────────────────────────────────────────────

  Future<void> sendLedgerEntrySms({
    required String customerName,
    required String customerPhone,
    required double amount,
    required String recordType,
    required String type,
    required String note,
    required DateTime createdAt,
    required String storeName,
    required double currentBalance,
  }) async {
    try {
      String? cleanPhone = customerPhone.replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.startsWith('0')) {
        cleanPhone = cleanPhone.substring(1);
      }

      final text = generateEntryText(
        customerName: customerName,
        customerPhone: customerPhone,
        amount: amount,
        recordType: recordType,
        type: type,
        note: note,
        createdAt: createdAt,
        storeName: storeName,
        currentBalance: currentBalance,
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
      if (kDebugMode) print('SMS share error: $e');
      rethrow;
    }
  }

  Future<void> shareLedgerEntryToWhatsAppWithSmsFallback({
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
    required Uint8List? receiptImageBytes,
    required VoidCallback onRedirectingToSms,
  }) async {
    try {
      if (receiptImageBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final imageFile = File('${tempDir.path}/Khata_${createdAt.millisecondsSinceEpoch}.png');
        await imageFile.writeAsBytes(receiptImageBytes);

        // Try direct WhatsApp via native platform method channel
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
          await Share.shareXFiles(
            [XFile(imageFile.path, mimeType: 'image/png')],
            subject: 'Transaction Voucher from $storeName',
          );
        }
        return;
      }

      // No image bytes - check and launch WhatsApp URL scheme
      bool isWhatsAppInstalled = false;
      try {
        isWhatsAppInstalled = await canLaunchUrl(Uri.parse('whatsapp://send'));
      } catch (_) {}

      if (isWhatsAppInstalled) {
        String phone = customerPhone.replaceAll(RegExp(r'\D'), '');
        if (phone.startsWith('0')) phone = phone.substring(1);
        if (phone.length == 10) phone = '91$phone';

        final text = generateEntryText(
          customerName: customerName,
          customerPhone: customerPhone,
          amount: amount,
          recordType: recordType,
          type: type,
          note: note,
          createdAt: createdAt,
          storeName: storeName,
          currentBalance: currentBalance,
        );

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
          onRedirectingToSms();
          await sendLedgerEntrySms(
            customerName: customerName,
            customerPhone: customerPhone,
            amount: amount,
            recordType: recordType,
            type: type,
            note: note,
            createdAt: createdAt,
            storeName: storeName,
            currentBalance: currentBalance,
          );
        }
      } else {
        onRedirectingToSms();
        await sendLedgerEntrySms(
          customerName: customerName,
          customerPhone: customerPhone,
          amount: amount,
          recordType: recordType,
          type: type,
          note: note,
          createdAt: createdAt,
          storeName: storeName,
          currentBalance: currentBalance,
        );
      }
    } catch (e) {
      if (kDebugMode) print('WhatsApp entry share fallback error: $e');
      onRedirectingToSms();
      await sendLedgerEntrySms(
        customerName: customerName,
        customerPhone: customerPhone,
        amount: amount,
        recordType: recordType,
        type: type,
        note: note,
        createdAt: createdAt,
        storeName: storeName,
        currentBalance: currentBalance,
      );
    }
  }

}
