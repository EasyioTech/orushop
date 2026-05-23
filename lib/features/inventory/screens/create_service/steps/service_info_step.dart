import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/features/inventory/controllers/service_form_notifier.dart';
import 'package:orushops/providers/staff_provider.dart';

class ServiceInfoStep extends ConsumerWidget {
  final GlobalKey<FormState> formKey;
  const ServiceInfoStep({super.key, required this.formKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceFormNotifierProvider);
    final notifier = ref.read(serviceFormNotifierProvider.notifier);
    final staffAsync = ref.watch(activeStaffProvider);

    final durationUnits = ['Minutes', 'Hours', 'Session', 'Visit', 'Job'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Picker
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => _showImageSourcePicker(context, notifier),
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
                        child: state.serviceImage != null
                            ? Image.file(
                                state.serviceImage!,
                                fit: BoxFit.cover,
                              )
                            : (state.externalImageUrl != null
                                ? Image.network(
                                    state.externalImageUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(
                                    Icons.add_a_photo_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 32,
                                  )),
                      ),
                    ),
                  ),
                  if (state.serviceImage != null || state.externalImageUrl != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          notifier.clearServiceImage();
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
            const SizedBox(height: 24),

            // Basic Info Section
            Text(
              'Service Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.textSecondary.withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: notifier.controllers['name'],
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              decoration: AppTheme.premiumDecoration(
                label: 'Service Name*',
                hint: 'e.g. Haircut & Hairwash',
                prefixIcon: const Icon(Icons.design_services_rounded, color: AppTheme.primaryColor),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the service name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: notifier.controllers['price'],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    decoration: AppTheme.premiumDecoration(
                      label: 'Price (₹)*',
                      hint: '499',
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, color: AppTheme.primaryColor),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Price required';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price < 0) {
                        return 'Invalid price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: notifier.controllers['tax'],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    decoration: AppTheme.premiumDecoration(
                      label: 'GST %',
                      hint: '18',
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
            const SizedBox(height: 24),

            // Duration Section
            Text(
              'Service Duration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.textSecondary.withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: notifier.controllers['durationMinutes'],
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    decoration: AppTheme.premiumDecoration(
                      label: 'Duration',
                      hint: '60',
                      prefixIcon: const Icon(Icons.timer_rounded, color: AppTheme.primaryColor),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final val = int.tryParse(value);
                        if (val == null || val <= 0) {
                          return 'Invalid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.slate200, width: 1.5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: state.durationUnit,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        items: durationUnits.map((String unit) {
                          return DropdownMenuItem<String>(
                            value: unit,
                            child: Text(unit),
                          );
                        }).toList(),
                        onChanged: (String? newVal) {
                          if (newVal != null) {
                            HapticFeedback.selectionClick();
                            notifier.setDurationUnit(newVal);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Staff Assignment Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assign Staff',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textSecondary.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    final newStaffId = await context.push('/staff/create');
                    if (newStaffId != null && newStaffId is int) {
                      ref.invalidate(activeStaffProvider);
                      notifier.toggleStaffSelection(newStaffId);
                    }
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                  label: const Text('Add Staff', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 8),

            staffAsync.when(
              data: (staffList) {
                if (staffList.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.slate50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.slate200, width: 1),
                    ),
                    child: const Center(
                      child: Text(
                        'No active staff added yet. Tap "Add Staff" to create.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: staffList.length,
                    itemBuilder: (context, index) {
                      final staff = staffList[index];
                      final isSelected = state.assignedStaffIds.contains(staff.id ?? 0);

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          notifier.toggleStaffSelection(staff.id ?? 0);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor.withValues(alpha: 0.05)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : AppTheme.slate200,
                              width: 1.5,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppTheme.slate100,
                                    backgroundImage: staff.photoPath != null
                                        ? FileImage(File(staff.photoPath!))
                                        : null,
                                    child: staff.photoPath == null
                                        ? Text(
                                            staff.name.substring(0, 1).toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    staff.name,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Description Section
            Text(
              'Additional Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.textSecondary.withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: notifier.controllers['description'],
              maxLines: 3,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              decoration: AppTheme.premiumDecoration(
                label: 'Description',
                hint: 'Provide details about what is included in the service',
                prefixIcon: const Icon(Icons.description_rounded, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: notifier.controllers['availabilityNotes'],
              maxLines: 2,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              decoration: AppTheme.premiumDecoration(
                label: 'Availability Notes',
                hint: 'e.g. Mon-Sat, 9:00 AM - 7:00 PM',
                prefixIcon: const Icon(Icons.event_available_rounded, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _showImageSourcePicker(BuildContext context, ServiceFormNotifier notifier) {
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
                'Select Image Source',
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
                      notifier.pickServiceImage(source: ImageSource.camera);
                    },
                  ),
                  _ImageSourceTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(ctx);
                      notifier.pickServiceImage(source: ImageSource.gallery);
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
        width: 100,
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
