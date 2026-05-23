import 'dart:io';
import '../../../core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/core/models/staff_member.dart';
import 'package:orushops/providers/staff_provider.dart';

class CreateStaffScreen extends ConsumerStatefulWidget {
  const CreateStaffScreen({super.key});

  @override
  ConsumerState<CreateStaffScreen> createState() => _CreateStaffScreenState();
}

class _CreateStaffScreenState extends ConsumerState<CreateStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _commissionController = TextEditingController();
  final _notesController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;

  final List<String> _roleSuggestions = [
    'Technician',
    'Barber',
    'Consultant',
    'Stylist',
    'Doctor',
    'Mechanic',
    'Therapist',
    'Cleaner',
    'Trainer',
  ];

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
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      appLogger.debug('Error picking image: $e');
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
                'Select Profile Photo',
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

  Future<void> _saveStaff() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final staffRepository = ref.read(staffRepositoryProvider);
      
      final hourlyRate = double.tryParse(_hourlyRateController.text.trim()) ?? 0.0;
      final commissionPct = double.tryParse(_commissionController.text.trim()) ?? 0.0;

      final newStaff = StaffMember(
        name: _nameController.text.trim(),
        role: _roleController.text.trim().isEmpty ? null : _roleController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        photoPath: _imageFile?.path,
        hourlyRate: hourlyRate,
        commissionPct: commissionPct,
        isActive: true,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final newId = await staffRepository.create(newStaff);

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newStaff.name} added successfully!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, newId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding staff member: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Add Staff Member'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Picker
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _showImageSourcePicker,
                            child: Hero(
                              tag: 'new_staff_avatar',
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: AppTheme.slate100,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: AppTheme.slate200, width: 2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: _imageFile != null
                                      ? Image.file(
                                          _imageFile!,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(
                                          Icons.add_a_photo_rounded,
                                          color: AppTheme.primaryColor,
                                          size: 32,
                                        ),
                                ),
                              ),
                            ),
                          ),
                          if (_imageFile != null)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _imageFile = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.errorColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Section: General Info
                    _buildSectionHeader('General Information'),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      decoration: AppTheme.premiumDecoration(
                        label: 'Full Name*',
                        hint: 'e.g. Ramesh Kumar',
                        prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.primaryColor),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _roleController,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      decoration: AppTheme.premiumDecoration(
                        label: 'Role / Designation',
                        hint: 'e.g. Master Stylist',
                        prefixIcon: const Icon(Icons.badge_rounded, color: AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Horizontal suggestions list
                    SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _roleSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _roleSuggestions[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(suggestion),
                              selected: _roleController.text == suggestion,
                              onSelected: (selected) {
                                if (selected) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _roleController.text = suggestion;
                                  });
                                }
                              },
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _roleController.text == suggestion
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                              selectedColor: AppTheme.primaryColor,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: _roleController.text == suggestion
                                      ? AppTheme.primaryColor
                                      : AppTheme.slate200,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      decoration: AppTheme.premiumDecoration(
                        label: 'Phone Number',
                        hint: 'e.g. 9876543210',
                        prefixIcon: const Icon(Icons.phone_rounded, color: AppTheme.primaryColor),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.trim().length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Section: Compensation
                    _buildSectionHeader('Compensation'),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _hourlyRateController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            decoration: AppTheme.premiumDecoration(
                              label: 'Hourly Rate (₹)',
                              hint: 'e.g. 150',
                              prefixIcon: const Icon(Icons.currency_rupee_rounded, color: AppTheme.primaryColor),
                            ),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final val = double.tryParse(value);
                                if (val == null || val < 0) {
                                  return 'Invalid rate';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _commissionController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            decoration: AppTheme.premiumDecoration(
                              label: 'Commission %',
                              hint: 'e.g. 10',
                              prefixIcon: const Icon(Icons.percent_rounded, color: AppTheme.primaryColor),
                            ),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final val = double.tryParse(value);
                                if (val == null || val < 0 || val > 100) {
                                  return 'Invalid %';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Section: Internal Notes
                    _buildSectionHeader('Notes'),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                      decoration: AppTheme.premiumDecoration(
                        label: 'Internal Notes',
                        hint: 'Record private details or work timing preferences here...',
                        prefixIcon: const Icon(Icons.sticky_note_2_rounded, color: AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveStaff,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Save Staff Member',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
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