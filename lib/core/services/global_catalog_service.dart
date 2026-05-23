import 'dart:convert';
import '../utils/app_logger.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import './catalog_data.dart';
import '../database/database_helper.dart';
import '../database/table_constants.dart';


final globalCatalogServiceProvider = Provider((ref) => GlobalCatalogService(DatabaseHelper()));


class GlobalProduct {
  final String name;
  final String category;
  final double typicalPrice;
  final double typicalCost;
  final String sku;
  final String? brand;
  final String? imageUrl;
  final String? imagePath;
  final String? template;
  final bool isService;
  final bool isLoose;
  final double? wholesalePrice;
  
  // New 29-column fields
  final double? mrp;
  final String? hsnCode;
  final double? taxRate;
  final String? manufacturer;
  final double? initialStock;
  final double? reorderLevel;
  final String? uom;
  final String? packagingUnit;
  final double? conversionFactor;
  final String? batchNumber;
  final String? serialNumber;
  final String? imeiNumber;
  final String? warrantyPeriod;
  final String? expiryDate;
  final String? medicineSchedule;
  final String? recipeInstructions;
  final String? weightVolume;
  final String? isbnNumber;

  const GlobalProduct({
    required this.name,
    required this.category,
    required this.typicalPrice,
    required this.typicalCost,
    required this.sku,
    this.brand,
    this.imageUrl,
    this.imagePath,
    this.template,
    this.isService = false,
    this.isLoose = false,
    this.wholesalePrice,
    this.mrp,
    this.hsnCode,
    this.taxRate,
    this.manufacturer,
    this.initialStock,
    this.reorderLevel,
    this.uom,
    this.packagingUnit,
    this.conversionFactor,
    this.batchNumber,
    this.serialNumber,
    this.imeiNumber,
    this.warrantyPeriod,
    this.expiryDate,
    this.medicineSchedule,
    this.recipeInstructions,
    this.weightVolume,
    this.isbnNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': typicalPrice,
      'sku': sku,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'template': template,
      'isService': isService ? 1 : 0,
      'isLoose': isLoose ? 1 : 0,
      'wholesalePrice': wholesalePrice,
      'costPrice': typicalCost,
      'quantity': initialStock ?? 0,
      'mrp': mrp,
      'hsnCode': hsnCode,
      'taxRate': taxRate,
      'brand': brand,
      'manufacturer': manufacturer,
      'reorderLevel': reorderLevel,
      'unit': uom ?? 'Piece',
      'packagingUnit': packagingUnit,
      'conversionFactor': conversionFactor,
      'batchNumber': batchNumber,
      'serialNumber': serialNumber,
      'imei': imeiNumber,
      'warranty': warrantyPeriod,
      'expiryDate': expiryDate,
      'schedule': medicineSchedule,
      'recipe': recipeInstructions,
      'weight': weightVolume,
      'isbn': isbnNumber,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory GlobalProduct.fromMap(Map<String, dynamic> p) {
    return GlobalProduct(
      name: p['product_name'] ?? 'Unknown',
      category: p['category'] ?? '',
      typicalPrice: (p['selling_price'] as num?)?.toDouble() ?? 0.0,
      typicalCost: (p['cost_price'] as num?)?.toDouble() ?? 0.0,
      sku: p['barcode'] ?? '',
      brand: p['brand'],
      imageUrl: p['product_photo'],
      template: p['procurement_template'],
      isService: p['is_service'] == 1,
      isLoose: p['is_loose'] == 1,
      wholesalePrice: (p['wholesale_price'] as num?)?.toDouble(),
      mrp: (p['mrp'] as num?)?.toDouble(),
      hsnCode: p['hsn_code'],
      taxRate: (p['tax_percentage'] as num?)?.toDouble(), // Corrected from tax_rate
      manufacturer: p['manufacturer'],
      initialStock: (p['opening_stock'] as num?)?.toDouble(), // Corrected from initial_stock
      reorderLevel: (p['reorder_level'] as num?)?.toDouble(),
      uom: p['base_uom'], // Corrected from uom
      packagingUnit: p['packaging_uom'], // Corrected from packaging_unit
      conversionFactor: (p['conversion_factor'] as num?)?.toDouble(),
      batchNumber: p['batch_number'],
      serialNumber: p['serial_imei_number'], // Corrected from serial_number
      imeiNumber: p['serial_imei_number'], 
      warrantyPeriod: p['warranty_period'],
      expiryDate: p['expiry_date'],
      medicineSchedule: p['medicine_schedule'],
      recipeInstructions: p['recipe_instructions'],
      weightVolume: p['weight_volume'],
      isbnNumber: p['isbn_number'],
    );
  }

  factory GlobalProduct.fromLocalMap(Map<String, dynamic> map) {
    return GlobalProduct(
      name: map['name'] ?? 'Unknown',
      category: map['category'] ?? '',
      typicalPrice: (map['price'] as num?)?.toDouble() ?? 0.0,
      typicalCost: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
      sku: map['sku'] ?? '',
      brand: map['brand'],
      imageUrl: map['imageUrl'],
      template: map['template'],
      isService: map['isService'] == 1,
      isLoose: map['isLoose'] == 1,
      wholesalePrice: (map['wholesalePrice'] as num?)?.toDouble(),
      mrp: (map['mrp'] as num?)?.toDouble(),
      hsnCode: map['hsnCode'],
      taxRate: (map['taxRate'] as num?)?.toDouble(),
      manufacturer: map['manufacturer'],
    );
  }
}


class GlobalCatalogService {
  final DatabaseHelper _dbHelper;

  GlobalCatalogService(this._dbHelper);


  // Common Indian Barcodes (Legacy) - Keeping for backwards compatibility
  final Map<String, GlobalProduct> _legacyCatalog = {
    '8901058000000': GlobalProduct(name: 'Maggi 2-Minute Noodles (70g)', category: 'Groceries', typicalPrice: 14.0, typicalCost: 12.0, sku: '8901058000000', brand: 'Nestle'),
    '8901741715530': GlobalProduct(name: 'Parle-G Gold Biscuits (1kg)', category: 'Groceries', typicalPrice: 150.0, typicalCost: 135.0, sku: '8901741715530', brand: 'Parle'),
  };

  /// Search for a product by barcode/SKU
  /// Returns null if not found in any catalog
  Future<GlobalProduct?> searchBySKU(String sku, String? shopType) async {
    appLogger.debug('🔍 Searching catalog for SKU: $sku (ShopType: $shopType)');

    // 1. Check local lookup table (Already synced catalog)
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> localLookup = await db.query(
        TableConstants.globalCatalog,
        where: 'sku = ?',
        whereArgs: [sku],
        limit: 1,
      );

      if (localLookup.isNotEmpty) {
        // If found in lookup, it should be in the main products table too
        final List<Map<String, dynamic>> products = await db.query(
          TableConstants.products,
          where: 'sku = ?',
          whereArgs: [sku],
          limit: 1,
        );
        if (products.isNotEmpty) {
          appLogger.debug('✅ Found in local database: $sku');
          return GlobalProduct.fromLocalMap(products.first);
        }
      }
    } catch (e) {
      appLogger.debug('⚠️ Local DB lookup error: $e');
    }

    // 2. Check hardcoded high-density local catalog (Legacy/Bundled)
    if (kGlobalProductCatalog.containsKey(sku)) {
      appLogger.debug('✅ Found in bundled catalog: $sku');
      return kGlobalProductCatalog[sku];
    }

    // 3. Check legacy sample barcodes
    if (_legacyCatalog.containsKey(sku)) {
      appLogger.debug('✅ Found in legacy catalog: $sku');
      return _legacyCatalog[sku];
    }
    
    // 4. Fallback to Cloud Catalog (Cloudflare D1)
    return await fetchFromCloud(sku, shopType);
  }


  /// Fetches product details from the centralized cloud database
  Future<GlobalProduct?> fetchFromCloud(String sku, String? shopType) async {
    try {
      appLogger.debug('☁️ Fetching from Cloudflare D1: catalog/$sku?type=$shopType');
      
      final String apiType = (shopType ?? '').toLowerCase();
      final typeParam = apiType.isNotEmpty ? '&type=$apiType' : '';
      final uri = Uri.parse('https://catalog-api.gamingcristy19.workers.dev/catalog?sku=$sku$typeParam');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        List<dynamic> data = [];
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map) {
          if (decoded.containsKey('data')) {
            data = decoded['data'] ?? [];
          } else if (decoded.containsKey('results')) {
            data = decoded['results'] ?? [];
          }
        }
        
        if (data.isNotEmpty) {
          appLogger.debug('✅ Found in Cloudflare D1: $sku');
          return GlobalProduct.fromMap(data.first);
        }
      }

      appLogger.debug('❌ Not found in cloud: $sku');
      return null;
    } catch (e) {
      appLogger.debug('⚠️ Cloudflare Lookup Error: $e');
      return null;
    }
  }


  /// Downloads the full catalog for a specific shop type from Cloudflare API
  Future<List<Map<String, dynamic>>> downloadCatalogForShopType(String shopType) async {
    try {
      final apiType = shopType.toLowerCase();
      appLogger.debug('☁️ Downloading catalog for shopType: $apiType from Cloudflare D1');
      final uri = Uri.parse('https://catalog-api.gamingcristy19.workers.dev/catalog?type=$apiType&limit=5000&offset=0');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        } else if (decoded is Map) {
          if (decoded.containsKey('data')) {
            return List<Map<String, dynamic>>.from(decoded['data'] ?? []);
          } else if (decoded.containsKey('results')) {
            return List<Map<String, dynamic>>.from(decoded['results'] ?? []);
          }
        }
        return [];
      } else if (response.statusCode == 400) {
        appLogger.debug('⚠️ Catalog not available for $apiType (400): ${response.body}');
        return [];
      } else {
        appLogger.debug('⚠️ Cloudflare API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      appLogger.debug('⚠️ Cloudflare Fetch Error: $e');
      return [];
    }
  }
}