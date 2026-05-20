part of '../shop_catalog_data.dart';

final List<ShopCategory> _bakeryCategories = [
      ShopCategory(
        name: 'Breads',
        subcategories: ['White Bread', 'Brown Bread', 'Multigrain Bread', 'Pav', 'Bun',
          'Sandwich Bread', 'Garlic Bread'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasMrp: true, hasTaxRate: true, hasBrand: true,
          hasUnit: true, hasRecipe: true,
          hasPackagingUnit: true, hasReorderLevel: true,
          isLoose: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Loaf', 'Pack', 'Dozen'],
          defaultTaxRate: 5.0,
          template: ProductTemplate.batchMultiUom,
        ),
      ),
      ShopCategory(
        name: 'Cakes & Pastries',
        subcategories: ['Whole Cakes', 'Pastry Slices', 'Cupcakes', 'Cheesecake',
          'Black Forest', 'Chocolate Cake', 'Fruit Cake'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasMrp: true, hasTaxRate: true,
          hasUnit: true, hasWeight: true, hasRecipe: true,
          isLoose: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Kg', 'Slice', 'Gram'],
          defaultTaxRate: 18.0,
          template: ProductTemplate.bulkUom,
        ),
      ),
      ShopCategory(
        name: 'Biscuits & Cookies',
        subcategories: ['Cream Biscuits', 'Digestive', 'Cookies', 'Rusk', 'Crackers',
          'Butter Cookies'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasMrp: true, hasTaxRate: true, hasBrand: true,
          hasUnit: true, hasWeight: true,
          isLoose: true,
          defaultUnit: 'Pack', unitOptions: ['Pack', 'Gram', 'Kg', 'Piece'],
          defaultTaxRate: 18.0,
          template: ProductTemplate.bulkUom,
        ),
      ),
      ShopCategory(
        name: 'Sweets & Mithai',
        subcategories: ['Ladoo', 'Barfi', 'Halwa', 'Gulab Jamun', 'Rasgulla',
          'Kaju Katli', 'Peda'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasMrp: true, hasTaxRate: true,
          hasUnit: true, hasWeight: true, hasRecipe: true,
          defaultUnit: 'Kg', unitOptions: ['Kg', 'Gram', 'Piece', 'Box'],
          defaultTaxRate: 5.0,
          isLoose: true, template: ProductTemplate.bulkUom,
        ),
      ),
      ShopCategory(
        name: 'Snacks & Savories',
        subcategories: ['Samosa', 'Kachori', 'Vada', 'Bread Roll', 'Pizza', 'Sandwich'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasMrp: true, hasTaxRate: true,
          hasUnit: true, hasRecipe: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Dozen', 'Kg'],
          defaultTaxRate: 5.0,
          isService: true, template: ProductTemplate.serviceLabor,
        ),
      ),
      ShopCategory(
        name: 'Beverages & Ice Cream',
        subcategories: ['Cold Coffee', 'Milkshake', 'Fresh Juice', 'Ice Cream Cup',
          'Ice Cream Cone', 'Kulfi'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasMrp: true, hasTaxRate: true,
          hasUnit: true, hasRecipe: true,
          isService: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Cup', 'ML', 'Litre', 'Glass'],
          defaultTaxRate: 18.0,
          template: ProductTemplate.serviceLabor,
        ),
      ),
      ShopCategory(
        name: 'Raw Ingredients',
        subcategories: ['Maida', 'Sugar', 'Butter / Margarine', 'Yeast', 'Baking Powder',
          'Chocolate / Cocoa', 'Flavours & Essences', 'Food Colour'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasMrp: true, hasTaxRate: true, hasBrand: true,
          hasUnit: true, hasWeight: true,
          defaultUnit: 'Kg', unitOptions: ['Kg', 'Gram', 'Litre', 'ML', 'Piece'],
          defaultTaxRate: 5.0,
          isLoose: true, template: ProductTemplate.bulkUom,
        ),
      ),
];
