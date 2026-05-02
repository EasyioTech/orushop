import csv

# Category to Unsplash Image Mapping
category_images = {
    'Food & Grocery': 'https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=800',
    'Electronics': 'https://images.unsplash.com/photo-1498049794561-7780e7231661?q=80&w=800',
    'Personal Care': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?q=80&w=800',
    'Home & Kitchen': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?q=80&w=800',
    'Clothing & Apparel': 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?q=80&w=800',
    'Sports & Fitness': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=800',
    'Books & Stationery': 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?q=80&w=800',
    'Toys & Baby Products': 'https://images.unsplash.com/photo-1532330393533-443990a51d10?q=80&w=800',
    'Other': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?q=80&w=800'
}

def generate_dart(csv_file, output_file):
    with open(csv_file, mode='r', encoding='utf-8') as infile:
        reader = csv.DictReader(infile)
        
        lines = [
            "// AUTO-GENERATED CATALOG DATA. DO NOT EDIT MANUALLY.",
            "import '../models/product.dart';",
            "import './global_catalog_service.dart';",
            "",
            "const Map<String, GlobalProduct> kGlobalProductCatalog = {"
        ]
        
        for row in reader:
            sku = row['sku']
            name = row['name'].replace('"', '\\"')
            category = row['category']
            price = row['typical_price']
            cost = row['typical_cost']
            
            # Map category for image
            image_url = category_images.get(category, category_images['Other'])
            
            # Clean category to match app categories if needed
            # For now keep as is
            
            line = f"  '{sku}': GlobalProduct(name: \"{name}\", category: \"{category}\", typicalPrice: {price}, typicalCost: {cost}, sku: \"{sku}\", imageUrl: \"{image_url}\"),"
            lines.append(line)
            
        lines.append("};")
        
        with open(output_file, mode='w', encoding='utf-8') as outfile:
            outfile.write('\n'.join(lines))

if __name__ == "__main__":
    generate_dart('f:/OruShops/retaildost/cleaned_catalog.csv', 
                  'f:/OruShops/retaildost/lib/core/services/catalog_data.dart')
