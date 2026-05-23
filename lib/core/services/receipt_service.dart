import '../models/sale.dart';
import '../models/sale_item.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class ReceiptService {
  String generateReceipt(
    Sale sale,
    List<SaleItem> items,
    String storeName,
    String storePhone,
    String storeAddress,
    String currencySymbol,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('=' * 40);
    buffer.writeln(_centerText(storeName, 40));
    buffer.writeln('-' * 40);

    if (storeAddress.isNotEmpty) {
      buffer.writeln(_centerText(storeAddress, 40));
    }
    if (storePhone.isNotEmpty) {
      buffer.writeln(_centerText('Ph: $storePhone', 40));
    }

    buffer.writeln('=' * 40);
    buffer.writeln('Receipt #${sale.id}');
    buffer.writeln('Date: ${DateFormatter.formatDateTime(sale.createdAt)}');
    buffer.writeln('-' * 40);

    buffer.writeln('Item              Qty   Rate    Amount');
    buffer.writeln('-' * 40);

    for (final item in items) {
      final amount = item.quantity * item.unitPrice;
      final itemName = item.productId.toString().padRight(15);
      final qty = item.quantity.toString().padLeft(3);
      final rate = CurrencyFormatter.format(item.unitPrice).padLeft(6);
      final amountStr = CurrencyFormatter.format(amount).padLeft(6);

      buffer.writeln('$itemName $qty $rate $amountStr');
    }

    buffer.writeln('-' * 40);
    buffer.writeln('Subtotal: ${CurrencyFormatter.format(sale.totalAmount).padLeft(33)}');

    if (sale.discountAmount > 0) {
      buffer.writeln('Discount: ${CurrencyFormatter.format(sale.discountAmount).padLeft(32)}');
    }

    buffer.writeln('=' * 40);
    buffer.writeln('Total:    ${CurrencyFormatter.format(sale.finalAmount).padLeft(34)}');
    buffer.writeln('=' * 40);

    buffer.writeln('Payment: ${sale.paymentMethod}');
    buffer.writeln('Status: ${sale.status}');

    if (sale.customerPhone?.isNotEmpty ?? false) {
      buffer.writeln('Customer: ${sale.customerPhone}');
    }

    buffer.writeln('=' * 40);
    buffer.writeln(_centerText('Thank You!', 40));
    buffer.writeln('=' * 40);

    return buffer.toString();
  }

  String _centerText(String text, int width) {
    final padding = (width - text.length) ~/ 2;
    return ' ' * padding + text;
  }

  String generateReceiptPlain(
    Sale sale,
    List<SaleItem> items,
    String storeName,
    String currencySymbol, {
    String? receiptBannerTitle,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('*RECEIPT FROM ${storeName.toUpperCase()}*');
    buffer.writeln('------------------------------------------');
    buffer.writeln('Receipt: #${sale.id.toString().padLeft(6, '0')}');
    buffer.writeln('Date: ${DateFormatter.formatDateTime(sale.createdAt)}');
    buffer.writeln('------------------------------------------');
    buffer.writeln('Item            Qty    Rate     Amount');
    buffer.writeln('------------------------------------------');

    for (final item in items) {
      final amount = item.quantity * item.unitPrice;
      final name = item.productName ?? 'Item #${item.productId}';
      
      // Limit item name to 14 characters to preserve strict column alignment
      final dispName = name.length > 14 ? name.substring(0, 14) : name.padRight(14);
      
      final qtyStr = (item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString()).padLeft(5);
      final rateStr = CurrencyFormatter.format(item.unitPrice).padLeft(8);
      final amtStr = CurrencyFormatter.format(amount).padLeft(10);
      
      buffer.writeln('$dispName $qtyStr $rateStr $amtStr');
    }

    buffer.writeln('------------------------------------------');
    if (sale.discountAmount > 0) {
      buffer.writeln('Subtotal: ${CurrencyFormatter.format(sale.totalAmount).padLeft(32)}');
      buffer.writeln('Discount: -${CurrencyFormatter.format(sale.discountAmount).padLeft(31)}');
    }
    buffer.writeln('*TOTAL: ${CurrencyFormatter.format(sale.finalAmount)}*');
    buffer.writeln('Payment: ${sale.paymentMethod}');
    buffer.writeln('------------------------------------------');
    buffer.writeln('Thank you for shopping with us!');
    
    final bannerText = (receiptBannerTitle != null && receiptBannerTitle.trim().isNotEmpty) 
        ? receiptBannerTitle 
        : 'Powered by OruShops';
    buffer.writeln(bannerText);

    return buffer.toString();
  }
}


