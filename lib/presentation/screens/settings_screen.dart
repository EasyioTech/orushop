import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';
import 'sync_backup_screen.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

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
                // 1. Branded Header Section with Gradient
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
              _SettingsSection(
                title: 'Store',
                children: [
                  _SettingsTile(
                    title: 'Store Name',
                    subtitle: settings?.storeName ?? 'Not set',
                    trailing: true,
                  ),
                  _SettingsTile(
                    title: 'Phone',
                    subtitle: settings?.storePhone ?? 'Not set',
                    trailing: true,
                  ),
                  _SettingsTile(
                    title: 'Address',
                    subtitle: settings?.storeAddress ?? 'Not set',
                    trailing: true,
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Sales Settings',
                children: [
                  _SwitchTile(
                    title: 'Enable Discounts',
                    subtitle: 'Allow manual discounts on sales',
                    value: settings?.enableDiscounts ?? false,
                    onChanged: (value) {},
                  ),
                  _SwitchTile(
                    title: 'Enable UPI',
                    subtitle: 'Accept UPI payments',
                    value: settings?.enableUpi ?? false,
                    onChanged: (value) {},
                  ),
                  _SettingsTile(
                    title: 'Default Discount',
                    subtitle: '${settings?.defaultDiscountPercent.toInt() ?? 0}% off',
                    trailing: true,
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Data',
                children: [
                  _SettingsTile(
                    title: 'Sync & Backup',
                    subtitle: 'Cloud sync and backup management',
                    trailing: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SyncBackupScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    title: 'Export Sales',
                    subtitle: 'Download sales data as CSV',
                    trailing: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exporting sales data...')),
                      );
                    },
                  ),
                ],
              ),
              _SettingsSection(
                title: 'App',
                children: [
                  _SettingsTile(
                    title: 'App Version',
                    subtitle: '1.0.0',
                    trailing: true,
                  ),
                  _ClearCacheTile(ref: ref),
                  _ClearDataTile(ref: ref),
                ],
              ),
              _SettingsSection(
                title: 'About',
                children: [
                  _SettingsTile(
                    title: 'About RetailDost',
                    subtitle: 'POS System for Retail',
                    trailing: true,
                  ),
                  _SettingsTile(
                    title: 'Help & Support',
                    subtitle: 'Contact support team',
                    trailing: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Support: support@retaildost.com')),
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

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    this.trailing = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        trailing: trailing ? Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary.withValues(alpha: 0.5)) : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}

class _ClearCacheTile extends ConsumerWidget {
  final WidgetRef ref;

  const _ClearCacheTile({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: const Text('Clear Cache'),
        subtitle: const Text('Remove cached data'),
        onTap: () => _clearCache(context, ref),
      ),
    );
  }

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
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
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performClearCache(context, ref);
            },
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

class _ClearDataTile extends ConsumerWidget {
  final WidgetRef ref;

  const _ClearDataTile({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppTheme.errorColor.withValues(alpha: 0.05),
      child: ListTile(
        title: Text(
          'Clear All Data',
          style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Reset app to default state'),
        onTap: () => _clearData(context, ref),
      ),
    );
  }

  Future<void> _clearData(BuildContext context, WidgetRef ref) async {
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
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performClearData(context, ref);
            },
            child: const Text('Clear', style: TextStyle(color: AppTheme.errorColor)),
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
