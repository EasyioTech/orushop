part of '../shop_catalog_data.dart';

final List<ShopCategory> _restaurantCategories = [
      ShopCategory(
        name: 'Main Course',
        subcategories: ['Roti & Naan', 'Rice Dishes', 'Curries (Veg)', 'Curries (Non-Veg)',
          'Biryani', 'Thali', 'Chinese Main'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasTaxRate: true, hasUnit: true, hasRecipe: true, hasWeight: true,
          defaultUnit: 'Plate', unitOptions: ['Plate', 'Half Plate', 'Bowl', 'Piece'],
          defaultTaxRate: 5.0,
          isService: true, template: ProductTemplate.serviceLabor,
        ),
      ),
      ShopCategory(
        name: 'Starters & Appetizers',
        subcategories: ['Tandoori', 'Tikka', 'Spring Rolls', 'Momos', 'Soup',
          'Salad', 'Pakora / Fritters'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasTaxRate: true, hasUnit: true, hasRecipe: true, hasWeight: true,
          defaultUnit: 'Plate', unitOptions: ['Plate', 'Half Plate', 'Piece'],
          defaultTaxRate: 5.0,
          isService: true, template: ProductTemplate.serviceLabor,
        ),
      ),
      ShopCategory(
        name: 'Breads',
        subcategories: ['Roti', 'Naan', 'Paratha', 'Puri', 'Kulcha', 'Laccha Paratha'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasTaxRate: true, hasUnit: true, hasRecipe: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Dozen', 'Half Dozen'],
          defaultTaxRate: 5.0,
          isService: true, template: ProductTemplate.serviceLabor,
        ),
      ),
      ShopCategory(
        name: 'Desserts & Sweets',
        subcategories: ['Gulab Jamun', 'Ice Cream', 'Halwa', 'Kheer', 'Brownie',
          'Cake Slice', 'Rasgulla'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasTaxRate: true, hasUnit: true, hasRecipe: true, hasWeight: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Bowl', 'Plate', 'Scoop'],
          defaultTaxRate: 5.0,
          isService: true, template: ProductTemplate.serviceLabor,
        ),
      ),
      ShopCategory(
        name: 'Beverages',
        subcategories: ['Cold Drinks', 'Juices', 'Lassi', 'Tea / Coffee',
          'Mocktails', 'Water', 'Shakes'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasTaxRate: true, hasUnit: true, hasRecipe: true,
          defaultUnit: 'Glass', unitOptions: ['Glass', 'Bottle', 'Cup', 'ML'],
          defaultTaxRate: 5.0,
          isService: true, template: ProductTemplate.serviceLabor,
        ),
      ),
      ShopCategory(
        name: 'Snacks & Fast Food',
        subcategories: ['Burger', 'Pizza', 'Sandwiches', 'Wraps', 'Pav Bhaji',
          'Chole Bhature', 'Vada Pav'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasTaxRate: true, hasUnit: true, hasRecipe: true, hasWeight: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Plate'],
          defaultTaxRate: 5.0,
          isService: true, template: ProductTemplate.serviceLabor,
        ),
      ),
      ShopCategory(
        name: 'Raw Ingredients (Kitchen)',
        subcategories: ['Vegetables', 'Meat & Poultry', 'Fish & Seafood', 'Spices',
          'Dairy', 'Oil & Ghee', 'Flour & Grains'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasMrp: true, hasTaxRate: true, hasUnit: true,
          isLoose: true,
          defaultUnit: 'Kg', unitOptions: ['Kg', 'Gram', 'Litre', 'ML', 'Piece', 'Pack'],
          defaultTaxRate: 0.0,
          template: ProductTemplate.bulkUom,
        ),
      ),
];
