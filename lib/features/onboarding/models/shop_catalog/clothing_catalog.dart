part of '../shop_catalog_data.dart';

final List<ShopCategory> _clothingCategories = [
      ShopCategory(
        name: "Men's Wear",
        subcategories: ['Shirts', 'T-Shirts', 'Trousers', 'Jeans', 'Kurta', 'Suit / Blazer',
          'Shorts', 'Ethnic Wear'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasSizeVariant: true, hasColorVariant: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Set'],
          defaultTaxRate: 5.0,
          sizeOptions: ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'],
          template: ProductTemplate.variantMatrix,
        ),
      ),
      ShopCategory(
        name: "Women's Wear",
        subcategories: ['Saree', 'Salwar Suit', 'Kurti', 'Lehenga', 'Western Tops',
          'Jeans & Trousers', 'Nightwear', 'Dupatta'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasSizeVariant: true, hasColorVariant: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Set', 'Metre'],
          defaultTaxRate: 5.0,
          sizeOptions: ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'Free Size'],
          template: ProductTemplate.variantMatrix,
        ),
      ),
      ShopCategory(
        name: "Kids' Wear",
        subcategories: ['Boys Clothing', 'Girls Clothing', 'Baby Clothes', 'School Uniform',
          'Winter Wear', 'Party Wear'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasSizeVariant: true, hasColorVariant: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Set'],
          defaultTaxRate: 5.0,
          sizeOptions: ['0-3m', '3-6m', '6-12m', '1Y', '2Y', '3Y', '4Y', '5Y', '6Y', '7Y',
            '8Y', '10Y', '12Y', '14Y'],
          template: ProductTemplate.variantMatrix,
        ),
      ),
      ShopCategory(
        name: 'Innerwear & Hosiery',
        subcategories: ['Briefs & Trunks', 'Bra & Lingerie', 'Vests', 'Socks', 'Leggings',
          'Thermal Wear'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasSizeVariant: true, hasColorVariant: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Pack'],
          defaultTaxRate: 5.0,
          sizeOptions: ['S', 'M', 'L', 'XL', 'XXL'],
          template: ProductTemplate.variantMatrix,
        ),
      ),
      ShopCategory(
        name: 'Winter & Seasonal',
        subcategories: ['Sweaters', 'Jackets', 'Hoodies', 'Shawls', 'Blankets', 'Caps & Gloves'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasSizeVariant: true, hasColorVariant: true,
          defaultUnit: 'Piece', unitOptions: ['Piece'],
          defaultTaxRate: 5.0,
          sizeOptions: ['S', 'M', 'L', 'XL', 'XXL', 'Free Size'],
          template: ProductTemplate.variantMatrix,
        ),
      ),
      ShopCategory(
        name: 'Footwear',
        subcategories: ['Slippers & Chappal', 'Sports Shoes', 'Formal Shoes', 'Sandals',
          'Boots', 'Kids Shoes'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasSizeVariant: true, hasColorVariant: true,
          defaultUnit: 'Pair', unitOptions: ['Pair'],
          defaultTaxRate: 18.0,
          sizeOptions: ['5', '6', '7', '8', '9', '10', '11', '12'],
          template: ProductTemplate.variantMatrix,
        ),
      ),
      ShopCategory(
        name: 'Accessories',
        subcategories: ['Belts', 'Wallets', 'Handbags', 'Sunglasses', 'Caps & Hats',
          'Scarves', 'Jewellery Accessories'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasColorVariant: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Set'],
          defaultTaxRate: 18.0,
        ),
      ),
];
