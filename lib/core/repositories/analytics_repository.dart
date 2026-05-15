import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../database/table_constants.dart';

class AnalyticsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<DailySalesTotal> getDailySalesTotal(DateTime date) async {
    final db = await _dbHelper.database;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    final result = await db.rawQuery(
      'SELECT SUM(finalAmount) as total, COUNT(*) as count FROM sales '
      'WHERE date(createdAt) = ?',
      [dateStr],
    );

    final row = result.isNotEmpty ? result.first : {};
    final total = (row['total'] as num?)?.toDouble() ?? 0.0;
    final count = (row['count'] as int?) ?? 0;
    
    debugPrint('AnalyticsRepo: getDailySalesTotal for $dateStr -> Total: $total, Count: $count');
    
    return DailySalesTotal(
      total: total,
      count: count,
    );
  }

  Future<List<TopProduct>> getTopProductsLast30Days() async {
    final db = await _dbHelper.database;
    final thirtyDaysAgo =
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

    final result = await db.rawQuery(
      'SELECT si.productId, p.name, SUM(si.quantity) as units '
      'FROM sale_items si '
      'JOIN sales s ON si.saleId = s.id '
      'JOIN products p ON si.productId = p.id '
      'WHERE s.createdAt >= ? '
      'GROUP BY si.productId, p.name '
      'ORDER BY units DESC LIMIT 10',
      [thirtyDaysAgo],
    );

    return result
        .map((row) => TopProduct(
              productId: row['productId'] as int,
              productName: row['name'] as String,
              unitsSold: (row['units'] as int?) ?? 0,
            ))
        .toList();
  }

  Future<List<LowStockProduct>> getLowStockProducts(int threshold) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      'SELECT id, name, quantity FROM products '
      'WHERE quantity <= ? ORDER BY quantity ASC',
      [threshold],
    );

    return result
        .map((row) => LowStockProduct(
              productId: row['id'] as int,
              productName: row['name'] as String,
              quantity: (row['quantity'] as int?) ?? 0,
            ))
        .toList();
  }

  Future<List<ExpiringBatch>> getExpiringBatches(int alertDays) async {
    final db = await _dbHelper.database;
    final alertDate = DateTime.now()
        .add(Duration(days: alertDays))
        .toIso8601String()
        .split('T')[0];

    final result = await db.rawQuery(
      'SELECT p.name, pb.quantity, pb.expiryDate FROM product_batches pb '
      'JOIN products p ON pb.productId = p.id '
      'WHERE pb.quantity > 0 AND pb.expiryDate <= ? '
      'ORDER BY pb.expiryDate ASC',
      [alertDate],
    );

    return result
        .map((row) => ExpiringBatch(
              productName: row['name'] as String,
              quantity: (row['quantity'] as int?) ?? 0,
              expiryDate: DateTime.parse(row['expiryDate'] as String),
            ))
        .toList();
  }

  Future<List<SalesHistoryItem>> getSalesHistory({
    int limit = 50,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = 'WHERE s.createdAt >= ? AND s.createdAt < ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    final result = await db.rawQuery(
      'SELECT s.id, s.finalAmount, s.paymentMethod, s.createdAt, COUNT(si.id) as itemCount '
      'FROM sales s LEFT JOIN sale_items si ON s.id = si.saleId '
      '$whereClause '
      'GROUP BY s.id '
      'ORDER BY s.createdAt DESC '
      'LIMIT ? OFFSET ?',
      [...whereArgs, limit, offset],
    );

    return result
        .map((row) => SalesHistoryItem(
              saleId: row['id'] as int,
              finalAmount: (row['finalAmount'] as num).toDouble(),
              paymentMethod: row['paymentMethod'] as String,
              createdAt: DateTime.parse(row['createdAt'] as String),
              itemCount: (row['itemCount'] as int?) ?? 0,
            ))
        .toList();
  }

  Future<SaleDetail?> getSaleDetail(int saleId) async {
    final db = await _dbHelper.database;

    final saleResult = await db.query(
      TableConstants.sales,
      where: 'id = ?',
      whereArgs: [saleId],
    );

    if (saleResult.isEmpty) return null;

    final saleRow = saleResult.first;
    final itemsResult = await db.rawQuery(
      'SELECT si.productName, si.quantity, si.unitPrice FROM sale_items si '
      'WHERE si.saleId = ?',
      [saleId],
    );

    final items = itemsResult
        .map((row) => SaleDetailItem(
              productName: row['productName'] as String,
              quantity: (row['quantity'] as int?) ?? 0,
              unitPrice: (row['unitPrice'] as num).toDouble(),
            ))
        .toList();

    return SaleDetail(
      saleId: saleRow['id'] as int,
      finalAmount: (saleRow['finalAmount'] as num).toDouble(),
      discountAmount: (saleRow['discountAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: saleRow['paymentMethod'] as String,
      createdAt: DateTime.parse(saleRow['createdAt'] as String),
      items: items,
    );
  }

  Future<List<DailySalesData>> getSalesTrend(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final startStr = DateFormat('yyyy-MM-dd').format(start);
    final endStr = DateFormat('yyyy-MM-dd').format(end);

    final result = await db.rawQuery(
      'SELECT date(createdAt) as date, SUM(finalAmount) as total, COUNT(*) as count '
      'FROM sales '
      'WHERE date(createdAt) BETWEEN ? AND ? '
      'GROUP BY date(createdAt) '
      'ORDER BY date ASC',
      [startStr, endStr],
    );

    return result
        .map((row) => DailySalesData(
              date: DateTime.parse(row['date'] as String),
              totalAmount: (row['total'] as num?)?.toDouble() ?? 0.0,
              transactionCount: (row['count'] as int?) ?? 0,
            ))
        .toList();
  }

  Future<PeriodAnalytics> getPeriodAnalytics(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(finalAmount) as total, AVG(finalAmount) as average, '
      'COUNT(*) as count, COUNT(DISTINCT paymentMethod) as methods '
      'FROM sales WHERE createdAt >= ? AND createdAt < ?',
      [start.toIso8601String(), end.add(const Duration(days: 1)).toIso8601String()],
    );

    final row = result.isNotEmpty ? result.first : {};
    final totalReturns = await db.rawQuery(
      'SELECT SUM(refundAmount) as refunded FROM ${TableConstants.refunds} WHERE createdAt >= ? AND createdAt < ?',
      [start.toIso8601String(), end.add(const Duration(days: 1)).toIso8601String()],
    );

    final refundRow = totalReturns.isNotEmpty ? totalReturns.first : {};
    final refunded = (refundRow['refunded'] as num?)?.toDouble() ?? 0.0;

    return PeriodAnalytics(
      totalSales: (row['total'] as num?)?.toDouble() ?? 0.0,
      averageTransaction: (row['average'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (row['count'] as int?) ?? 0,
      refundedAmount: refunded,
      netSales: ((row['total'] as num?)?.toDouble() ?? 0.0) - refunded,
    );
  }

  Future<List<PaymentMethodBreakdown>> getPaymentMethodBreakdown(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT paymentMethod, COUNT(*) as count, SUM(finalAmount) as total '
      'FROM sales WHERE createdAt >= ? AND createdAt < ? '
      'GROUP BY paymentMethod ORDER BY total DESC',
      [start.toIso8601String(), end.add(const Duration(days: 1)).toIso8601String()],
    );

    return result
        .map((row) => PaymentMethodBreakdown(
              method: row['paymentMethod'] as String,
              count: (row['count'] as int?) ?? 0,
              totalAmount: (row['total'] as num?)?.toDouble() ?? 0.0,
            ))
        .toList();
  }
}

class DailySalesTotal {
  final double total;
  final int count;

  DailySalesTotal({required this.total, required this.count});
}

class TopProduct {
  final int productId;
  final String productName;
  final int unitsSold;

  TopProduct({
    required this.productId,
    required this.productName,
    required this.unitsSold,
  });
}

class LowStockProduct {
  final int productId;
  final String productName;
  final int quantity;

  LowStockProduct({
    required this.productId,
    required this.productName,
    required this.quantity,
  });
}

class ExpiringBatch {
  final String productName;
  final int quantity;
  final DateTime expiryDate;

  ExpiringBatch({
    required this.productName,
    required this.quantity,
    required this.expiryDate,
  });
}

class SalesHistoryItem {
  final int saleId;
  final double finalAmount;
  final String paymentMethod;
  final DateTime createdAt;
  final int itemCount;

  SalesHistoryItem({
    required this.saleId,
    required this.finalAmount,
    required this.paymentMethod,
    required this.createdAt,
    required this.itemCount,
  });
}

class SaleDetail {
  final int saleId;
  final double finalAmount;
  final double discountAmount;
  final String paymentMethod;
  final DateTime createdAt;
  final List<SaleDetailItem> items;

  SaleDetail({
    required this.saleId,
    required this.finalAmount,
    required this.discountAmount,
    required this.paymentMethod,
    required this.createdAt,
    required this.items,
  });
}

class SaleDetailItem {
  final String productName;
  final int quantity;
  final double unitPrice;

  SaleDetailItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get subtotal => quantity * unitPrice;
}

class DailySalesData {
  final DateTime date;
  final double totalAmount;
  final int transactionCount;

  DailySalesData({
    required this.date,
    required this.totalAmount,
    required this.transactionCount,
  });
}

class PeriodAnalytics {
  final double totalSales;
  final double averageTransaction;
  final int transactionCount;
  final double refundedAmount;
  final double netSales;

  PeriodAnalytics({
    required this.totalSales,
    required this.averageTransaction,
    required this.transactionCount,
    required this.refundedAmount,
    required this.netSales,
  });
}

class PaymentMethodBreakdown {
  final String method;
  final int count;
  final double totalAmount;

  PaymentMethodBreakdown({
    required this.method,
    required this.count,
    required this.totalAmount,
  });
}

