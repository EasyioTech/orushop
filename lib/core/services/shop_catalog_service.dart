import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/table_constants.dart';
import '../../features/onboarding/models/shop_models.dart';

final shopCatalogServiceProvider = Provider((ref) => ShopCatalogService(ref.watch(databaseHelperProvider)));
final databaseHelperProvider = Provider((ref) => DatabaseHelper());

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
  static const String _baseUrl = 'https://catalog-api.gamingcristy19.workers.dev'; 

  ShopCatalogService(this._dbHelper);

  /// Downloads the catalog for a specific shop type and stores it locally.
  Future<void> syncCatalog(ShopType shopType) async {
    try {
      debugPrint('📥 Syncing full catalog for ${shopType.name} from Cloudflare...');

      final response = await http.get(Uri.parse('$_baseUrl/catalog?type=${shopType.name}&limit=500'));

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);

        // Handle new API response format: {success, data, count, total, limit, offset}
        List<Map<String, dynamic>> data = [];
        if (decoded is Map && decoded.containsKey('data')) {
          data = List<Map<String, dynamic>>.from(decoded['data'] ?? []);
        } else if (decoded is List) {
          // Fallback for old format (array)
          data = decoded.cast<Map<String, dynamic>>();
        }

        if (data.isNotEmpty) {
          debugPrint('✅ Received ${data.length} items. Seeding database...');
          await _dbHelper.seedDatabase(data, shopType.name);
          debugPrint('✅ Successfully synced and seeded ${data.length} products for ${shopType.name}');
        } else {
          debugPrint('⚠️ No catalog data returned for ${shopType.name}');
        }
      } else {
        throw Exception('Failed to download catalog: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Catalog Sync Error: $e');
      // Seed mock data in debug mode only for testing
      if (kDebugMode) {
        await _seedMockData(shopType);
      }
      // In production, silently continue — catalog will be empty but app won't crash
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
    await batch.commit(noResult: true);
    debugPrint('🧪 Seeded mock data for ${shopType.name}');
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
