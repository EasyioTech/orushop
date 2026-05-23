import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/core/models/product.dart';
import 'package:orushops/core/database/database_helper.dart';
import 'package:orushops/core/database/table_constants.dart';
import 'package:orushops/features/inventory/controllers/service_form_notifier.dart';
import 'steps/service_category_step.dart';
import 'steps/service_info_step.dart';

class CreateServiceScreen extends ConsumerStatefulWidget {
  final Product? editProduct;
  const CreateServiceScreen({super.key, this.editProduct});

  @override
  ConsumerState<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends ConsumerState<CreateServiceScreen> {
  final _infoFormKey = GlobalKey<FormState>();
  bool _initialized = false;
  bool _loadingEditData = false;

  @override
  void initState() {
    super.initState();
    if (widget.editProduct != null) {
      _loadEditData();
    } else {
      // Delay reset to avoid riverpod rebuild loops during initState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(serviceFormNotifierProvider.notifier).reset();
        setState(() {
          _initialized = true;
        });
      });
    }
  }

  Future<void> _loadEditData() async {
    setState(() {
      _loadingEditData = true;
    });

    try {
      final db = await DatabaseHelper().database;
      final productId = widget.editProduct!.id;

      // 1. Fetch from service_details
      final detailRows = await db.query(
        TableConstants.serviceDetails,
        where: 'productId = ?',
        whereArgs: [productId],
        limit: 1,
      );

      final Map<String, dynamic> details = detailRows.isNotEmpty ? detailRows.first : {};

      // 2. Fetch assigned staff IDs
      final staffRows = await db.query(
        TableConstants.staffServiceAssignments,
        where: 'productId = ?',
        whereArgs: [productId],
      );

      final List<int> staffIds = staffRows.map((r) => r['staffId'] as int).toList();

      if (mounted) {
        ref.read(serviceFormNotifierProvider.notifier).initializeForEdit(
              widget.editProduct!,
              details,
              staffIds,
            );
        setState(() {
          _initialized = true;
          _loadingEditData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingEditData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading edit data: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (_infoFormKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      final formNotifier = ref.read(serviceFormNotifierProvider.notifier);
      final success = widget.editProduct != null
          ? await formNotifier.updateService(widget.editProduct!.id)
          : await formNotifier.saveService();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editProduct != null
                ? 'Service updated successfully!'
                : 'Service created successfully!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _loadingEditData) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    final state = ref.watch(serviceFormNotifierProvider);
    final notifier = ref.read(serviceFormNotifierProvider.notifier);
    final isEditMode = widget.editProduct != null;

    final String title = isEditMode ? 'Edit Service' : 'Add Service';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (state.currentStep > 0 && !isEditMode) {
              notifier.setCurrentStep(state.currentStep - 1);
            } else {
              context.pop();
            }
          },
        ),
        actions: [
          if (state.currentStep == 1)
            Container(
              margin: const EdgeInsets.only(right: 16),
              alignment: Alignment.center,
              child: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : TextButton(
                      onPressed: _handleSave,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Step indicators
          if (!isEditMode) _buildStepIndicators(state.currentStep),

          // Main form step
          Expanded(
            child: isEditMode || state.currentStep == 1
                ? ServiceInfoStep(formKey: _infoFormKey)
                : ServiceCategoryStep(onNext: () {
                    notifier.setCurrentStep(1);
                  }),
          ),
        ],
      ),
      bottomNavigationBar: state.errorMessage != null
          ? Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.errorColor,
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => notifier.clearErrorMessage(),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildStepIndicators(int currentStep) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          _buildStepNode(0, 'Category', currentStep >= 0),
          _buildStepConnector(currentStep > 0),
          _buildStepNode(1, 'Info', currentStep >= 1),
        ],
      ),
    );
  }

  Widget _buildStepNode(int index, String label, bool isActive) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : AppTheme.slate100,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: isActive ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Expanded(
      child: Container(
        height: 2.5,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : AppTheme.slate100,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
