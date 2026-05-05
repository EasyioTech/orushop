import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import json
import os

# 1. DOWNLOAD your Service Account Key from Firebase Console
# Settings -> Service Accounts -> Generate New Private Key
# Save it as 'serviceAccountKey.json' in this folder
SERVICE_ACCOUNT_PATH = r'f:\OruShops\retaildost\scratch\orushops-110-firebase-adminsdk-fbsvc-bd746a788e.json'
JSON_DATA_PATH = r'f:\OruShops\retaildost\data\global_catalog.json'

def upload_to_firestore():
    if not os.path.exists(SERVICE_ACCOUNT_PATH):
        print(f"Error: {SERVICE_ACCOUNT_PATH} not found. Please download it from Firebase Console.")
        return

    # Initialize Firebase
    cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    # Load Data
    with open(JSON_DATA_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"Starting upload of {len(data)} products...")
    
    batch = db.batch()
    count = 0
    total = 0
    
    for barcode, product in data.items():
        doc_ref = db.collection('global_catalog').document(barcode)
        batch.set(doc_ref, product)
        
        count += 1
        total += 1
        
        # Firestore batch limit is 500
        if count >= 500:
            batch.commit()
            print(f"Uploaded {total} items...")
            batch = db.batch()
            count = 0
            
    # Final commit
    if count > 0:
        batch.commit()
        
    print(f"Success! Total {total} products uploaded to Firestore collection 'global_catalog'.")

if __name__ == "__main__":
    upload_to_firestore()
