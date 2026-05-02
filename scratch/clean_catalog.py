import csv

def clean_csv(input_file, output_file):
    with open(input_file, mode='r', encoding='utf-8') as infile:
        reader = csv.DictReader(infile)
        
        # Define fields we want to keep
        # sku, name, category, typical_price, typical_cost
        fieldnames = ['sku', 'name', 'category', 'typical_price', 'typical_cost']
        
        with open(output_file, mode='w', encoding='utf-8', newline='') as outfile:
            writer = csv.DictWriter(outfile, fieldnames=fieldnames)
            writer.writeheader()
            
            for row in reader:
                # Map price range to a typical price
                price_range = row['price_range'].lower()
                category = row['primary_category']
                
                # Default prices
                price = 100.0
                if 'electronics' in category.lower():
                    if 'premium' in price_range: price = 45000.0
                    elif 'mid-range' in price_range: price = 15000.0
                    else: price = 2000.0
                elif 'clothing' in category.lower() or 'sports' in category.lower():
                    if 'premium' in price_range: price = 2499.0
                    elif 'mid-range' in price_range: price = 999.0
                    else: price = 399.0
                else:
                    if 'premium' in price_range: price = 500.0
                    elif 'mid-range' in price_range: price = 250.0
                    else: price = 40.0
                
                cost = round(price * 0.85, 2)
                
                writer.writerow({
                    'sku': row['product_id'],
                    'name': row['product_name'],
                    'category': category,
                    'typical_price': price,
                    'typical_cost': cost
                })

if __name__ == "__main__":
    clean_csv('f:/OruShops/retaildost/Indian Retail Product Categorization Dataset - Sheet1.csv', 
              'f:/OruShops/retaildost/cleaned_catalog.csv')
