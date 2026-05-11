import 'shop_models.dart';

/// Full catalog: categories → subcategories → suggested product fields
/// Covers the most common Indian retail store types.

class ShopCatalog {
  static Map<ShopType, List<ShopCategory>> get catalog => _catalog;

  static List<ShopCategory> forType(ShopType type) =>
      _catalog[type] ?? _catalog[ShopType.other]!;

  /// Returns flat list of category names (for backward compat with categories screen)
  static List<String> categoryNamesFor(ShopType type) =>
      forType(type).map((c) => c.name).toList();

  static final Map<ShopType, List<ShopCategory>> _catalog = {
    // ───────────────────────── MEDICAL / PHARMACY ─────────────────────────
    ShopType.medical: [
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
    ],

    // ───────────────────────── GROCERY / KIRANA ───────────────────────────
    ShopType.grocery: [
      ShopCategory(
        name: 'Atta, Rice & Grains',
        subcategories: ['Wheat Atta', 'Rice', 'Maida', 'Besan', 'Semolina / Suji',
          'Multigrain Atta', 'Bajra / Jowar', 'Oats'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasUnit: true,
          defaultUnit: 'Kg', unitOptions: ['Kg', 'Gram', 'Pack', 'Bag'],
          defaultTaxRate: 0.0,
          isLoose: true, template: ProductTemplate.bulkUom,
        ),
      ),
      ShopCategory(
        name: 'Dal & Pulses',
        subcategories: ['Toor Dal', 'Moong Dal', 'Chana Dal', 'Masoor Dal', 'Urad Dal',
          'Rajma', 'Chole / Chickpeas', 'Lobia'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasUnit: true,
          defaultUnit: 'Kg', unitOptions: ['Kg', 'Gram', 'Pack'],
          defaultTaxRate: 0.0,
          isLoose: true, template: ProductTemplate.bulkUom,
        ),
      ),
      ShopCategory(
        name: 'Oil & Ghee',
        subcategories: ['Mustard Oil', 'Refined Oil', 'Groundnut Oil', 'Coconut Oil',
          'Sunflower Oil', 'Ghee', 'Vanaspati', 'Olive Oil'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasUnit: true,
          defaultUnit: 'Litre', unitOptions: ['Litre', 'ML', 'Kg', 'Tin'],
          defaultTaxRate: 5.0,
          isLoose: true, template: ProductTemplate.bulkUom,
        ),
      ),
      ShopCategory(
        name: 'Spices & Masala',
        subcategories: ['Haldi', 'Red Chilli Powder', 'Coriander Powder', 'Jeera',
          'Garam Masala', 'Kitchen King', 'Sambhar Masala', 'Salt'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasUnit: true,
          defaultUnit: 'Gram', unitOptions: ['Gram', 'Kg', 'Pack'],
          defaultTaxRate: 5.0,
          isLoose: true, template: ProductTemplate.bulkUom,
        ),
      ),
      ShopCategory(
        name: 'Dairy & Eggs',
        subcategories: ['Milk', 'Paneer', 'Curd / Dahi', 'Butter', 'Cheese', 'Eggs',
          'Cream', 'Condensed Milk'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasUnit: true,
          isLoose: true,
          defaultUnit: 'Litre', unitOptions: ['Litre', 'ML', 'Kg', 'Gram', 'Dozen', 'Piece'],
          defaultTaxRate: 0.0,
          template: ProductTemplate.bulkUom,
        ),
      ),
      ShopCategory(
        name: 'Snacks & Namkeen',
        subcategories: ['Chips', 'Namkeen', 'Biscuits', 'Papad', 'Murmura', 'Popcorn',
          'Dry Fruits', 'Nuts'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasUnit: true,
          isLoose: true,
          defaultUnit: 'Gram', unitOptions: ['Gram', 'Kg', 'Pack', 'Piece'],
          defaultTaxRate: 18.0,
          template: ProductTemplate.bulkUom,
        ),
      ),
      ShopCategory(
        name: 'Beverages',
        subcategories: ['Tea', 'Coffee', 'Cold Drinks', 'Juices', 'Energy Drinks',
          'Water Bottles', 'Health Drinks', 'Instant Mixes'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasUnit: true,
          isLoose: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Litre', 'ML', 'Gram', 'Kg', 'Pack'],
          defaultTaxRate: 18.0,
          template: ProductTemplate.bulkUom,
        ),
      ),
      ShopCategory(
        name: 'Packaged & Instant Food',
        subcategories: ['Instant Noodles', 'Ready Meals', 'Sauces & Ketchup', 'Pickle',
          'Jam & Spreads', 'Pasta & Macaroni', 'Canned Food'],
        productFields: ProductFieldConfig(
          hasExpiryDate: true, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasUnit: true,
          defaultUnit: 'Pack', unitOptions: ['Pack', 'Gram', 'Piece', 'Bottle'],
          defaultTaxRate: 18.0,
          template: ProductTemplate.batchExpiry,
        ),
      ),
      ShopCategory(
        name: 'Home & Cleaning',
        subcategories: ['Detergent', 'Dish Wash', 'Floor Cleaner', 'Toilet Cleaner',
          'Phenyl', 'Air Freshener', 'Mosquito Repellent', 'Broom & Mops'],
        productFields: ProductFieldConfig(
          hasExpiryDate: false, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasUnit: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Litre', 'ML', 'Gram', 'Kg', 'Pack'],
          defaultTaxRate: 18.0,
        ),
      ),
      ShopCategory(
        name: 'Personal Care',
        subcategories: ['Soap', 'Shampoo', 'Toothpaste', 'Toothbrush', 'Razor',
          'Sanitary Napkins', 'Deodorant', 'Face Wash'],
        productFields: ProductFieldConfig(
          hasExpiryDate: false, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasUnit: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Gram', 'ML', 'Pack'],
          defaultTaxRate: 18.0,
        ),
      ),
    ],

    // ────────────────────── ELECTRONICS & APPLIANCES ──────────────────────
    ShopType.electronics: [
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
    ],

    // ────────────────────── CLOTHING & APPAREL ─────────────────────────
    ShopType.clothing: [
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
    ],

    // ────────────────────── BAKERY & CONFECTIONERY ─────────────────────────
    ShopType.bakery: [
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
    ],

    // ────────────────────── STATIONERY & BOOKS ─────────────────────────
    ShopType.stationery: [
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
    ],

    // ────────────────────── HARDWARE & TOOLS ─────────────────────────
    ShopType.hardware: [
      ShopCategory(
        name: 'Hand Tools',
        subcategories: ['Hammer', 'Screwdriver Set', 'Pliers', 'Wrench', 'Chisel',
          'Hand Saw', 'File & Rasp', 'Tape Measure'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasUnit: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Set'],
          defaultTaxRate: 18.0,
        ),
      ),
      ShopCategory(
        name: 'Power Tools',
        subcategories: ['Drill Machine', 'Angle Grinder', 'Jigsaw', 'Circular Saw',
          'Sander', 'Heat Gun', 'Electric Screwdriver'],
        productFields: ProductFieldConfig(
          hasSerialNumber: true, hasMrp: true, hasHsnCode: true, hasTaxRate: true,
          hasBrand: true, hasWarranty: true, hasUnit: true,
          defaultUnit: 'Piece', unitOptions: ['Piece'],
          defaultTaxRate: 18.0,
          template: ProductTemplate.serialized,
        ),
      ),
      ShopCategory(
        name: 'Fasteners',
        subcategories: ['Nails', 'Screws', 'Bolts & Nuts', 'Anchors', 'Rivets',
          'Wall Plugs', 'Hinges', 'Locks'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasUnit: true,
          defaultUnit: 'Pack', unitOptions: ['Pack', 'Piece', 'Kg', 'Box'],
          defaultTaxRate: 18.0,
          isLoose: true, template: ProductTemplate.bulkUom,
        ),
      ),
      ShopCategory(
        name: 'Building Materials',
        subcategories: ['Cement', 'Sand', 'Bricks', 'Tiles', 'Waterproofing', 'POP / Gypsum',
          'Putty', 'Plywood / MDF'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasUnit: true,
          defaultUnit: 'Bag', unitOptions: ['Bag', 'Kg', 'Piece', 'Sheet', 'SqFt'],
          defaultTaxRate: 28.0,
          isLoose: true, template: ProductTemplate.bulkUom,
        ),
      ),
      ShopCategory(
        name: 'Plumbing',
        subcategories: ['PVC Pipes', 'Fittings & Elbows', 'Taps & Valves', 'Water Tank',
          'Water Pump', 'Pipe Fittings'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasUnit: true,
          isLoose: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Metre', 'Pack', 'Set'],
          defaultTaxRate: 18.0,
          template: ProductTemplate.bulkUom,
        ),
      ),
      ShopCategory(
        name: 'Electrical',
        subcategories: ['Wires & Cables', 'Switches & Sockets', 'MCB / Fuses', 'LED Bulbs',
          'Fans', 'Extension Boards', 'Conduit Pipes'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasUnit: true,
          isLoose: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Metre', 'Roll', 'Box'],
          defaultTaxRate: 18.0,
          template: ProductTemplate.bulkUom,
        ),
      ),
      ShopCategory(
        name: 'Paints & Finishes',
        subcategories: ['Wall Paint', 'Enamel Paint', 'Primer', 'Varnish', 'Thinner',
          'Putty', 'Brushes & Rollers'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasUnit: true,
          isLoose: true,
          defaultUnit: 'Litre', unitOptions: ['Litre', 'ML', 'Kg', 'Tin'],
          defaultTaxRate: 18.0,
          template: ProductTemplate.bulkUom,
        ),
      ),
      ShopCategory(
        name: 'Safety Equipment',
        subcategories: ['Helmets', 'Safety Gloves', 'Safety Goggles', 'Safety Shoes',
          'Hi-Viz Vests', 'Fire Extinguisher', 'First Aid Kit'],
        productFields: ProductFieldConfig(
          hasMrp: true, hasHsnCode: true, hasTaxRate: true, hasBrand: true,
          hasUnit: true,
          defaultUnit: 'Piece', unitOptions: ['Piece', 'Set', 'Pair'],
          defaultTaxRate: 18.0,
        ),
      ),
    ],

    // ────────────────────── COSMETICS & BEAUTY ─────────────────────────
    ShopType.cosmetics: [
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
    ],

    // ────────────────────── MOBILE & ACCESSORIES ─────────────────────────
    ShopType.mobile: [
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
    ],

    // ────────────────────── RESTAURANT ─────────────────────────
    ShopType.restaurant: [
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
    ],

    // ────────────────────── OTHER ─────────────────────────
    ShopType.other: [
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
    ],
  };
}
