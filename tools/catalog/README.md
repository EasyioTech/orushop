# OruShops Catalog Management Tools

This directory contains tools to update the global product barcode catalog.

## How to update the catalog

1.  **Prepare the Excel file**: Place your latest product list (Excel format) in the `f:\OruShops\retaildost\data` directory.
2.  **Parse the data**: Run the parsing script to generate a clean JSON file.
    ```bash
    python tools/catalog/parse_products.py
    ```
    This will update `f:\OruShops\retaildost\data\global_catalog.json`.
3.  **Upload to Firestore**: 
    *   Ensure your Firebase Service Account JSON is in `f:\OruShops\retaildost\scratch\`.
    *   Update the `SERVICE_ACCOUNT_PATH` in `tools/catalog/upload_to_firestore.py` if the filename changed.
    *   Run the upload script:
    ```bash
    python tools/catalog/upload_to_firestore.py
    ```

## Requirements
- `pandas`
- `openpyxl`
- `firebase-admin`
