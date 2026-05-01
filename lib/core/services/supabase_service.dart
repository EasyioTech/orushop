import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../database/database_helper.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() => _instance;

  SupabaseService._internal();

  late SupabaseClient _client;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> initialize(String url, String anonKey) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
    _client = Supabase.instance.client;
  }

  SupabaseClient get client => _client;

  Future<bool> isOnline() async {
    try {
      await _client.from('health_check').select().limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> backupDatabase(String userId) async {
    try {
      final db = await _dbHelper.database;

      final sales = await db.query('sales');
      final saleItems = await db.query('sale_items');
      final products = await db.query('products');
      final productBatches = await db.query('product_batches');
      final returns = await db.query('returns');
      final returnItems = await db.query('return_items');
      final refunds = await db.query('refunds');

      final backup = {
        'timestamp': DateTime.now().toIso8601String(),
        'sales': sales,
        'sale_items': saleItems,
        'products': products,
        'product_batches': productBatches,
        'returns': returns,
        'return_items': returnItems,
        'refunds': refunds,
      };

      final backupJson = jsonEncode(backup);

      await _client.storage.from('backups').uploadBinary(
            '$userId/backup_${DateTime.now().millisecondsSinceEpoch}.json',
            utf8.encode(backupJson),
            fileOptions: const FileOptions(contentType: 'application/json'),
          );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLastBackup(String userId) async {
    try {
      final files = await _client.storage
          .from('backups')
          .list(path: userId);

      if (files.isEmpty) return {};

      files.sort((a, b) {
        final aTime = (a.updatedAt as DateTime?) ?? DateTime(1970);
        final bTime = (b.updatedAt as DateTime?) ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });
      final latestFile = files.first;

      final content = await _client.storage
          .from('backups')
          .download('$userId/${latestFile.name}');

      return jsonDecode(utf8.decode(content));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restoreDatabase(String userId, Map<String, dynamic> backup) async {
    try {
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        await txn.delete('sale_items');
        await txn.delete('sales');
        await txn.delete('return_items');
        await txn.delete('returns');
        await txn.delete('refunds');
        await txn.delete('product_batches');
        await txn.delete('products');

        if (backup['products'] != null) {
          for (final product in backup['products']) {
            await txn.insert('products', product);
          }
        }

        if (backup['product_batches'] != null) {
          for (final batch in backup['product_batches']) {
            await txn.insert('product_batches', batch);
          }
        }

        if (backup['sales'] != null) {
          for (final sale in backup['sales']) {
            await txn.insert('sales', sale);
          }
        }

        if (backup['sale_items'] != null) {
          for (final item in backup['sale_items']) {
            await txn.insert('sale_items', item);
          }
        }

        if (backup['returns'] != null) {
          for (final return_ in backup['returns']) {
            await txn.insert('returns', return_);
          }
        }

        if (backup['return_items'] != null) {
          for (final item in backup['return_items']) {
            await txn.insert('return_items', item);
          }
        }

        if (backup['refunds'] != null) {
          for (final refund in backup['refunds']) {
            await txn.insert('refunds', refund);
          }
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncSalesData(String userId) async {
    try {
      final db = await _dbHelper.database;
      final sales = await db.rawQuery(
        'SELECT s.*, GROUP_CONCAT(si.id) as item_ids FROM sales s '
        'LEFT JOIN sale_items si ON s.id = si.saleId '
        'WHERE s.syncedAt IS NULL OR s.syncedAt < datetime("now", "-1 day") '
        'GROUP BY s.id',
      );

      for (final sale in sales) {
        await _client.from('sales_sync').insert({
          'user_id': userId,
          'sale_id': sale['id'],
          'final_amount': sale['finalAmount'],
          'payment_method': sale['paymentMethod'],
          'created_at': sale['createdAt'],
          'synced_at': DateTime.now().toIso8601String(),
        });

        await db.update(
          'sales',
          {'syncedAt': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [sale['id']],
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }
}
