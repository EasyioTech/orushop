part of '../shop_catalog_data.dart';

final List<ShopCategory> _electronicsCategories = [
      ShopCategory(
        name: 'Television',
        subcategories: ['LED TV', 'OLED TV', 'Smart TV', 'HD TV', '4K TV'],
        productFields: ProductFieldConfig(
          hasSerialNumber: true, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasWarranty: true,
          defaultUnit: 'Piece', unitOptions: ['Piece'],
          defaultTaxRate: 18.0,
          template: ProductTemplate.serialized,
        ),
      ),
      ShopCategory(
        name: 'Refrigerators',
        subcategories: ['Single Door', 'Double Door', 'Side by Side', 'Mini Fridge',
          'Deep Freezer'],
        productFields: ProductFieldConfig(
          hasSerialNumber: true, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasWarranty: true,
          defaultUnit: 'Piece', unitOptions: ['Piece'],
          defaultTaxRate: 18.0,
          template: ProductTemplate.serialized,
        ),
      ),
      ShopCategory(
        name: 'Air Conditioners',
        subcategories: ['Split AC', 'Window AC', 'Portable AC', 'Cassette AC', 'Tower AC'],
        productFields: ProductFieldConfig(
          hasSerialNumber: true, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasWarranty: true, hasSizeVariant: true,
          defaultUnit: 'Piece', unitOptions: ['Piece'],
          defaultTaxRate: 28.0,
          template: ProductTemplate.serialized,
        ),
      ),
      ShopCategory(
        name: 'Washing Machines',
        subcategories: ['Front Load', 'Top Load', 'Semi Automatic', 'Fully Automatic'],
        productFields: ProductFieldConfig(
          hasSerialNumber: true, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasWarranty: true,
          defaultUnit: 'Piece', unitOptions: ['Piece'],
          defaultTaxRate: 18.0,
          template: ProductTemplate.serialized,
        ),
      ),
      ShopCategory(
        name: 'Kitchen Appliances',
        subcategories: ['Mixer Grinder', 'Microwave', 'Induction Cooktop', 'Water Purifier',
          'Juicer', 'Electric Kettle', 'Toaster', 'OTG'],
        productFields: ProductFieldConfig(
          hasSerialNumber: true, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasWarranty: true,
          defaultUnit: 'Piece', unitOptions: ['Piece'],
          defaultTaxRate: 18.0,
          template: ProductTemplate.serialized,
        ),
      ),
      ShopCategory(
        name: 'Laptops & Computers',
        subcategories: ['Laptops', 'Desktops', 'Monitors', 'Keyboards', 'Mouse', 'Printers'],
        productFields: ProductFieldConfig(
          hasSerialNumber: true, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasWarranty: true,
          defaultUnit: 'Piece', unitOptions: ['Piece'],
          defaultTaxRate: 18.0,
          template: ProductTemplate.serialized,
        ),
      ),
      ShopCategory(
        name: 'Fans & Cooling',
        subcategories: ['Ceiling Fan', 'Table Fan', 'Exhaust Fan', 'Air Cooler', 'Pedestal Fan'],
        productFields: ProductFieldConfig(
          hasSerialNumber: false, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasWarranty: true,
          defaultUnit: 'Piece', unitOptions: ['Piece'],
          defaultTaxRate: 18.0,
        ),
      ),
      ShopCategory(
        name: 'Accessories & Cables',
        subcategories: ['HDMI Cables', 'USB Cables', 'Extension Cords', 'Power Strips',
          'Remote Controls', 'Batteries'],
        productFields: ProductFieldConfig(
          hasSerialNumber: false, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Pack'],
          defaultTaxRate: 18.0,
        ),
      ),
];
