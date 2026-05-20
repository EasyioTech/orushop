part of '../shop_catalog_data.dart';

final List<ShopCategory> _otherCategories = [
      ShopCategory(
        name: 'General Products',
        subcategories: [],
        productFields: ProductFieldConfig(
          hasMrp: true, hasUnit: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Kg', 'Litre', 'Pack', 'Set'],
          defaultTaxRate: 18.0,
        ),
      ),
      ShopCategory(
        name: 'Services',
        subcategories: [],
        productFields: ProductFieldConfig.service(),
      ),
];
