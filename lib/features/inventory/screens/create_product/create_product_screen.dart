import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/features/inventory/controllers/product_form_notifier.dart';
import 'package:orushops/features/inventory/models/product_form_state.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';
import 'package:orushops/features/inventory/screens/create_product/steps/category_step.dart';
import 'package:orushops/features/inventory/screens/create_product/steps/info_step.dart';
import 'package:orushops/features/inventory/screens/create_product/steps/details_step.dart';
import 'package:orushops/features/inventory/screens/create_product/steps/variants_step.dart';

class CreateProductScreen extends ConsumerStatefulWidget {
  const CreateProductScreen({super.key});

  @override
  ConsumerState<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends ConsumerState<CreateProductScreen> {
  @override
  void dispose() {
    super.dispose();
  }
  late final ProductFormNotifier _notifier;



  @override
  void initState() {
    super.initState();
    _notifier = ref.read(productFormNotifierProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _notifier.loadCategories();

      // Recover any image lost to Android process death before checking for a draft
      await _notifier.retrieveLostImage();

      // Check if a saved draft exists and prompt to restore
      final hasSavedDraft = await _notifier.hasDraft();
      if (hasSavedDraft && mounted) {
        _showRestoreDraftDialog(_notifier);
      }
    });
  }

  void _showRestoreDraftDialog(ProductFormNotifier notifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: AppTheme.primaryColor, size: 28),
            SizedBox(width: 8),
            Text(
              'Restore Draft?',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: const Text(
          'We found a draft from your last product creation. Do you want to restore it and continue where you left off?',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        actions: [
          TextButton(
            onPressed: () {
              notifier.clearDraft();
              Navigator.pop(context);
            },
            child: const Text(
              'Discard Draft',
              style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await notifier.restoreDraft();
              await notifier.retrieveLostImage();
              navigator.pop();
            },
            child: const Text('Restore Draft'),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor, size: 28),
            SizedBox(width: 8),
            Text(
              'Discard Changes?',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to close? All unsaved progress will be lost.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog (No)
            },
            child: const Text(
              'No',
              style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              ref.read(productFormNotifierProvider.notifier).clearDraft(); // Ensure draft is wiped
              if (context.mounted) {
                 context.pop(); // Close wizard screen safely
              }
            },
            child: const Text('Yes, Discard'),
          ),
        ],
      ),
    );
  }


  void _handleBack(ProductFormState state, ProductFormNotifier notifier) {
    if (state.currentStep > 0) {
      notifier.setCurrentStep(state.currentStep - 1);
    } else {
      _showExitConfirmationDialog();
    }
  }

String? _validateStep(int step, ProductFormState state, ProductFormNotifier notifier) {
    switch (step) {
      case 0:
        if (state.selectedCategory == null) {
          return 'Please select a category to continue';
        }
        break;

      case 1:
        // Step 1: name, price, stock only
        final name = notifier.controllers['name']?.text.trim() ?? '';
        if (name.isEmpty) return 'Product Name is required';

        final priceText = notifier.controllers['price']?.text.trim() ?? '';
        if (priceText.isEmpty) return 'Selling Price is required';
        final price = double.tryParse(priceText);
        if (price == null || price <= 0) return 'Please enter a valid Selling Price greater than 0';

        final qtyText = notifier.controllers['initialQty']?.text.trim() ?? '';
        if (qtyText.isNotEmpty) {
          final qty = double.tryParse(qtyText);
          if (qty == null || qty < 0) return 'Current Stock cannot be negative';
        }
        break;

      case 2:
        // Step 2: MRP check + per-category field flag validation (NOT shop-type-level)
        final mrpText = notifier.controllers['mrp']?.text.trim() ?? '';
        if (mrpText.isNotEmpty) {
          final priceText = notifier.controllers['price']?.text.trim() ?? '';
          final price = double.tryParse(priceText) ?? 0;
          final mrp = double.tryParse(mrpText);
          if (mrp == null || mrp < price) {
            return 'MRP must be greater than or equal to the Selling Price';
          }
        }

        final category = state.selectedCategory;
        if (category != null) {
          final fields = category.productFields;

          if (fields.hasBatchNumber) {
            final batch = notifier.controllers['batchNumber']?.text.trim() ?? '';
            if (batch.isEmpty) return 'Batch Number is required for this item';
          }

          if (fields.hasExpiryDate && state.expiryDate == null) {
            return 'Expiry Date is required for this item';
          }

          if (fields.hasImei) {
            final imei = notifier.controllers['imei']?.text.trim() ?? '';
            if (imei.isEmpty) return 'IMEI is required';
            if (imei.length != 15 || int.tryParse(imei) == null) {
              return 'IMEI must be a valid 15-digit number';
            }
          }

          if (fields.hasIsbn) {
            final isbn = notifier.controllers['isbn']?.text.trim() ?? '';
            if (isbn.isEmpty) return 'ISBN is required for this item';
            if (isbn.length != 13 || int.tryParse(isbn) == null) {
              return 'ISBN must be a valid 13-digit number';
            }
          }

          // Variant fields only validated when NOT going to the variant matrix step
          if (fields.template != ProductTemplate.variantMatrix) {
            if (fields.hasSizeVariant) {
              final size = notifier.controllers['size']?.text.trim() ?? '';
              if (size.isEmpty) return 'Size is required for this item';
            }
            if (fields.hasColorVariant) {
              final color = notifier.controllers['color']?.text.trim() ?? '';
              if (color.isEmpty) return 'Color is required for this item';
            }
          }
        }
        break;

      case 3:
        // Variants step — validation handled inside VariantsStep
        break;
    }
    return null;
  }

  void _handleNext(ProductFormState state, ProductFormNotifier notifier) {
    final error = _validateStep(state.currentStep, state, notifier);
    if (error != null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(CupertinoIcons.exclamationmark_circle_fill, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    notifier.setCurrentStep(state.currentStep + 1);
  }

  /// The Variants step only applies to variant-matrix categories
  /// (clothing, footwear). Services and simple products skip it.
  bool _hasVariantStep(ProductFormState state) {
    final fields = state.selectedCategory?.productFields;
    return (fields?.hasSizeVariant ?? false) || (fields?.hasColorVariant ?? false);
  }

  /// Ordered list of step widgets for the current category.
  List<Widget> _stepWidgets(ProductFormState state, ProductFormNotifier notifier) {
    return [
      const CategoryStep(),
      InfoStep(onSave: () => _handleSave(notifier)),
      DetailsStep(onSave: () => _handleSave(notifier)),
      if (_hasVariantStep(state)) const VariantsStep(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productFormNotifierProvider);
    final notifier = ref.read(productFormNotifierProvider.notifier);

    final steps = _stepWidgets(state, notifier);
    final stepCount = steps.length;
    // Guard against a stale step index after the category (and thus the step
    // list) changed — e.g. switching from a variant category to a simple one.
    final currentStep = state.currentStep.clamp(0, stepCount - 1);

    ref.listen<ProductFormState>(
      productFormNotifierProvider,
      (previous, next) {
        if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(CupertinoIcons.exclamationmark_circle_fill, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      next.errorMessage!,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          notifier.clearErrorMessage();
        }
      },
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleBack(state, notifier);
        });
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Create Item',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => _handleBack(state, notifier),
          ),
        ),
        body: Stack(
          children: [
            IndexedStack(
              index: currentStep,
              children: steps,
            ),
            if (state.isLoading)
              Container(
                color: Colors.white.withValues(alpha: 0.7),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(state, notifier, currentStep, stepCount),
      ),
    );
  }

  Widget _buildBottomBar(
    ProductFormState state,
    ProductFormNotifier notifier,
    int currentStep,
    int stepCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.slate100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (currentStep > 0)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.slate100,
                foregroundColor: AppTheme.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => notifier.setCurrentStep(currentStep - 1),
              child: const Text('Back'),
            )
          else
            const SizedBox.shrink(),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(stepCount, (i) {
                final isActive = i == currentStep;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isActive ? AppTheme.primaryColor : AppTheme.slate200,
                  ),
                );
              }),
            ),
          ),
          if (currentStep < stepCount - 1)
            ElevatedButton(
              onPressed: () => _handleNext(state, notifier),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Next'),
            )
          else
            ElevatedButton(
              onPressed: () => _handleSave(notifier),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Save'),
            ),
        ],
      ),
    );
  }

  Future<void> _handleSave(ProductFormNotifier notifier) async {
    final state = ref.read(productFormNotifierProvider);
    
    // Validate final step(s)
    for (int i = 0; i <= state.currentStep; i++) {
      final error = _validateStep(i, state, notifier);
      if (error != null) {
        notifier.setCurrentStep(i); // Go back to the step that has the error so user can fix it!
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(CupertinoIcons.exclamationmark_circle_fill, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    error,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    
    final success = await notifier.createProduct();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Product created successfully!',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    } else {
      final formState = ref.read(productFormNotifierProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(CupertinoIcons.exclamationmark_circle_fill, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  formState.errorMessage ?? 'Failed to create product. Please try again.',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
