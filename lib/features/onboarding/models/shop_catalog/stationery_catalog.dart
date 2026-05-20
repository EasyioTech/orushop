part of '../shop_catalog_data.dart';

final List<ShopCategory> _stationeryCategories = [
      ShopCategory(
        name: 'Notebooks & Diaries',
        subcategories: ['Single Line', 'Double Line', 'Square / Graph', 'Spiral', 'Hardcover',
          'Long Book', 'Register', 'Short Book'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasUnit: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Pack', 'Dozen'],
          defaultTaxRate: 12.0,
        ),
      ),
      ShopCategory(
        name: 'Pens & Pencils',
        subcategories: ['Ball Pens', 'Gel Pens', 'Sketch Pens', 'Pencils', 'Mechanical Pencils',
          'Highlighters', 'Markers', 'Ink Pens'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasUnit: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Pack', 'Box', 'Dozen'],
          defaultTaxRate: 18.0,
        ),
      ),
      ShopCategory(
        name: 'Books',
        subcategories: ['School Textbooks', 'Competitive Exam Books', 'Children Books',
          'Fiction / Novels', 'Reference Books', 'Dictionaries'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasIsbn: true,
          defaultUnit: 'Piece', unitOptions: ['Piece'],
          defaultTaxRate: 0.0,
        ),
      ),
      ShopCategory(
        name: 'Paper Products',
        subcategories: ['A4 Paper Ream', 'Drawing Sheet', 'Tissue Paper', 'Envelope',
          'Ruled Paper', 'Carbon Paper', 'Tracing Paper'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasUnit: true,
          defaultUnit: 'Pack', unitOptions: ['Pack', 'Ream', 'Piece', 'Dozen'],
          defaultTaxRate: 18.0,
        ),
      ),
      ShopCategory(
        name: 'Art & Craft Supplies',
        subcategories: ['Colour Pencils', 'Watercolours', 'Acrylic Colours', 'Clay',
          'Brushes', 'Canvas', 'Scissors', 'Craft Paper'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasUnit: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Set', 'Box', 'Pack'],
          defaultTaxRate: 12.0,
        ),
      ),
      ShopCategory(
        name: 'Office Supplies',
        subcategories: ['Stapler', 'Staple Pins', 'Punch Machine', 'Tape & Dispenser',
          'Files & Folders', 'Rubber Bands', 'Whitener', 'Glue Stick'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasUnit: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Pack', 'Box'],
          defaultTaxRate: 18.0,
        ),
      ),
      ShopCategory(
        name: 'Instruments & Geometry',
        subcategories: ['Compass', 'Protractor', 'Scale / Ruler', 'Set Squares',
          'Calculator', 'Geometry Box'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasUnit: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Set'],
          defaultTaxRate: 18.0,
        ),
      ),
];
