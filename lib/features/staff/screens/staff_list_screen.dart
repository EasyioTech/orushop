import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/core/models/staff_member.dart';
import 'package:orushops/providers/staff_provider.dart';

class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffListAsync = ref.watch(staffListProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Staff Roster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Add Staff Member',
            onPressed: () => _navigateToAddStaff(context, ref),
          ),
        ],
      ),
      body: staffListAsync.when(
        data: (staffList) {
          if (staffList.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          return RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              ref.invalidate(staffListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: staffList.length,
              itemBuilder: (context, index) {
                final staff = staffList[index];
                return _buildStaffCard(context, ref, staff);
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.errorColor,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load staff roster',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: staffListAsync.value?.isNotEmpty == true
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToAddStaff(context, ref),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Staff',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  void _navigateToAddStaff(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    final result = await context.push('/staff/create');
    if (result != null) {
      ref.invalidate(staffListProvider);
      ref.invalidate(activeStaffProvider);
    }
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Staff Members Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add professionals to assign them to services, set custom commission rates, and track hourly performance.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddStaff(context, ref),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add First Staff Member'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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

  Widget _buildStaffCard(BuildContext context, WidgetRef ref, StaffMember staff) {
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
    final fallbackColor = gradients[colorIndex];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppTheme.slate200, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          HapticFeedback.lightImpact();
          await context.push('/staff/${staff.id}');
          ref.invalidate(staffListProvider);
          ref.invalidate(activeStaffProvider);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Hero(
                tag: 'staff_avatar_${staff.id}',
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: fallbackColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.slate200, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: staff.photoPath != null && staff.photoPath!.isNotEmpty
                        ? Image.file(
                            File(staff.photoPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(staff, fallbackColor),
                          )
                        : _buildFallbackAvatar(staff, fallbackColor),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            staff.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!staff.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.slate100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'INACTIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      staff.role ?? 'Staff Member',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (staff.phone != null && staff.phone!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_rounded,
                            size: 13,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            staff.phone!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Pricing Details / Quick Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (staff.hourlyRate > 0)
                    Text(
                      '₹${staff.hourlyRate.toStringAsFixed(0)}/hr',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  if (staff.commissionPct > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${staff.commissionPct.toStringAsFixed(0)}% Comm',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppTheme.slate300,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(StaffMember staff, Color color) {
    return Center(
      child: Text(
        staff.name.isNotEmpty ? staff.name.substring(0, 1).toUpperCase() : 'S',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}
