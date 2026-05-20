part of '../settings_screen.dart';

class _ClearCacheButton extends ConsumerWidget {
  final WidgetRef ref;

  const _ClearCacheButton({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.2)),
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
                Icon(Icons.cleaning_services_rounded, color: AppTheme.warningColor, size: 24),
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
            style: FilledButton.styleFrom(backgroundColor: AppTheme.warningColor),
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
