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
import 'settings/receipt_banner_settings_screen.dart';
import '../../features/onboarding/models/shop_models.dart';
import '../../providers/shop_provider.dart';

part 'settings/settings_widgets.dart';
part 'settings/settings_action_buttons.dart';

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
                    _ShopTypeTile(
                      currentType: ref.watch(shopTypeProvider),
                      onTap: () => _showStoreTypeSheet(context, ref),
                    ),
                    _ActionButton(
                      icon: Icons.receipt_long_rounded,
                      label: 'Receipt Banner Customization',
                      subtitle: 'Change the advertisement banner on bills',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReceiptBannerSettingsScreen(),
                          ),
                        );
                      },
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

  void _showStoreTypeSheet(BuildContext context, WidgetRef ref) {
    final current = ref.read(shopTypeProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Store Type',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.8),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select your business category',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: ShopType.values.length,
              itemBuilder: (ctx, i) {
                final type = ShopType.values[i];
                final color = _shopTypeColor(type);
                final icon = _shopTypeIcon(type);
                final label = ShopTypeConfig.getConfig(type).displayName;
                final isSelected = type == current;
                return GestureDetector(
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(ctx);
                    try {
                      await OwnerRepository().updateShopType(type.name);
                      ref.invalidate(ownerDetailsStreamProvider);
                      ref.invalidate(shopCategoriesProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Store type updated to ${ShopTypeConfig.getConfig(type).displayName}'),
                          backgroundColor: AppTheme.successColor,
                          duration: const Duration(seconds: 2),
                        ));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppTheme.errorColor,
                        ));
                      }
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color : AppTheme.slate200,
                        width: isSelected ? 2 : 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: color, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? color : AppTheme.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
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

