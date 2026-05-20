part of '../shop_catalog_data.dart';

final List<ShopCategory> _mobileCategories = [
      ShopCategory(
        name: 'Mobile Phones',
        subcategories: ['Budget Phones (under 10k)', 'Mid-Range (10k-25k)',
          'Flagship (25k+)', 'Feature Phones', 'Refurbished Phones'],
        productFields: ProductFieldConfig(
          hasSerialNumber: true, hasImei: true, hasMrp: true, hasHsnCode: true,
          hasTaxRate: true, hasBrand: true, hasWarranty: true, hasSizeVariant: true,
          defaultUnit: 'Piece', unitOptions: ['Piece'],
          defaultTaxRate: 18.0,
          sizeOptions: ['64GB', '128GB', '256GB', '512GB', '1TB'],
          template: ProductTemplate.serialized,
        ),
      ),
      ShopCategory(
        name: 'Chargers & Power',
        subcategories: ['Original Chargers', 'Third-Party Chargers', 'Power Banks',
          'Wireless Chargers', 'Charging Cables', 'Multi-Port Adapters'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true, hasUnit: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Pack'],
          defaultTaxRate: 18.0,
        ),
      ),
      ShopCategory(
        name: 'Cases & Covers',
        subcategories: ['Back Covers', 'Flip Cases', 'Silicone Cases', 'Tempered Glass',
          'Screen Protectors', 'Camera Protectors'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasUnit: true, hasColorVariant: true, hasSizeVariant: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Pack'],
          defaultTaxRate: 18.0,
          template: ProductTemplate.variantMatrix,
        ),
      ),
      ShopCategory(
        name: 'Audio',
        subcategories: ['Earphones (Wired)', 'Earbuds (TWS)', 'Headphones', 'Speakers',
          'Neckbands'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true, hasUnit: true,
          defaultUnit: 'Piece', unitOptions: ['Piece'],
          defaultTaxRate: 18.0,
        ),
      ),
      ShopCategory(
        name: 'Smart Wearables',
        subcategories: ['Smartwatch', 'Fitness Band', 'Smart Ring', 'Smart Glasses'],
        productFields: ProductFieldConfig(
          hasSerialNumber: true, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasUnit: true, hasWarranty: true,
          defaultUnit: 'Piece', unitOptions: ['Piece'],
          defaultTaxRate: 18.0,
        ),
      ),
      ShopCategory(
        name: 'Storage & OTG',
        subcategories: ['Memory Cards', 'Pen Drives', 'OTG Adapters', 'Hard Disks',
          'SSDs'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true, hasUnit: true,
          hasSizeVariant: true,
          defaultUnit: 'Piece', unitOptions: ['Piece'],
          defaultTaxRate: 18.0,
          sizeOptions: ['8GB', '16GB', '32GB', '64GB', '128GB', '256GB', '512GB', '1TB'],
        ),
      ),
      ShopCategory(
        name: 'Repair Parts',
        subcategories: ['Screens / Display', 'Batteries', 'Back Panels', 'Charging Ports',
          'Cameras', 'Speakers', 'Motherboards'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true, hasUnit: true,
          hasSerialNumber: true,
          defaultUnit: 'Piece', unitOptions: ['Piece'],
          defaultTaxRate: 18.0,
          template: ProductTemplate.serialized,
        ),
      ),
      ShopCategory(
        name: 'Repair Services',
        subcategories: ['Screen Replacement', 'Battery Replacement', 'Software Repair',
          'Water Damage', 'Charging Port Fix', 'Speaker / Mic Fix', 'Data Recovery'],
        productFields: ProductFieldConfig(
          hasUnit: true,
          defaultUnit: 'Job', unitOptions: ['Job', 'Hour', 'Visit'],
          defaultTaxRate: 18.0,
          hasTaxRate: true,
          isService: true,
          template: ProductTemplate.serviceLabor,
        ),
      ),
];
