part of '../shop_catalog_data.dart';

final List<ShopCategory> _hardwareCategories = [
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
];
