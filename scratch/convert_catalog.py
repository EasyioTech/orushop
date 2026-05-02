import csv
import json

category_images = {
    'Personal Care': 'https://images.unsplash.com/photo-1556229010-6c3f2c9ca5f8?auto=format&fit=crop&q=80&w=400',
    'Sports & Fitness': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&q=80&w=400',
    'Electronics': 'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&q=80&w=400',
    'Clothing & Apparel': 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?auto=format&fit=crop&q=80&w=400',
    'Food & Grocery': 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=400',
    'Home & Kitchen': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&q=80&w=400',
    'Toys & Baby Products': 'https://images.unsplash.com/photo-1536640712247-c45474d66487?auto=format&fit=crop&q=80&w=400',
    'Books & Stationery': 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?auto=format&fit=crop&q=80&w=400',
    'Home': 'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&q=80&w=400'
}

default_image = 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&q=80&w=400'

def convert():
    with open('f:/OruShops/retaildost/cleaned_catalog.csv', 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        products = []
        for row in reader:
            cat = row['category'].strip()
            products.append({
                'sku': row['sku'],
                'name': row['name'],
                'category': cat,
                'price': float(row['typical_price']),
                'cost': float(row['typical_cost']),
                'imageUrl': category_images.get(cat, default_image)
            })
    
    with open('f:/OruShops/retaildost/lib/core/database/catalog_data.dart', 'w', encoding='utf-8') as f:
        f.write('final List<Map<String, dynamic>> catalogData = [\n')
        for p in products:
            f.write(f"  {json.dumps(p)},\n")
        f.write('];\n')

if __name__ == '__main__':
    convert()
