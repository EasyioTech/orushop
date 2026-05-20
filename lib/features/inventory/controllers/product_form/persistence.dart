// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../product_form_notifier.dart';

/// Draft save / restore via SharedPreferences
extension ProductFormPersistence on ProductFormNotifier {
  /// Check if a draft exists
  Future<bool> hasDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('product_creation_draft');
    } catch (_) {
      return false;
    }
  }

  /// Clear the saved draft
  Future<void> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('product_creation_draft');
      debugPrint('Draft cleared.');
    } catch (e) {
      debugPrint('Error clearing draft: $e');
    }
  }

  /// Save form state as a draft in SharedPreferences
  Future<void> saveAsDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftData = {
        'categoryName': state.selectedCategory?.name,
        'subcategory': state.selectedSubcategory,
        'unit': state.selectedUnit,
        'isLoose': state.isLoose,
        'isService': state.isService,
        'name': state.name,
        'sku': state.sku,
        'brand': state.brand,
        'manufacturer': state.manufacturer,
        'hsnCode': state.hsnCode,
        'weight': state.weight,
        'recipe': state.recipe,
        'isbn': state.isbn,
        'size': state.size,
        'color': state.color,
        'serialNumber': state.serialNumber,
        'imei': state.imei,
        'warranty': state.warranty,
        'schedule': state.schedule,
        'expiryDate': state.expiryDate?.toIso8601String(),
        'batchNumber': state.batchNumber,
        'sellingPrice': state.sellingPrice,
        'wholesalePrice': state.wholesalePrice,
        'costPrice': state.costPrice,
        'mrp': state.mrp,
        'taxRate': state.taxRate,
        'initialQuantity': state.initialQuantity,
        'reorderLevel': state.reorderLevel,
        'packagingUnit': state.packagingUnit,
        'conversionFactor': state.conversionFactor,
        'imagePath': state.productImage?.path,
        'currentStep': state.currentStep,
        'variantSizes': state.variantSizes,
        'variantColors': state.variantColors,
      };

      final jsonStr = json.encode(draftData);
      await prefs.setString('product_creation_draft', jsonStr);
      debugPrint('Draft saved successfully.');
    } catch (e) {
      debugPrint('Error saving draft: $e');
    }
  }

  /// Restore draft from SharedPreferences
  Future<bool> restoreDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('product_creation_draft');
      if (jsonStr == null) return false;

      final data = json.decode(jsonStr) as Map<String, dynamic>;

      ShopCategory? selectedCategory;
      if (data['categoryName'] != null) {
        final shopType = ref.read(shopTypeProvider);
        final categories = ShopCatalog.forType(shopType);
        for (final cat in categories) {
          if (cat.name.toLowerCase() == data['categoryName'].toString().toLowerCase()) {
            selectedCategory = cat;
            break;
          }
        }
      }

      controllers['name']!.text = data['name'] ?? '';
      controllers['sku']!.text = data['sku'] ?? '';
      controllers['brand']!.text = data['brand'] ?? '';
      controllers['manufacturer']!.text = data['manufacturer'] ?? '';
      controllers['hsn']!.text = data['hsnCode'] ?? '';
      controllers['weight']!.text = data['weight'] ?? '';
      controllers['recipe']!.text = data['recipe'] ?? '';
      controllers['isbn']!.text = data['isbn'] ?? '';
      controllers['size']!.text = data['size'] ?? '';
      controllers['color']!.text = data['color'] ?? '';
      controllers['serialNumber']!.text = data['serialNumber'] ?? '';
      controllers['imei']!.text = data['imei'] ?? '';
      controllers['warranty']!.text = data['warranty'] ?? '';
      controllers['schedule']!.text = data['schedule'] ?? '';
      controllers['batchNumber']!.text = data['batchNumber'] ?? '';
      controllers['price']!.text = data['sellingPrice']?.toString() ?? '';
      controllers['wholesalePrice']!.text = data['wholesalePrice']?.toString() ?? '';
      controllers['costPrice']!.text = data['costPrice']?.toString() ?? '';
      controllers['mrp']!.text = data['mrp']?.toString() ?? '';
      controllers['tax']!.text = data['taxRate']?.toString() ?? '';
      controllers['initialQty']!.text = data['initialQuantity']?.toString() ?? '0';
      controllers['reorderLevel']!.text = data['reorderLevel']?.toString() ?? '5';
      controllers['packagingUnit']!.text = data['packagingUnit'] ?? '';
      controllers['conversionFactor']!.text = data['conversionFactor']?.toString() ?? '1';

      state = state.copyWith(
        selectedCategory: selectedCategory,
        selectedSubcategory: data['subcategory'],
        selectedUnit: data['unit'] ?? 'Piece',
        isLoose: data['isLoose'] ?? false,
        isService: data['isService'] ?? false,
        name: data['name'] ?? '',
        sku: data['sku'] ?? '',
        brand: data['brand'],
        manufacturer: data['manufacturer'],
        hsnCode: data['hsnCode'],
        weight: data['weight'],
        recipe: data['recipe'],
        isbn: data['isbn'],
        size: data['size'],
        color: data['color'],
        serialNumber: data['serialNumber'],
        imei: data['imei'],
        warranty: data['warranty'],
        schedule: data['schedule'],
        expiryDate: data['expiryDate'] != null ? DateTime.tryParse(data['expiryDate']) : null,
        batchNumber: data['batchNumber'],
        sellingPrice: (data['sellingPrice'] as num?)?.toDouble() ?? 0.0,
        wholesalePrice: (data['wholesalePrice'] as num?)?.toDouble() ?? 0.0,
        costPrice: (data['costPrice'] as num?)?.toDouble() ?? 0.0,
        mrp: (data['mrp'] as num?)?.toDouble(),
        taxRate: (data['taxRate'] as num?)?.toDouble() ?? 0.0,
        initialQuantity: (data['initialQuantity'] as num?)?.toDouble() ?? 0.0,
        reorderLevel: (data['reorderLevel'] as num?)?.toDouble() ?? 5.0,
        packagingUnit: data['packagingUnit'],
        conversionFactor: (data['conversionFactor'] as num?)?.toDouble() ?? 1.0,
        productImage: data['imagePath'] != null ? File(data['imagePath']) : null,
        variantSizes: List<String>.from(data['variantSizes'] ?? []),
        variantColors: List<String>.from(data['variantColors'] ?? []),
        currentStep: data['currentStep'] ?? 0,
      );

      debugPrint('Draft restored successfully.');
      return true;
    } catch (e) {
      debugPrint('Error restoring draft: $e');
      return false;
    }
  }

  /// Retrieve any lost image data (for Android process death recovery)
  Future<void> retrieveLostImage() async {
    try {
      final LostDataResponse response = await _imagePicker.retrieveLostData();
      if (response.isEmpty) return;
      if (response.file != null) {
        state = state.copyWith(productImage: File(response.file!.path));
        // Save draft with the new image
        await saveAsDraft();
        debugPrint('Lost image retrieved successfully: ${response.file!.path}');
      }
    } catch (e) {
      debugPrint('Error retrieving lost image: $e');
    }
  }
}
