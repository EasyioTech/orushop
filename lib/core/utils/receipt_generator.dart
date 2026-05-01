import '../models/sale.dart';
import '../models/sale_item.dart';
import 'currency_formatter.dart';

class ReceiptGenerator {
  static String generateReceipt({
    required Sale sale,
    required List<SaleItem> items,
    String? storeName = 'RetailDost',
    String? storePhone,
  }) {
    final buffer = StringBuffer();
    final separator = '=' * 40;

    buffer.writeln(separator);
    buffer.writeln(storeName?.padLeft((40 + storeName.length) ~/ 2) ?? '');
    if (storePhone != null) {
      buffer.writeln(storePhone.padLeft((40 + storePhone.length) ~/ 2));
    }
    buffer.writeln(separator);
    buffer.writeln('Receipt #${sale.id.toString().padLeft(6, '0')}');
    buffer.writeln('Date: ${_formatDateTime(sale.createdAt)}');
    buffer.writeln(separator);

    buffer.writeln('ITEMS');
    buffer.writeln(separator);
    for (final item in items) {
      buffer.writeln('${item.productId} x${item.quantity}');
      buffer.writeln('  ${CurrencyFormatter.format(item.unitPrice)}/unit');
      buffer.writeln('  Total: ${CurrencyFormatter.format(item.totalPrice)}');
    }

    buffer.writeln(separator);
    buffer.writeln('Subtotal'.padRight(20) + CurrencyFormatter.format(sale.totalAmount).padLeft(18));
    if (sale.discountAmount > 0) {
      buffer.writeln('Discount'.padRight(20) + '−${CurrencyFormatter.format(sale.discountAmount)}'.padLeft(17));
    }
    buffer.writeln('-' * 40);
    buffer.writeln('Total'.padRight(20) + CurrencyFormatter.format(sale.finalAmount).padLeft(18));
    buffer.writeln('Payment: ${sale.paymentMethod}');
    if (sale.transactionId != null) {
      buffer.writeln('Transaction ID: ${sale.transactionId}');
    }
    buffer.writeln(separator);
    buffer.writeln('Thank you for your purchase!'.padLeft((40 + 28) ~/ 2));
    buffer.writeln(separator);

    return buffer.toString();
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
