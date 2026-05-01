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
    String currencySymbol,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('$storeName - Receipt #${sale.id}');
    buffer.writeln('Date: ${DateFormatter.formatDate(sale.createdAt)}');
    buffer.writeln('---');

    for (final item in items) {
      final amount = item.quantity * item.unitPrice;
      buffer.writeln(
        '${item.quantity}x ${CurrencyFormatter.format(item.unitPrice)} = ${CurrencyFormatter.format(amount)}',
      );
    }

    buffer.writeln('---');
    buffer.writeln('Total: ${CurrencyFormatter.format(sale.finalAmount)}');
    buffer.writeln('Payment: ${sale.paymentMethod}');

    return buffer.toString();
  }
}
