// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../product_form_notifier.dart';

/// Field update methods (info / pricing / inventory)
extension ProductFormFieldUpdates on ProductFormNotifier {
  /// Update basic info fields
  void updateInfoField(String fieldName, String value) {
    if (!controllers.containsKey(fieldName)) return;

    switch (fieldName) {
      case 'brand':
        state = state.copyWith(brand: value);
      case 'manufacturer':
        state = state.copyWith(manufacturer: value);
      case 'hsn':
        state = state.copyWith(hsnCode: value);
      case 'weight':
        state = state.copyWith(weight: value);
      case 'recipe':
        state = state.copyWith(recipe: value);
      case 'isbn':
        state = state.copyWith(isbn: value);
      case 'serialNumber':
        state = state.copyWith(serialNumber: value);
      case 'imei':
        state = state.copyWith(imei: value);
      case 'warranty':
        state = state.copyWith(warranty: value);
      case 'schedule':
        state = state.copyWith(schedule: value);
      case 'batchNumber':
        state = state.copyWith(batchNumber: value);
      case 'size':
        state = state.copyWith(size: value);
      case 'color':
        state = state.copyWith(color: value);
    }
  }

  /// Update pricing fields
  void updatePricingField(String fieldName, String value) {
    if (!controllers.containsKey(fieldName)) return;

    final doubleValue = double.tryParse(value) ?? 0.0;
    switch (fieldName) {
      case 'price':
        state = state.copyWith(sellingPrice: doubleValue);
      case 'wholesalePrice':
        state = state.copyWith(wholesalePrice: doubleValue);
      case 'costPrice':
        state = state.copyWith(costPrice: doubleValue);
      case 'mrp':
        state = state.copyWith(mrp: doubleValue);
      case 'tax':
        state = state.copyWith(taxRate: doubleValue);
    }
  }

  /// Update inventory fields
  void updateInventoryField(String fieldName, String value) {
    if (!controllers.containsKey(fieldName)) return;

    final doubleValue = double.tryParse(value) ?? 0.0;
    switch (fieldName) {
      case 'initialQty':
        state = state.copyWith(initialQuantity: doubleValue);
      case 'reorderLevel':
        state = state.copyWith(reorderLevel: doubleValue);
      case 'conversionFactor':
        state = state.copyWith(conversionFactor: doubleValue);
      case 'packagingUnit':
        state = state.copyWith(packagingUnit: value.isEmpty ? null : value);
      case 'serviceDuration':
        final intValue = int.tryParse(value);
        state = state.copyWith(serviceDuration: intValue);
      case 'staffCommission':
        state = state.copyWith(staffCommission: doubleValue);
    }
  }
}
