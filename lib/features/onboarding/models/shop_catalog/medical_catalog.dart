part of '../shop_catalog_data.dart';

final List<ShopCategory> _medicalCategories = [
      ShopCategory(
        name: 'Tablets & Capsules',
        subcategories: ['Antibiotics', 'Analgesics', 'Antacids', 'Vitamins & Supplements',
          'Antidiabetics', 'Antihypertensives', 'Antiallergics', 'Multivitamins'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasBatchNumber: true, hasMrp: true,
          hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasManufacturer: true, hasSchedule: true, hasUnit: true,
          hasPackagingUnit: true, hasReorderLevel: true,
          isLoose: true,
          defaultUnit: 'Strip', unitOptions: ['Strip', 'Box', 'Bottle', 'Piece'],
          defaultTaxRate: 12.0,
          template: ProductTemplate.batchMultiUom,
        ),
      ),
      ShopCategory(
        name: 'Syrups & Liquids',
        subcategories: ['Cough Syrups', 'Antacid Suspensions', 'Vitamin Syrups', 'Tonics'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasBatchNumber: true, hasMrp: true,
          hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasManufacturer: true, hasSchedule: true, hasUnit: true,
          hasPackagingUnit: true, hasReorderLevel: true,
          isLoose: true,
          defaultUnit: 'Bottle', unitOptions: ['Bottle', 'Sachet'],
          defaultTaxRate: 12.0,
          template: ProductTemplate.batchMultiUom,
        ),
      ),
      ShopCategory(
        name: 'Injections & IV',
        subcategories: ['Ampoules', 'Vials', 'IV Fluids', 'Pre-filled Syringes'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasBatchNumber: true, hasMrp: true,
          hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasManufacturer: true, hasSchedule: true, hasUnit: true,
          defaultUnit: 'Vial', unitOptions: ['Vial', 'Ampoule', 'Pack'],
          defaultTaxRate: 12.0,
          template: ProductTemplate.batchExpiry,
        ),
      ),
      ShopCategory(
        name: 'Surgical & Disposables',
        subcategories: ['Syringes', 'Gloves', 'Bandages', 'Cotton', 'Masks', 'Catheters'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasBatchNumber: false, hasMrp: true,
          hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasManufacturer: false, hasUnit: true,
          isLoose: true,
          defaultUnit: 'Box', unitOptions: ['Box', 'Pack', 'Piece', 'Gram', 'Metre'],
          defaultTaxRate: 5.0,
          template: ProductTemplate.batchExpiry,
        ),
      ),
      ShopCategory(
        name: 'Baby & Infant Care',
        subcategories: ['Baby Food', 'Diapers', 'Baby Wipes', 'Baby Powder', 'Feeding Bottles'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasBatchNumber: false, hasMrp: true,
          hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Pack', 'Box'],
          defaultTaxRate: 0.0,
          template: ProductTemplate.batchExpiry,
        ),
      ),
      ShopCategory(
        name: 'OTC Health Products',
        subcategories: ['Thermometers', 'BP Monitors', 'Glucometers', 'Pulse Oximeters',
          'Heating Pads', 'First Aid Kits'],
        productFields: ProductFieldConfig(
          hasExpiryDate: false, hasBatchNumber: false, hasMrp: true,
          hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasSerialNumber: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Kit'],
          defaultTaxRate: 18.0,
          template: ProductTemplate.serialized,
        ),
      ),
      ShopCategory(
        name: 'Herbal & Ayurvedic',
        subcategories: ['Chyawanprash', 'Ashwagandha', 'Triphala', 'Herbal Juices', 'Oils'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasBatchNumber: false, hasMrp: true,
          hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          isLoose: true,
          defaultUnit: 'Bottle', unitOptions: ['Bottle', 'Pack', 'Box', 'Gram', 'ML'],
          defaultTaxRate: 0.0,
          template: ProductTemplate.batchExpiry,
        ),
      ),
];
