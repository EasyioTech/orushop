import 'dart:convert';
import '../../core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/table_constants.dart';
import '../../features/onboarding/models/shop_models.dart';
import '../../providers/settings_provider.dart';
import 'write_queue.dart';

final shopCatalogServiceProvider = Provider((ref) => ShopCatalogService(
      ref.watch(databaseHelperProvider),
      ref.watch(writeQueueProvider),
    ));

class CatalogItem {
  final String name;
  final String? category;
  final String? sku;
  final ShopType shopType;

  CatalogItem({
    required this.name, 
    this.category,
    this.sku,
    required this.shopType,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'sku': sku,
      'shopType': shopType.name,
    };
  }

  factory CatalogItem.fromMap(Map<String, dynamic> map) {
    return CatalogItem(
      name: map['name'],
      category: map['category'],
      sku: map['sku'],
      shopType: ShopType.values.firstWhere(
        (e) => e.name == map['shopType'],
        orElse: () => ShopType.other,
      ),
    );
  }
}


class ShopCatalogService {
  final DatabaseHelper _dbHelper;
  final WriteQueue _queue;
  static const String _baseUrl = 'https://catalog-api.gamingcristy19.workers.dev';

  ShopCatalogService(this._dbHelper, this._queue);

  /// Maps ShopType to the string expected by the catalog API.
  String _getApiStoreType(ShopType shopType) {
    switch (shopType) {
      case ShopType.medical:
        return 'medical';
      case ShopType.grocery:
        return 'grocery';
      case ShopType.electronics:
        return 'electronics';
      case ShopType.clothing:
        return 'clothing';
      default:
        // Default to a known type or handle as unsupported
        return shopType.name.toLowerCase();
    }
  }

  /// Downloads the catalog for a specific shop type and stores it locally.
  Future<void> syncCatalog(ShopType shopType) async {
    try {
      final apiType = _getApiStoreType(shopType);
      appLogger.debug('📥 Syncing full catalog for $apiType from Cloudflare...');

      final response = await http.get(Uri.parse('$_baseUrl/catalog?type=$apiType&limit=500'));

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);

        // Handle both formats: {success, data, ...} and direct array
        List<Map<String, dynamic>> data = [];
        if (decoded is List) {
          data = decoded.cast<Map<String, dynamic>>();
        } else if (decoded is Map) {
          if (decoded.containsKey('data')) {
            data = List<Map<String, dynamic>>.from(decoded['data'] ?? []);
          } else if (decoded.containsKey('results')) {
            data = List<Map<String, dynamic>>.from(decoded['results'] ?? []);
          }
        }

        if (data.isNotEmpty) {
          appLogger.debug('✅ Received ${data.length} items. Seeding database...');
          await _queue.enqueue(() => _dbHelper.seedDatabase(data, shopType.name));
          appLogger.debug('✅ Successfully synced and seeded ${data.length} products for ${shopType.name}');
        } else {
          appLogger.debug('⚠️ No catalog data returned for ${shopType.name}');
        }
      } else if (response.statusCode == 400) {
        appLogger.debug('⚠️ Catalog not available for $apiType (400): ${response.body}');
        // Silently return, no need to throw for unsupported store types
      } else {
        appLogger.debug('❌ Catalog Sync Failed: ${response.statusCode}');
        appLogger.debug('❌ Response Body: ${response.body}');
        throw Exception('Failed to download catalog: ${response.statusCode}');
      }
    } catch (e) {
      appLogger.debug('⚠️ Catalog Sync Error Details: $e');
      // Seed mock data in debug mode only for testing
      if (kDebugMode) {
        await _seedMockData(shopType);
      }
    }
  }

  Future<void> _seedMockData(ShopType shopType) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    
    List<Map<String, String>> mockData = [];
    if (shopType == ShopType.medical) {
      mockData = [
        {'n': 'Paracetamol 500mg', 'c': 'Tablets'},
        {'n': 'Amoxicillin 250mg', 'c': 'Tablets'},
        {'n': 'Cetirizine', 'c': 'Syrups'},
        {'n': 'Dolo 650', 'c': 'Tablets'},
      ];
    } else if (shopType == ShopType.grocery) {
      mockData = [
        {'n': 'Tata Salt 1kg', 'c': 'Groceries'},
        {'n': 'Aashirvaad Atta 5kg', 'c': 'Groceries'},
        {'n': 'Maggi Noodles 70g', 'c': 'Groceries'},
      ];
    }

    for (var item in mockData) {
      batch.insert(TableConstants.globalCatalog, {
        'name': item['n'],
        'category': item['c'],
        'shopType': shopType.name,
      });
    }
    await _queue.enqueue(() => batch.commit(noResult: true));
    appLogger.debug('🧪 Seeded mock data for ${shopType.name}');
  }

  /// Searches the local catalog for products matching the query for a specific shop type.
  Future<List<CatalogItem>> searchLocal(String query, ShopType shopType) async {
    if (query.isEmpty) return [];
    
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      TableConstants.globalCatalog,
      where: 'shopType = ? AND (name LIKE ? OR sku LIKE ?)',
      whereArgs: [shopType.name, '%$query%', '%$query%'],
      limit: 20,
    );


    return List.generate(maps.length, (i) {
      return CatalogItem.fromMap(maps[i]);
    });
  }

  /// Checks if the catalog for a specific shop type is already downloaded
  Future<bool> isCatalogDownloaded(ShopType shopType) async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM ${TableConstants.globalCatalog} WHERE shopType = ?',
      [shopType.name],
    ));
    return (count ?? 0) > 0;
  }
}