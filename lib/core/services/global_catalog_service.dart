import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './catalog_data.dart';

final globalCatalogServiceProvider = Provider((ref) => GlobalCatalogService());

class GlobalProduct {
  final String name;
  final String category;
  final double typicalPrice;
  final double typicalCost;
  final String sku;
  final String? brand;
  final String? imageUrl;
  final String? imagePath;

  const GlobalProduct({
    required this.name,
    required this.category,
    required this.typicalPrice,
    required this.typicalCost,
    required this.sku,
    this.brand,
    this.imageUrl,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': typicalPrice,
      'sku': sku,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'quantity': 0, // Default for new products
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory GlobalProduct.fromFirestore(Map<String, dynamic> data, String id) {
    return GlobalProduct(
      name: data['name'] ?? 'Unknown Product',
      category: data['category'] ?? 'General',
      typicalPrice: (data['mrp'] ?? data['price'] ?? 0.0).toDouble(),
      typicalCost: (data['cost'] ?? 0.0).toDouble(),
      sku: id,
      brand: data['brand'],
      imageUrl: data['imageUrl'],
    );
  }
}

class GlobalCatalogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Common Indian Barcodes (Legacy)
  final Map<String, GlobalProduct> _legacyCatalog = {
    '8901058000000': GlobalProduct(name: 'Maggi 2-Minute Noodles (70g)', category: 'Groceries', typicalPrice: 14.0, typicalCost: 12.0, sku: '8901058000000', brand: 'Nestle'),
    '8901741715530': GlobalProduct(name: 'Parle-G Gold Biscuits (1kg)', category: 'Groceries', typicalPrice: 150.0, typicalCost: 135.0, sku: '8901741715530', brand: 'Parle'),
    '8901741000000': GlobalProduct(name: 'Parle-G Biscuits (Small)', category: 'Groceries', typicalPrice: 5.0, typicalCost: 4.5, sku: '8901741000000', brand: 'Parle'),
    '8904063223000': GlobalProduct(name: "Haldiram's Aloo Bhujia (200g)", category: 'Groceries', typicalPrice: 50.0, typicalCost: 42.0, sku: '8904063223000', brand: 'Haldirams'),
    '8901582206211': GlobalProduct(name: 'Tata Salt (1kg)', category: 'Groceries', typicalPrice: 28.0, typicalCost: 25.0, sku: '8901582206211', brand: 'Tata'),
    '8901058862024': GlobalProduct(name: 'Nescafe Classic (50g)', category: 'Groceries', typicalPrice: 185.0, typicalCost: 170.0, sku: '8901058862024', brand: 'Nestle'),
    '8901231000000': GlobalProduct(name: 'Amul Butter (100g)', category: 'Groceries', typicalPrice: 56.0, typicalCost: 52.0, sku: '8901231000000', brand: 'Amul'),
    '8901138101412': GlobalProduct(name: 'Dabur Honey (250g)', category: 'Groceries', typicalPrice: 120.0, typicalCost: 105.0, sku: '8901138101412', brand: 'Dabur'),
    '8901262010016': GlobalProduct(name: 'Aashirvaad Atta (5kg)', category: 'Groceries', typicalPrice: 280.0, typicalCost: 260.0, sku: '8901262010016', brand: 'ITC'),
    '8901030329579': GlobalProduct(name: 'Kissan Mango Blast (200ml)', category: 'Beverages', typicalPrice: 20.0, typicalCost: 17.0, sku: '8901030329579', brand: 'Kissan'),
  };

  /// Search for a product by barcode/SKU
  /// Returns null if not found in any catalog
  Future<GlobalProduct?> searchBySKU(String sku) async {
    debugPrint('🔍 Searching catalog for SKU: $sku');

    // 1. Check generated high-density local catalog (Offline first)
    if (kGlobalProductCatalog.containsKey(sku)) {
      debugPrint('✅ Found in local catalog: $sku');
      return kGlobalProductCatalog[sku];
    }

    // 2. Check legacy sample barcodes
    if (_legacyCatalog.containsKey(sku)) {
      debugPrint('✅ Found in legacy catalog: $sku');
      return _legacyCatalog[sku];
    }
    
    // 3. Fallback to Cloud Catalog (Firestore)
    return await fetchFromCloud(sku);
  }

  /// Fetches product details from the centralized cloud database
  Future<GlobalProduct?> fetchFromCloud(String sku) async {
    try {
      debugPrint('☁️ Fetching from Firestore: global_catalog/$sku');

      // Try document ID lookup first (Fastest)
      final doc = await _firestore.collection('global_catalog').doc(sku).get(
        const GetOptions(source: Source.serverAndCache),
      );

      if (doc.exists && doc.data() != null) {
        debugPrint('✅ Found in Firestore (Doc ID): $sku');
        return GlobalProduct.fromFirestore(doc.data()!, doc.id);
      }

      // Fallback: Search by 'barcode' field (More robust)
      debugPrint('🔦 Falling back to field search for: $sku');
      final query = await _firestore
          .collection('global_catalog')
          .where('barcode', isEqualTo: sku)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        debugPrint('✅ Found in Firestore (Field search): $sku');
        return GlobalProduct.fromFirestore(data, query.docs.first.id);
      }

      debugPrint('❌ Not found in cloud: $sku');
      return null;
    } catch (e) {
      debugPrint('⚠️ Firestore Lookup Error: $e');
      return null;
    }
  }
}
