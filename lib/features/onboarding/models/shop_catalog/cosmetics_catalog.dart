part of '../shop_catalog_data.dart';

final List<ShopCategory> _cosmeticsCategories = [
      ShopCategory(
        name: 'Skincare',
        subcategories: ['Face Wash', 'Moisturiser', 'Sunscreen', 'Serum', 'Toner',
          'Face Mask', 'Eye Cream', 'Night Cream'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasUnit: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'ML', 'Gram'],
          defaultTaxRate: 18.0,
        ),
      ),
      ShopCategory(
        name: 'Makeup',
        subcategories: ['Foundation', 'Lipstick', 'Eyeliner', 'Mascara', 'Blush',
          'Eyeshadow Palette', 'Compact Powder', 'Kajal', 'Nail Polish'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasUnit: true, hasColorVariant: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'ML', 'Gram'],
          defaultTaxRate: 28.0,
        ),
      ),
      ShopCategory(
        name: 'Hair Care',
        subcategories: ['Shampoo', 'Conditioner', 'Hair Oil', 'Hair Colour', 'Hair Serum',
          'Hair Mask', 'Dry Shampoo', 'Hair Spray'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasUnit: true, hasColorVariant: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'ML', 'Gram'],
          defaultTaxRate: 18.0,
        ),
      ),
      ShopCategory(
        name: 'Fragrances & Perfumes',
        subcategories: ['Perfumes', 'Deodorants', 'Body Mist', 'Attar / Oud',
          'Room Freshener'],
        productFields: ProductFieldConfig(
          hasExpiryDate: false, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasUnit: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'ML'],
          defaultTaxRate: 28.0,
        ),
      ),
      ShopCategory(
        name: 'Bath & Body',
        subcategories: ['Soaps', 'Body Wash', 'Body Lotion', 'Scrubs', 'Talcum Powder',
          'Lip Balm', 'Hand Sanitiser'],
        productFields: ProductFieldConfig(
          hasExpiryDate: false, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasUnit: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'ML', 'Gram'],
          defaultTaxRate: 18.0,
        ),
      ),
      ShopCategory(
        name: 'Nail & Tools',
        subcategories: ['Nail Polish', 'Nail Polish Remover', 'Nail Cutters', 'Tweezers',
          'Eyelash Curlers', 'Makeup Brushes', 'Beauty Blenders'],
        productFields: ProductFieldConfig(
          hasExpiryDate: false, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasUnit: true, hasColorVariant: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Set', 'Pack'],
          defaultTaxRate: 18.0,
        ),
      ),
      ShopCategory(
        name: 'Men Grooming',
        subcategories: ['Shaving Cream', 'Aftershave', 'Beard Oil', 'Razor',
          'Trimmer', "Men's Face Wash", "Men's Moisturiser"],
        productFields: ProductFieldConfig(
          hasExpiryDate: false, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasUnit: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'ML', 'Gram'],
          defaultTaxRate: 18.0,
        ),
      ),
];
