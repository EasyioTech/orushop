import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/core/models/product.dart';
import 'package:orushops/core/models/staff_member.dart';
import 'package:orushops/core/database/database_helper.dart';
import 'package:orushops/core/database/table_constants.dart';
import 'package:orushops/providers/products_provider.dart';
import 'package:orushops/core/services/product_crud_service.dart';
import 'package:orushops/providers/staff_provider.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  final int serviceId;
  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  ConsumerState<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  bool _isLoading = true;
  Product? _service;
  Map<String, dynamic>? _details;
  List<StaffMember> _assignedStaff = [];

  @override
  void initState() {
    super.initState();
    _loadServiceDetails();
  }

  Future<void> _loadServiceDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper().database;
      final productId = widget.serviceId;

      // 1. Fetch Product
      final productRepo = ref.read(productRepositoryProvider);
      final product = await productRepo.getById(productId);

      if (product == null) {
        throw 'Service not found';
      }

      // 2. Fetch service_details
      final detailRows = await db.query(
        TableConstants.serviceDetails,
        where: 'productId = ?',
        whereArgs: [productId],
        limit: 1,
      );
      final details = detailRows.isNotEmpty ? detailRows.first : null;

      // 3. Fetch assigned staff
      final staffRows = await db.rawQuery('''
        SELECT s.* FROM ${TableConstants.staff} s
        INNER JOIN ${TableConstants.staffServiceAssignments} a ON s.id = a.staffId
        WHERE a.productId = ?
      ''', [productId]);

      final assignedStaff = staffRows.map((r) => StaffMember.fromMap(r)).toList();

      if (mounted) {
        setState(() {
          _service = product;
          _details = details;
          _assignedStaff = assignedStaff;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading details: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service?'),
        content: Text('Are you sure you want to delete "${_service?.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      HapticFeedback.mediumImpact();
      try {
        await ProductCrudService().deleteProduct(widget.serviceId);
        ref.invalidate(productsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service deleted successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting service: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _manageStaffAssignment() async {
    final db = await DatabaseHelper().database;
    final allActiveStaff = await ref.read(activeStaffProvider.future);

    if (!mounted) return;

    List<int> selectedIds = _assignedStaff.map((s) => s.id).whereType<int>().toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.slate200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Manage Service Staff',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Assign or unassign staff members for this service',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: allActiveStaff.isEmpty
                      ? const Center(
                          child: Text('No active staff available. Add staff in settings first.'),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: allActiveStaff.length,
                          itemBuilder: (ctx, index) {
                            final staff = allActiveStaff[index];
                            final isSelected = selectedIds.contains(staff.id);

                            return CheckboxListTile(
                              value: isSelected,
                              activeColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              title: Text(
                                staff.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: staff.role != null ? Text(staff.role!) : null,
                              secondary: CircleAvatar(
                                backgroundImage: staff.photoPath != null ? FileImage(File(staff.photoPath!)) : null,
                                child: staff.photoPath == null ? Text(staff.name.substring(0, 1).toUpperCase()) : null,
                              ),
                              onChanged: (bool? value) {
                                HapticFeedback.selectionClick();
                                setSheetState(() {
                                  if (value == true) {
                                    if (staff.id != null) selectedIds.add(staff.id!);
                                  } else {
                                    if (staff.id != null) selectedIds.remove(staff.id!);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Save to db
                      await db.transaction((txn) async {
                        await txn.delete(
                          TableConstants.staffServiceAssignments,
                          where: 'productId = ?',
                          whereArgs: [widget.serviceId],
                        );

                        for (final staffId in selectedIds) {
                          await txn.insert(TableConstants.staffServiceAssignments, {
                            'staffId': staffId,
                            'productId': widget.serviceId,
                            'priceOverride': null,
                            'durationOverride': null,
                            'createdAt': DateTime.now().toIso8601String(),
                          });
                        }
                      });

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _loadServiceDetails();
                    },
                    child: const Text('Save Assignments'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (_service == null) {
      return const Scaffold(
        body: Center(
          child: Text('Service not found.'),
        ),
      );
    }

    final hasImage = _service!.imagePath != null || _service!.imageUrl != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Banner Sliver AppBar
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: hasImage
                  ? (_service!.imagePath != null
                      ? Image.file(
                          File(_service!.imagePath!),
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          _service!.imageUrl!,
                          fit: BoxFit.cover,
                        ))
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _service!.category.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          // Main Info Details
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _service!.category,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _service!.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '₹${_service!.price}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.successColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Duration info row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.slate200, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoColumn(
                          icon: Icons.timer_rounded,
                          label: 'Duration',
                          value: '${_details?['durationMinutes'] ?? _service!.serviceDuration ?? 60} ${_details?['durationUnit'] ?? 'Minutes'}',
                        ),
                        Container(width: 1.5, height: 40, color: AppTheme.slate200),
                        _buildInfoColumn(
                          icon: Icons.percent_rounded,
                          label: 'Tax (GST)',
                          value: '${_service!.taxRate}%',
                        ),
                        Container(width: 1.5, height: 40, color: AppTheme.slate200),
                        _buildInfoColumn(
                          icon: Icons.people_rounded,
                          label: 'Staff Active',
                          value: '${_assignedStaff.length}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description card
                  if (_details?['notes'] != null && (_details?['notes'] as String).isNotEmpty) ...[
                    _buildSectionHeader('Description'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.slate200, width: 1.5),
                      ),
                      child: Text(
                        _details!['notes'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Staff Assignments list
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Assigned Staff'),
                      TextButton.icon(
                        onPressed: _manageStaffAssignment,
                        icon: const Icon(Icons.settings_rounded, size: 16),
                        label: const Text('Manage', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_assignedStaff.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.slate50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.slate200, width: 1),
                      ),
                      child: const Center(
                        child: Text(
                          'No staff assigned to this service yet.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _assignedStaff.length,
                      itemBuilder: (ctx, index) {
                        final staff = _assignedStaff[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.slate200, width: 1.5),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: staff.photoPath != null ? FileImage(File(staff.photoPath!)) : null,
                              child: staff.photoPath == null ? Text(staff.name.substring(0, 1).toUpperCase()) : null,
                            ),
                            title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: staff.role != null ? Text(staff.role!) : null,
                            trailing: Text(
                              staff.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: staff.isActive ? AppTheme.successColor : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // Availability Card
                  if (_details?['availabilityNotes'] != null && (_details?['availabilityNotes'] as String).isNotEmpty) ...[
                    _buildSectionHeader('Availability'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.slate200, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available_rounded, color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _details!['availabilityNotes'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.slate200, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push('/stock/edit-service', extra: _service);
                },
                icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
                label: const Text('Edit Details'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor, size: 28),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(14),
                backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: AppTheme.textSecondary.withValues(alpha: 0.8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
