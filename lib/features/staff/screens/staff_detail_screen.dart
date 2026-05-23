import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/core/models/staff_member.dart';
import 'package:orushops/providers/staff_provider.dart';
import 'package:orushops/providers/products_provider.dart';

class StaffDetailScreen extends ConsumerStatefulWidget {
  final int staffId;
  const StaffDetailScreen({super.key, required this.staffId});

  @override
  ConsumerState<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends ConsumerState<StaffDetailScreen> {
  bool _isEditing = false;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _phoneController;
  late TextEditingController _hourlyRateController;
  late TextEditingController _commissionController;
  late TextEditingController _notesController;

  File? _imageFile;
  List<Map<String, dynamic>> _assignedServices = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _roleController = TextEditingController();
    _phoneController = TextEditingController();
    _hourlyRateController = TextEditingController();
    _commissionController = TextEditingController();
    _notesController = TextEditingController();
    
    // Load assigned services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssignedServices();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _phoneController.dispose();
    _hourlyRateController.dispose();
    _commissionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAssignedServices() async {
    try {
      final repo = ref.read(staffRepositoryProvider);
      final services = await repo.getAssignedServicesWithOverrides(widget.staffId);
      if (mounted) {
        setState(() {
          _assignedServices = services;
        });
      }
    } catch (e) {
      debugPrint('Error loading assigned services: $e');
    }
  }

  void _populateControllers(StaffMember staff) {
    _nameController.text = staff.name;
    _roleController.text = staff.role ?? '';
    _phoneController.text = staff.phone ?? '';
    _hourlyRateController.text = staff.hourlyRate > 0 ? staff.hourlyRate.toStringAsFixed(0) : '';
    _commissionController.text = staff.commissionPct > 0 ? staff.commissionPct.toStringAsFixed(0) : '';
    _notesController.text = staff.notes ?? '';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 500,
        maxHeight: 500,
      );
      if (pickedFile != null) {
        final image = File(pickedFile.path);
        setState(() {
          _imageFile = image;
        });
        
        // Auto update photo if not in edit mode
        if (!_isEditing) {
          final staffAsync = ref.read(staffByIdProvider(widget.staffId));
          if (staffAsync.hasValue && staffAsync.value != null) {
            final updated = staffAsync.value!.copyWith(
              photoPath: image.path,
              updatedAt: DateTime.now(),
            );
            await ref.read(staffRepositoryProvider).update(updated);
            ref.invalidate(staffByIdProvider(widget.staffId));
            ref.invalidate(staffListProvider);
            ref.invalidate(activeStaffProvider);
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ImageSourceTile(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _ImageSourceTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateStaffStatus(StaffMember staff, bool active) async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    try {
      final updated = staff.copyWith(
        isActive: active,
        updatedAt: DateTime.now(),
      );
      await ref.read(staffRepositoryProvider).update(updated);
      ref.invalidate(staffByIdProvider(widget.staffId));
      ref.invalidate(staffListProvider);
      ref.invalidate(activeStaffProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveStaffProfile(StaffMember staff) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final hourlyRate = double.tryParse(_hourlyRateController.text.trim()) ?? 0.0;
      final commissionPct = double.tryParse(_commissionController.text.trim()) ?? 0.0;

      final updated = staff.copyWith(
        name: _nameController.text.trim(),
        role: _roleController.text.trim().isEmpty ? null : _roleController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        photoPath: _imageFile?.path ?? staff.photoPath,
        hourlyRate: hourlyRate,
        commissionPct: commissionPct,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await ref.read(staffRepositoryProvider).update(updated);
      ref.invalidate(staffByIdProvider(widget.staffId));
      ref.invalidate(staffListProvider);
      ref.invalidate(activeStaffProvider);
      
      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteStaff() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Staff Member?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('This will permanently delete this staff profile, including all service assignments and override prices. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(staffRepositoryProvider).delete(widget.staffId);
        ref.invalidate(staffListProvider);
        ref.invalidate(activeStaffProvider);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Staff member deleted successfully'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unassignService(int productId, String serviceName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Remove Assignment?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to unassign $serviceName from this staff member?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Unassign', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(staffRepositoryProvider).unassignFromService(widget.staffId, productId);
        await _loadAssignedServices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unassigned from $serviceName'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
          );
        }
      }
    }
  }

  void _showServiceAssignmentPicker() {
    final productsAsync = ref.read(productsProvider);
    productsAsync.whenData((allProducts) {
      final servicesOnly = allProducts.where((p) => p.isService == true).toList();
      final alreadyAssignedIds = _assignedServices.map((e) => e['id'] as int).toSet();
      
      final assignableServices = servicesOnly.where((s) => !alreadyAssignedIds.contains(s.id)).toList();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Assign Service',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Select a service to assign to this staff member. You can override their specific price and duration afterwards.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: assignableServices.isEmpty
                    ? const Center(
                        child: Text(
                          'No assignable services available.\nCreate new services in the Services tab first.',
                          style: TextStyle(color: AppTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: assignableServices.length,
                        itemBuilder: (ctx, idx) {
                          final service = assignableServices[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppTheme.slate200),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.miscellaneous_services_rounded, color: AppTheme.primaryColor),
                              ),
                              title: Text(
                                service.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Standard: ₹${service.price.toStringAsFixed(0)}'),
                              trailing: ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  HapticFeedback.lightImpact();
                                  await ref.read(staffRepositoryProvider).assignToService(
                                    widget.staffId,
                                    service.id,
                                  );
                                  await _loadAssignedServices();
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Assign', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showOverrideBottomSheet(Map<String, dynamic> service) {
    final name = service['name'] as String;
    final id = service['id'] as int;
    final basePrice = (service['price'] as num?)?.toDouble() ?? 0.0;
    
    final priceOverride = service['priceOverride'] != null ? (service['priceOverride'] as num).toDouble() : null;
    final durationOverride = service['durationOverride'] as int?;

    final priceController = TextEditingController(text: priceOverride != null ? priceOverride.toStringAsFixed(0) : '');
    final durationController = TextEditingController(text: durationOverride != null ? durationOverride.toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Override for: $name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Set custom price and duration overrides for this specific staff member. Leave blank to use service defaults (Price: ₹${basePrice.toStringAsFixed(0)}).',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    decoration: AppTheme.premiumDecoration(
                      label: 'Override Price (₹)',
                      hint: priceOverride != null ? priceOverride.toStringAsFixed(0) : 'e.g. 450',
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    decoration: AppTheme.premiumDecoration(
                      label: 'Override Duration (min)',
                      hint: durationOverride != null ? durationOverride.toString() : 'e.g. 45',
                      prefixIcon: const Icon(Icons.timer_rounded, color: AppTheme.primaryColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final newPriceStr = priceController.text.trim();
                  final newDurationStr = durationController.text.trim();
                  
                  final newPrice = newPriceStr.isNotEmpty ? double.tryParse(newPriceStr) : null;
                  final newDuration = newDurationStr.isNotEmpty ? int.tryParse(newDurationStr) : null;

                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  
                  await ref.read(staffRepositoryProvider).assignToService(
                    widget.staffId,
                    id,
                    priceOverride: newPrice,
                    durationOverride: newDuration,
                  );
                  await _loadAssignedServices();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Save Overrides', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffByIdProvider(widget.staffId));

    return staffAsync.when(
      data: (staff) {
        if (staff == null) {
          return const Scaffold(
            body: Center(child: Text('Staff member not found')),
          );
        }

        // Generate a beautiful consistent color based on the staff member's name
        final List<Color> gradients = [
          const Color(0xFF3B82F6), // Blue
          const Color(0xFF10B981), // Emerald
          const Color(0xFFEC4899), // Pink
          const Color(0xFFF59E0B), // Amber
          const Color(0xFF8B5CF6), // Purple
          const Color(0xFFEF4444), // Red
        ];
        final colorIndex = staff.name.codeUnits.fold(0, (prev, element) => prev + element) % gradients.length;
        final themeColor = gradients[colorIndex];

        // Populate controllers once when loaded
        if (!_isEditing && _nameController.text.isEmpty) {
          _populateControllers(staff);
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: Text(staff.name),
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Edit Profile',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isEditing = true;
                    });
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Cancel Edit',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isEditing = false;
                      _populateControllers(staff);
                    });
                  },
                ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Banner Avatar Area
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          border: const Border(
                            bottom: BorderSide(color: AppTheme.slate200, width: 1.5),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _showImageSourcePicker,
                              child: Stack(
                                children: [
                                  Hero(
                                    tag: 'staff_avatar_${staff.id}',
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: themeColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(32),
                                        border: Border.all(color: AppTheme.slate200, width: 2),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(30),
                                        child: _imageFile != null
                                            ? Image.file(_imageFile!, fit: BoxFit.cover)
                                            : (staff.photoPath != null && staff.photoPath!.isNotEmpty
                                                ? Image.file(
                                                    File(staff.photoPath!),
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) =>
                                                        _buildFallbackAvatar(staff, themeColor),
                                                  )
                                                : _buildFallbackAvatar(staff, themeColor)),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              staff.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              staff.role ?? 'Staff Member',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Active Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: staff.isActive,
                                  activeThumbColor: AppTheme.successColor,
                                  onChanged: (active) => _updateStaffStatus(staff, active),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Profile Info/Form Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_isEditing) ...[
                                const Text(
                                  'Edit Profile details',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: AppTheme.premiumDecoration(
                                    label: 'Full Name*',
                                    hint: 'e.g. Ramesh Kumar',
                                    prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.primaryColor),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) return 'Name required';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _roleController,
                                  decoration: AppTheme.premiumDecoration(
                                    label: 'Role / Designation',
                                    hint: 'e.g. Stylist',
                                    prefixIcon: const Icon(Icons.badge_rounded, color: AppTheme.primaryColor),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: AppTheme.premiumDecoration(
                                    label: 'Phone Number',
                                    hint: 'e.g. 9876543210',
                                    prefixIcon: const Icon(Icons.phone_rounded, color: AppTheme.primaryColor),
                                  ),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty && value.trim().length < 10) return 'Invalid phone';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _hourlyRateController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: AppTheme.premiumDecoration(
                                          label: 'Hourly Rate (₹)',
                                          hint: '150',
                                          prefixIcon: const Icon(Icons.currency_rupee_rounded, color: AppTheme.primaryColor),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _commissionController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: AppTheme.premiumDecoration(
                                          label: 'Commission %',
                                          hint: '10',
                                          prefixIcon: const Icon(Icons.percent_rounded, color: AppTheme.primaryColor),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _notesController,
                                  maxLines: 2,
                                  decoration: AppTheme.premiumDecoration(
                                    label: 'Internal Notes',
                                    hint: 'Add private records here...',
                                    prefixIcon: const Icon(Icons.sticky_note_2_rounded, color: AppTheme.primaryColor),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => _saveStaffProfile(staff),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = false;
                                        _populateControllers(staff);
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                              ] else ...[
                                // Contact and Rates Info
                                Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    side: const BorderSide(color: AppTheme.slate200, width: 1.5),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        _buildInfoRow(Icons.phone_rounded, 'Phone', staff.phone ?? 'Not Provided'),
                                        const Divider(),
                                        _buildInfoRow(Icons.currency_rupee_rounded, 'Hourly Rate',
                                            staff.hourlyRate > 0 ? '₹${staff.hourlyRate.toStringAsFixed(0)}/hr' : 'No Base Hourly Rate'),
                                        const Divider(),
                                        _buildInfoRow(Icons.percent_rounded, 'Service Commission',
                                            staff.commissionPct > 0 ? '${staff.commissionPct.toStringAsFixed(0)}%' : 'No Custom Commission'),
                                        if (staff.notes != null && staff.notes!.isNotEmpty) ...[
                                          const Divider(),
                                          _buildInfoRow(Icons.sticky_note_2_rounded, 'Private Notes', staff.notes!),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 32),

                              // Assigned Services Section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Assigned Services',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _showServiceAssignmentPicker,
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: const Text('Assign New', style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              if (_assignedServices.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: AppTheme.slate200, width: 1.5),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.miscellaneous_services_rounded, size: 40, color: AppTheme.slate300),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'No Services Assigned Yet',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Assign services to enable this staff member to perform them and configure time/staff-specific pricing overrides.',
                                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      OutlinedButton(
                                        onPressed: _showServiceAssignmentPicker,
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        child: const Text('Assign Service'),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _assignedServices.length,
                                  itemBuilder: (ctx, idx) {
                                    final item = _assignedServices[idx];
                                    final basePrice = (item['price'] as num?)?.toDouble() ?? 0.0;
                                    final overridePrice = item['priceOverride'] != null ? (item['priceOverride'] as num).toDouble() : null;
                                    final overrideDuration = item['durationOverride'] as int?;

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: const BorderSide(color: AppTheme.slate200, width: 1.5),
                                      ),
                                      child: ListTile(
                                        onTap: () => _showOverrideBottomSheet(item),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        title: Text(
                                          item['name'] as String,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            if (overridePrice != null)
                                              Row(
                                                children: [
                                                  const Icon(Icons.price_check_rounded, size: 14, color: AppTheme.successColor),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Price Override: ₹${overridePrice.toStringAsFixed(0)} (Base: ₹${basePrice.toStringAsFixed(0)})',
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.successColor),
                                                  ),
                                                ],
                                              )
                                            else
                                              Text('Base Price: ₹${basePrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                            const SizedBox(height: 2),
                                            if (overrideDuration != null)
                                              Row(
                                                children: [
                                                  const Icon(Icons.timer_rounded, size: 14, color: AppTheme.accentColor),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Duration Override: $overrideDuration min',
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.edit_note_rounded, color: AppTheme.textSecondary),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.errorColor),
                                              onPressed: () => _unassignService(item['id'] as int, item['name'] as String),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              
                              const SizedBox(height: 40),

                              // Delete Button Block
                              if (!_isEditing) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: _deleteStaff,
                                    icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.errorColor),
                                    label: const Text('Delete Profile', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w900)),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 40),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar(StaffMember staff, Color color) {
    return Center(
      child: Text(
        staff.name.isNotEmpty ? staff.name.substring(0, 1).toUpperCase() : 'S',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _ImageSourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.slate50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.slate100, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
