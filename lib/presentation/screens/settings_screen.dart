import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/settings_provider.dart';
import 'sync_backup_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/database_helper.dart';
import 'package:orushops/providers/products_provider.dart';
import '../../core/repositories/owner_repository.dart';
import '../../core/repositories/owner_provider.dart';
import '../../core/services/global_catalog_service.dart';
import '../../core/services/compliance_service.dart';
import '../../core/services/auth_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final ownerDetailsAsync = ref.watch(ownerDetailsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(settingsProvider);
          await ref.read(settingsProvider.future);
        },
        color: AppTheme.primaryColor,
        child: settingsAsync.when(
          data: (settings) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 20,
                    right: 20,
                    bottom: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Configure your store preferences',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Store Settings
                _SettingsSection(
                  title: 'Store Information',
                  children: [
                    _EditableSettingTile(
                      icon: Icons.store_rounded,
                      label: 'Store Name',
                      value: ownerDetailsAsync.value?['storeName'] ?? 'Not set',
                      onEdit: () => _showEditDialog(
                        context,
                        ref,
                        'Store Name',
                        ownerDetailsAsync.value?['storeName'] ?? '',
                        (value) => OwnerRepository().updateStoreName(value),
                      ),
                    ),
                    _EditableSettingTile(
                      icon: Icons.phone_rounded,
                      label: 'Phone',
                      value: ownerDetailsAsync.value?['storePhone'] ?? 'Not set',
                      onEdit: () => _showEditDialog(
                        context,
                        ref,
                        'Phone Number',
                        ownerDetailsAsync.value?['storePhone'] ?? '',
                        (value) => OwnerRepository().updateStorePhone(value),
                      ),
                    ),
                    _EditableSettingTile(
                      icon: Icons.location_on_rounded,
                      label: 'Address',
                      value: ownerDetailsAsync.value?['storeAddress'] ?? 'Not set',
                      onEdit: () => _showEditDialog(
                        context,
                        ref,
                        'Address',
                        ownerDetailsAsync.value?['storeAddress'] ?? '',
                        (value) => OwnerRepository().updateStoreAddress(value),
                      ),
                    ),
                  ],
                ),
                // Privacy & Compliance
                _SettingsSection(
                  title: 'Privacy & Compliance',
                  children: [
                    _ActionButton(
                      icon: Icons.privacy_tip_rounded,
                      label: 'Privacy Policy',
                      subtitle: 'View our privacy policy',
                      onTap: () => ref.read(complianceServiceProvider).launchPrivacyPolicy(),
                    ),
                    _ActionButton(
                      icon: Icons.description_rounded,
                      label: 'Terms of Service',
                      subtitle: 'View terms and conditions',
                      onTap: () => ref.read(complianceServiceProvider).launchTermsOfService(),
                    ),
                    _SwitchSettingTile(
                      icon: Icons.analytics_rounded,
                      label: 'Analytics & Crash Reports',
                      subtitle: 'Help us improve by sharing anonymous data',
                      value: ref.watch(complianceServiceProvider).hasAnalyticsConsent,
                      onChanged: (val) => ref.read(complianceServiceProvider).acceptAnalytics(val),
                    ),
                    _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Request Data Deletion',
                      subtitle: 'Delete all your data from our servers',
                      onTap: () => _showDataDeletionDialog(context, ref),
                    ),
                  ],
                ),
                // Data Management
                _SettingsSection(
                  title: 'Data Management',
                  children: [
                    _FactoryResetButton(ref: ref),
                    _SeedCatalogButton(ref: ref),
                    _ActionButton(
                      icon: Icons.cloud_sync_rounded,
                      label: 'Sync & Backup',
                      subtitle: 'Cloud sync and backup management',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SyncBackupScreen(),
                          ),
                        );
                      },
                    ),
                    _ActionButton(
                      icon: Icons.download_rounded,
                      label: 'Export Sales',
                      subtitle: 'Download sales data as CSV',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Exporting sales data...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                // App Management
                _SettingsSection(
                  title: 'App Management',
                  children: [
                    _InfoButton(
                      icon: Icons.info_rounded,
                      label: 'App Version',
                      value: '1.0.0',
                    ),
                    _ClearCacheButton(ref: ref),
                    _ClearDataButton(ref: ref),
                  ],
                ),
                // About
                _SettingsSection(
                  title: 'About',
                  children: [
                    _InfoButton(
                      icon: Icons.store_rounded,
                      label: 'About OruShops',
                      value: 'Retail POS System',
                    ),
                    _ActionButton(
                      icon: Icons.help_rounded,
                      label: 'Help & Support',
                      subtitle: 'Contact support team',
                      onTap: () {
                        launchUrl(Uri.parse('mailto:support@orushops.com'));
                      },
                    ),
                  ],
                ),
                // Developer Settings (Only visible in debug or if specifically needed)
                _SettingsSection(
                  title: 'Developer Tools',
                  children: [
                    _SwitchSettingTile(
                      icon: Icons.bug_report_rounded,
                      label: 'RevenueCat Test Mode',
                      subtitle: 'Use sandbox environment for IAP',
                      value: ref.watch(revenueCatTestModeProvider).value ?? true,
                      onChanged: (val) {
                        ref.read(updateRevenueCatTestModeProvider(val));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Test Mode ${val ? "Enabled" : "Disabled"}. Restart app to apply.'),
                            action: SnackBarAction(label: 'RESTART', onPressed: () => SystemNavigator.pop()),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text('Error: $err'),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    String title,
    String initialValue,
    Future<void> Function(String) onSave,
  ) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          autofocus: false,
          decoration: InputDecoration(
            hintText: 'Enter $title',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await onSave(controller.text);
                ref.invalidate(ownerDetailsStreamProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$title updated successfully'),
                      backgroundColor: AppTheme.successColor,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDataDeletionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Your Data?'),
        content: const Text(
          'This will request permanent deletion of all your data from our servers including your account, products, sales records, and khata. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () {
              Navigator.pop(context);
              _performDataDeletion(context, ref);
            },
            child: const Text('Delete My Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDataDeletion(BuildContext context, WidgetRef ref) async {
    final scaffold = ScaffoldMessenger.of(context);
    final complianceService = ref.read(complianceServiceProvider);
    final authState = ref.read(authStateProvider);

    scaffold.showSnackBar(const SnackBar(content: Text('Requesting data deletion...')));

    try {
      final user = authState.value;
      if (user == null) {
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Error: Not authenticated'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      await complianceService.requestDataDeletion(user.uid);

      scaffold.showSnackBar(
        const SnackBar(
          content: Text('Data deletion request submitted. You will be logged out.'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SwitchSettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSettingTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableSettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _EditableSettingTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              onPressed: onEdit,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoButton({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearCacheButton extends ConsumerWidget {
  final WidgetRef ref;

  const _ClearCacheButton({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showClearDialog(context, ref),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.cleaning_services_rounded, color: Colors.orange, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Clear Cache',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Remove cached data',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text('This will remove cached data but keep your sales records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _performClearCache(context, ref);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _performClearCache(BuildContext context, WidgetRef ref) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      const SnackBar(content: Text('Clearing cache...')),
    );

    try {
      await ref.read(clearCacheProvider.future);
      scaffold.showSnackBar(
        const SnackBar(
          content: Text('Cache cleared successfully'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 1),
        ),
      );
      await Future.microtask(() => ref.refresh(cacheSizeProvider));
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

class _ClearDataButton extends ConsumerWidget {
  final WidgetRef ref;

  const _ClearDataButton({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showClearDialog(context, ref),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.delete_sweep_rounded, color: AppTheme.errorColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clear All Data',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.errorColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Reset app to default state',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text('This will permanently delete all sales, products, and other data. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _performClearData(context, ref);
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _performClearData(BuildContext context, WidgetRef ref) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      const SnackBar(content: Text('Clearing all data...')),
    );

    try {
      await ref.read(clearDataProvider.future);
      scaffold.showSnackBar(
        const SnackBar(
          content: Text('All data cleared'),
          backgroundColor: AppTheme.errorColor,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

class _FactoryResetButton extends ConsumerWidget {
  final WidgetRef ref;
  const _FactoryResetButton({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showResetDialog(context, ref),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.delete_forever_rounded, color: AppTheme.errorColor, size: 24),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Factory Reset",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.errorColor),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Clear all data, products, and sales (Irreversible)",
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Factory Reset?"),
        content: const Text(
          "This will PERMANENTLY DELETE all your data including products, batches, sales, and khata records. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () {
              Navigator.pop(context);
              _performReset(context, ref);
            },
            child: const Text("Delete Everything"),
          ),
        ],
      ),
    );
  }

  Future<void> _performReset(BuildContext context, WidgetRef ref) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(const SnackBar(content: Text("Clearing database...")));

    try {
      await DatabaseHelper().clearAllData();
      ref.invalidate(productsProvider);

      scaffold.showSnackBar(
        const SnackBar(
          content: Text("All data cleared successfully!"),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showDataDeletionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Your Data?"),
        content: const Text(
          "This will request permanent deletion of all your data from our servers including your account, products, sales records, and khata. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () {
              Navigator.pop(context);
              _performDataDeletion(context, ref);
            },
            child: const Text("Delete My Data"),
          ),
        ],
      ),
    );
  }

  Future<void> _performDataDeletion(BuildContext context, WidgetRef ref) async {
    final scaffold = ScaffoldMessenger.of(context);
    final complianceService = ref.read(complianceServiceProvider);
    final authState = ref.read(authStateProvider);

    scaffold.showSnackBar(const SnackBar(content: Text("Requesting data deletion...")));

    try {
      final user = authState.value;
      if (user == null) {
        scaffold.showSnackBar(
          const SnackBar(
            content: Text("Error: Not authenticated"),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      await complianceService.requestDataDeletion(user.uid);

      scaffold.showSnackBar(
        const SnackBar(
          content: Text("Data deletion request submitted. You will be logged out."),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 2),
        ),
      );

      // Add small delay to show the snackbar before logout
      await Future.delayed(const Duration(milliseconds: 500));
      // Logout will be handled by the auth state listener
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

class _SeedCatalogButton extends ConsumerWidget {
  final WidgetRef ref;

  const _SeedCatalogButton({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSeedDialog(context, ref),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Replenish Catalog",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Reload standard product database",
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSeedDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Replenish Catalog?"),
        content: const Text(
          "This will reset your products to the default catalog. Existing products and sales data will be wiped.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _performSeed(context, ref);
            },
            child: const Text("Wipe & Seed"),
          ),
        ],
      ),
    );
  }

  Future<void> _performSeed(BuildContext context, WidgetRef ref) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(const SnackBar(content: Text("Fetching catalog data from cloud...")));

    try {
      final ownerDetails = await ref.read(ownerDetailsStreamProvider.future);
      final shopType = ownerDetails?['shopType'] ?? 'grocery_supermarket';
      
      final catalogData = await ref.read(globalCatalogServiceProvider).downloadCatalogForShopType(shopType);
      
      if (catalogData.isEmpty) {
        scaffold.showSnackBar(const SnackBar(content: Text("Failed to download catalog or no items found for this shop type.")));
        return;
      }

      scaffold.showSnackBar(const SnackBar(content: Text("Seeding database...")));
      await DatabaseHelper().seedDatabase(catalogData, shopType);
      ref.invalidate(productsProvider);

      scaffold.showSnackBar(
        const SnackBar(
          content: Text("Catalog seeded successfully!"),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
