import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/table_constants.dart';
import '../features/onboarding/models/shop_models.dart';

final shopCatalogServiceProvider = Provider((ref) => ShopCatalogService(ref.watch(databaseHelperProvider)));
final databaseHelperProvider = Provider((ref) => DatabaseHelper());

class CatalogItem {
  final String name;
  final String? category;
  final ShopType shopType;

  CatalogItem({
    required this.name, 
    this.category,
    required this.shopType,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'shopType': shopType.name,
    };
  }

  factory CatalogItem.fromMap(Map<String, dynamic> map) {
    return CatalogItem(
      name: map['name'],
      category: map['category'],
      shopType: ShopType.values.firstWhere(
        (e) => e.name == map['shopType'],
        orElse: () => ShopType.other,
      ),
    );
  }
}

class ShopCatalogService {
  final DatabaseHelper _dbHelper;
  static const String _baseUrl = 'https://catalog.retaildost.workers.dev'; // Placeholder

  ShopCatalogService(this._dbHelper);

  /// Downloads the catalog for a specific shop type and stores it locally.
  Future<void> syncCatalog(ShopType shopType) async {
    try {
      debugPrint('📥 Syncing catalog for ${shopType.name} from Cloudflare...');
      
      // Simulating a fetch from Cloudflare. 
      // In a real app, this URL would point to a worker or R2 bucket.
      final response = await http.get(Uri.parse('$_baseUrl/catalog?type=${shopType.name}'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final db = await _dbHelper.database;

        await db.transaction((txn) async {
          // Clear existing data for THIS shop type before syncing
          await txn.delete(
            TableConstants.globalCatalog, 
            where: 'shopType = ?', 
            whereArgs: [shopType.name],
          );
          
          final batch = txn.batch();
          for (var item in data) {
            batch.insert(TableConstants.globalCatalog, {
              'name': item['n'] ?? item['name'],
              'category': item['c'] ?? item['category'],
              'shopType': shopType.name,
            });
          }
          await batch.commit(noResult: true);
        });

        debugPrint('✅ Successfully synced ${data.length} products for ${shopType.name}');
      } else {
        // If the URL fails (which it will since it's a placeholder), 
        // we'll log it but not crash onboarding if we want a silent background fetch.
        // However, the user wants it at onboarding, so we should handle errors.
        throw Exception('Failed to download catalog: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Catalog Sync Error: $e');
      // For demo purposes, if it fails, we might want to seed some mock data 
      // so the user can see the "Fast Lookup" working.
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
    await batch.commit(noResult: true);
    debugPrint('🧪 Seeded mock data for ${shopType.name}');
  }

  /// Searches the local catalog for products matching the query for a specific shop type.
  Future<List<CatalogItem>> searchLocal(String query, ShopType shopType) async {
    if (query.isEmpty) return [];
    
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      TableConstants.globalCatalog,
      where: 'shopType = ? AND name LIKE ?',
      whereArgs: [shopType.name, '%$query%'],
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
