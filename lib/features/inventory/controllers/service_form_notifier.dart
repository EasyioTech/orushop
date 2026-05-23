import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:orushops/core/models/product.dart';
import 'package:orushops/core/database/database_helper.dart';
import 'package:orushops/core/database/table_constants.dart';
import 'package:orushops/features/inventory/models/service_form_state.dart';
import 'package:orushops/providers/products_provider.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';

class ServiceFormNotifier extends Notifier<ServiceFormState> {
  final ImagePicker _imagePicker = ImagePicker();

  final Map<String, TextEditingController> controllers = {
    'name': TextEditingController(),
    'price': TextEditingController(),
    'tax': TextEditingController(text: '0.0'),
    'durationMinutes': TextEditingController(text: '60'),
    'description': TextEditingController(),
    'availabilityNotes': TextEditingController(),
  };

  bool _disposed = false;

  @override
  ServiceFormState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      for (final c in controllers.values) {
        c.dispose();
      }
    });
    return const ServiceFormState();
  }

  void setCategory(String category) {
    state = state.copyWith(serviceCategory: category);
  }

  void setCurrentStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void setDurationUnit(String unit) {
    state = state.copyWith(durationUnit: unit);
  }

  void toggleStaffSelection(int staffId) {
    final list = List<int>.from(state.assignedStaffIds);
    if (list.contains(staffId)) {
      list.remove(staffId);
    } else {
      list.add(staffId);
    }
    state = state.copyWith(assignedStaffIds: list);
  }

  void setAssignedStaff(List<int> staffIds) {
    state = state.copyWith(assignedStaffIds: staffIds);
  }

  Future<void> pickServiceImage({required ImageSource source}) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        if (_disposed) return;
        state = state.copyWith(serviceImage: File(pickedFile.path));
      }
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(errorMessage: 'Image pick failed: $e');
    }
  }

  void clearServiceImage() {
    state = state.copyWith(serviceImage: null);
  }

  void clearErrorMessage() {
    state = state.copyWith(errorMessage: null);
  }

  void reset() {
    for (final controller in controllers.values) {
      controller.text = '';
    }
    controllers['tax']!.text = '0.0';
    controllers['durationMinutes']!.text = '60';
    state = const ServiceFormState();
  }

  /// Create service in database
  Future<bool> saveService() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final name = controllers['name']!.text.trim();
      final priceStr = controllers['price']!.text.trim();
      final taxStr = controllers['tax']!.text.trim();
      final durationStr = controllers['durationMinutes']!.text.trim();
      final desc = controllers['description']!.text.trim();
      final avail = controllers['availabilityNotes']!.text.trim();

      if (name.isEmpty) {
        throw 'Service name is required';
      }
      if (state.serviceCategory.isEmpty) {
        throw 'Service category is required';
      }
      final price = double.tryParse(priceStr);
      if (price == null || price < 0) {
        throw 'A valid service price is required';
      }

      final taxRate = double.tryParse(taxStr) ?? 0.0;
      final duration = int.tryParse(durationStr) ?? 60;

      final now = DateTime.now();
      // Format unique SKU: SVC-YYYYMMDD-XXXX
      final dateStr = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
      final randomPart = (1000 + (now.microsecondsSinceEpoch % 9000)).toString();
      final sku = "SVC-$dateStr-$randomPart";

      final product = Product(
        id: 0,
        template: ProductTemplate.serviceLabor,
        name: name,
        sku: sku,
        price: price,
        quantity: 0.0,
        category: state.serviceCategory,
        subcategory: null,
        unit: 'Session',
        mrp: price,
        hsnCode: null,
        taxRate: taxRate,
        brand: null,
        manufacturer: null,
        imageUrl: state.externalImageUrl,
        imagePath: state.serviceImage?.path,
        createdAt: now,
        updatedAt: now,
        isService: true,
        isLoose: false,
        costPrice: null,
        serviceDuration: duration,
        staffCommission: 0.0,
      );

      final db = await DatabaseHelper().database;
      await db.transaction((txn) async {
        final productRepo = ref.read(productRepositoryProvider);
        final productId = await productRepo.create(product, txn: txn);

        // Insert into service_details
        await txn.insert(TableConstants.serviceDetails, {
          'productId': productId,
          'durationMinutes': duration,
          'durationUnit': state.durationUnit,
          'availabilityNotes': avail.isNotEmpty ? avail : null,
          'bookingEnabled': 0,
          'notes': desc.isNotEmpty ? desc : null,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });

        // Insert staff assignments
        for (final staffId in state.assignedStaffIds) {
          await txn.insert(TableConstants.staffServiceAssignments, {
            'staffId': staffId,
            'productId': productId,
            'priceOverride': null,
            'durationOverride': null,
            'createdAt': now.toIso8601String(),
          });
        }
      });

      ref.invalidate(productsProvider);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Update an existing service
  Future<bool> updateService(int productId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final name = controllers['name']!.text.trim();
      final priceStr = controllers['price']!.text.trim();
      final taxStr = controllers['tax']!.text.trim();
      final durationStr = controllers['durationMinutes']!.text.trim();
      final desc = controllers['description']!.text.trim();
      final avail = controllers['availabilityNotes']!.text.trim();

      if (name.isEmpty) {
        throw 'Service name is required';
      }
      final price = double.tryParse(priceStr);
      if (price == null || price < 0) {
        throw 'A valid service price is required';
      }

      final taxRate = double.tryParse(taxStr) ?? 0.0;
      final duration = int.tryParse(durationStr) ?? 60;
      final now = DateTime.now();

      final db = await DatabaseHelper().database;
      await db.transaction((txn) async {
        // Fetch current product to keep SKU, image, etc.
        final currentRows = await txn.query(
          TableConstants.products,
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );
        if (currentRows.isEmpty) throw 'Service not found';
        final sku = currentRows.first['sku'] as String;
        final existingImagePath = currentRows.first['imagePath'] as String?;

        final product = Product(
          id: productId,
          template: ProductTemplate.serviceLabor,
          name: name,
          sku: sku,
          price: price,
          quantity: 0.0,
          category: state.serviceCategory,
          subcategory: null,
          unit: 'Session',
          mrp: price,
          hsnCode: null,
          taxRate: taxRate,
          brand: null,
          manufacturer: null,
          imageUrl: state.externalImageUrl,
          imagePath: state.serviceImage?.path ?? existingImagePath,
          createdAt: DateTime.parse(currentRows.first['createdAt'] as String),
          updatedAt: now,
          isService: true,
          isLoose: false,
          costPrice: null,
          serviceDuration: duration,
          staffCommission: 0.0,
        );

        final productRepo = ref.read(productRepositoryProvider);
        await productRepo.update(product, txn: txn);

        // Update service_details
        await txn.update(
          TableConstants.serviceDetails,
          {
            'durationMinutes': duration,
            'durationUnit': state.durationUnit,
            'availabilityNotes': avail.isNotEmpty ? avail : null,
            'notes': desc.isNotEmpty ? desc : null,
            'updatedAt': now.toIso8601String(),
          },
          where: 'productId = ?',
          whereArgs: [productId],
        );

        // Update staff assignments: delete old ones and insert new ones
        await txn.delete(
          TableConstants.staffServiceAssignments,
          where: 'productId = ?',
          whereArgs: [productId],
        );

        for (final staffId in state.assignedStaffIds) {
          await txn.insert(TableConstants.staffServiceAssignments, {
            'staffId': staffId,
            'productId': productId,
            'priceOverride': null,
            'durationOverride': null,
            'createdAt': now.toIso8601String(),
          });
        }
      });

      ref.invalidate(productsProvider);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void initializeForEdit(Product service, Map<String, dynamic> details, List<int> staffIds) {
    controllers['name']!.text = service.name;
    controllers['price']!.text = service.price.toString();
    controllers['tax']!.text = service.taxRate.toString();
    controllers['durationMinutes']!.text = details['durationMinutes']?.toString() ?? '60';
    controllers['description']!.text = details['notes'] ?? '';
    controllers['availabilityNotes']!.text = details['availabilityNotes'] ?? '';

    state = ServiceFormState(
      currentStep: 1,
      name: service.name,
      serviceCategory: service.category,
      price: service.price,
      taxRate: service.taxRate,
      durationMinutes: details['durationMinutes'],
      durationUnit: details['durationUnit'] ?? 'Minutes',
      description: details['notes'] ?? '',
      availabilityNotes: details['availabilityNotes'],
      assignedStaffIds: staffIds,
      externalImageUrl: service.imageUrl,
      serviceImage: service.imagePath != null ? File(service.imagePath!) : null,
    );
  }
}

final serviceFormNotifierProvider = NotifierProvider<ServiceFormNotifier, ServiceFormState>(
  ServiceFormNotifier.new,
);
