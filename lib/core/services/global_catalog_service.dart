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
}

class GlobalCatalogService {
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
  };

  GlobalProduct? searchBySKU(String sku) {
    // 1. Check generated high-density catalog
    if (kGlobalProductCatalog.containsKey(sku)) {
      return kGlobalProductCatalog[sku];
    }
    
    // 2. Check legacy sample barcodes
    if (_legacyCatalog.containsKey(sku)) {
      return _legacyCatalog[sku];
    }
    
    // Fallback search logic for "Lot more" auto-population:
    // In a production app, this would call a Cloud Functions / Firestore / OpenFoodFacts API
    // return await _fetchFromCloudCatalog(sku);
    
    return null;
  }

  // Strategy for "Lot More" auto-population:
  // Use a public API like Open Food Facts or your own Cloud Database (Firebase)
  Future<GlobalProduct?> fetchFromCloud(String sku) async {
    // 1. First check local catalog (already done in searchBySKU)
    
    // 2. Mock Cloud/API Lookup (Concept)
    try {
      // In a real app:
      // final response = await http.get(Uri.parse('https://world.openfoodfacts.org/api/v0/product/$sku.json'));
      // if (response.statusCode == 200) { ... parse and return product ... }
      
      // For now, return null to show it's a fallback
      return null;
    } catch (e) {
      return null;
    }
  }
}
