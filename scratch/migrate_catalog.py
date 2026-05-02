import csv
import json
import re

def clean_name(name):
    # Remove Hindi text in parentheses or after a dash
    # Example: "Himalaya Purifying Neem Face Wash (200ml)" -> keep
    # Example: "HP DeskJet 2331 All-in-One Inkjet Colour Printer, एचपी डेस्कजेट 2331..." -> remove after comma
    if ',' in name:
        name = name.split(',')[0]
    return name.strip()

def get_price(price_range, category):
    if price_range == 'Budget':
        return 149.0
    elif price_range == 'Mid-range':
        return 899.0
    elif price_range == 'Premium':
        if category == 'Electronics':
            return 45000.0
        return 2499.0
    return 99.0

def get_image_url(category, keywords):
    # Mapping categories to unsplash images
    mapping = {
        'Personal Care': 'https://images.unsplash.com/photo-1556229010-6c3f2c9ca5f8',
        'Sports & Fitness': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438',
        'Electronics': 'https://images.unsplash.com/photo-1498049794561-7780e7231661',
        'Clothing & Apparel': 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f',
        'Food & Grocery': 'https://images.unsplash.com/photo-1542838132-92c53300491e',
        'Home & Kitchen': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f',
        'Toys & Baby Products': 'https://images.unsplash.com/photo-1536640712247-c45474d66487',
        'Books & Stationery': 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6',
    }
    base = mapping.get(category, 'https://images.unsplash.com/photo-1523275335684-37898b6baf30')
    return f"{base}?auto=format&fit=crop&q=80&w=400"

catalog = []
with open('f:/OruShops/retaildost/Indian Retail Product Categorization Dataset - Sheet1.csv', mode='r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        name = clean_name(row['product_name'])
        cat = row['primary_category']
        price = get_price(row['price_range'], cat)
        cost = round(price * 0.85, 2)
        sku = row['product_id']
        img = get_image_url(cat, row['primary_keywords'])
        
        catalog.append({
            "sku": sku,
            "name": name,
            "category": cat,
            "price": price,
            "cost": cost,
            "imageUrl": img
        })

# Write to catalog_data.dart
with open('f:/OruShops/retaildost/lib/core/database/catalog_data.dart', 'w', encoding='utf-8') as f:
    f.write('final List<Map<String, dynamic>> catalogData = [\n')
    for item in catalog:
        f.write(f'  {json.dumps(item)},\n')
    f.write('];\n')

print(f"Generated {len(catalog)} products.")
