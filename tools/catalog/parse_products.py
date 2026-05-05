import pandas as pd
import json
import os

def parse_excel_to_json(input_path, output_path):
    print(f"Reading {input_path}...")
    df = pd.read_excel(input_path, header=None)
    
    products = {}
    current_category = 'General'
    
    # Skip the header row (index 0)
    for idx, row in df.iterrows():
        if idx == 0: continue
        
        sku = str(row[0]).strip() if pd.notna(row[0]) else None
        name = str(row[1]).strip() if pd.notna(row[1]) else None
        barcode = str(row[4]).strip() if pd.notna(row[4]) else None
        mrp = float(row[7]) if pd.notna(row[7]) and isinstance(row[7], (int, float)) else 0.0
        
        # Category row detection
        # Logic: Name is empty and SKU has '-' (like '33 - Bakery')
        if (not name or name.lower() == 'nan') and sku and '-' in sku:
            current_category = sku
            # print(f"Switched to category: {current_category}")
            continue
            
        # Valid product detection
        # Must have a name and a barcode (EAN Code)
        if name and name.lower() != 'nan' and barcode and barcode.lower() != 'nan' and len(barcode) > 5:
            # Clean barcode (remove .0 if interpreted as float)
            clean_barcode = barcode.split('.')[0]
            
            # Store by barcode for easy lookup
            products[clean_barcode] = {
                'barcode': clean_barcode,
                'name': name,
                'sku': sku if sku and sku.lower() != 'nan' else clean_barcode,
                'mrp': mrp,
                'cost': mrp * 0.85, # Estimate 15% margin if cost missing
                'category': current_category,
                'brand': current_category.split('-')[-1].strip() if '-' in current_category else 'Generic'
            }

    print(f"Total valid products found: {len(products)}")
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(products, f, indent=2)
    
    print(f"Saved to {output_path}")

if __name__ == "__main__":
    base_dir = r"f:\OruShops\retaildost"
    input_file = os.path.join(base_dir, "data", "125065902-Price-List.xlsx")
    output_file = os.path.join(base_dir, "data", "global_catalog.json")
    
    if os.path.exists(input_file):
        parse_excel_to_json(input_file, output_file)
    else:
        print(f"Error: {input_file} not found")
