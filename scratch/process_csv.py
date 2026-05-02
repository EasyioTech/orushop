import csv

def process_csv(input_file, output_file):
    price_map = {
        'Budget': 149.0,
        'Mid-range': 899.0,
        'Premium': 2499.0
    }
    
    image_map = {
        'Personal Care': 'https://images.unsplash.com/photo-1556229010-6c3f2c9ca5f8?auto=format&fit=crop&q=80&w=400',
        'Sports & Fitness': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&q=80&w=400',
        'Electronics': 'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&q=80&w=400',
        'Clothing & Apparel': 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?auto=format&fit=crop&q=80&w=400',
        'Food & Grocery': 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=400',
        'Home & Kitchen': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&q=80&w=400',
        'Toys & Baby Products': 'https://images.unsplash.com/photo-1536640712247-c45474d66487?auto=format&fit=crop&q=80&w=400',
        'Books & Stationery': 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?auto=format&fit=crop&q=80&w=400',
        'Pet Supplies': 'https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?auto=format&fit=crop&q=80&w=400',
        'Automotive': 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?auto=format&fit=crop&q=80&w=400'
    }

    default_image = 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&q=80&w=400'

    catalog_items = []
    
    with open(input_file, mode='r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)
        
        for row in reader:
            if not row: continue
            
            sku = row[0]
            name = row[1]
            category = row[3]
            price_r = row[7]
            
            price = price_map.get(price_r, 149.0)
            cost = round(price * 0.85, 2) # Assume 15% margin
            image_url = image_map.get(category, default_image)
            
            # Clean name from (Hindi) if any or just take the English part
            # The CSV seems to have English name in product_name
            
            item = {
                "sku": sku,
                "name": name,
                "category": category,
                "price": price,
                "cost": cost,
                "imageUrl": image_url
            }
            catalog_items.append(item)

    with open(output_file, mode='w', encoding='utf-8') as f:
        f.write("final List<Map<String, dynamic>> catalogData = [\n")
        for i, item in enumerate(catalog_items):
            comma = "," if i < len(catalog_items) - 1 else ""
            # Escape quotes in names
            clean_name = item['name'].replace('"', '\\"')
            line = f'  {{"sku": "{item["sku"]}", "name": "{clean_name}", "category": "{item["category"]}", "price": {item["price"]}, "cost": {item["cost"]}, "imageUrl": "{item["imageUrl"]}"}}{comma}\n'
            f.write(line)
        f.write("];\n")

if __name__ == "__main__":
    process_csv('Indian Retail Product Categorization Dataset - Sheet1.csv', 'lib/core/database/catalog_data.dart')
