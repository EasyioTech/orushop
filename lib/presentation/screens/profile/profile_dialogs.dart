part of '../profile_screen.dart';

extension _ProfileDialogs on _ProfileContent {
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performLogout(context, ref);
            },
            child: const Text('Logout', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context, WidgetRef ref) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      const SnackBar(content: Text('Logging out...')),
    );

    try {
      await ref.read(authServiceProvider).signOut();
      await ref.read(revenueCatServiceProvider).logOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_completed');

      if (context.mounted) {
        scaffold.showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );
      }
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performDeleteAccount(context, ref);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteAccount(BuildContext context, WidgetRef ref) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      const SnackBar(content: Text('Deleting account...')),
    );

    try {
      await user.delete();
      await ref.read(authServiceProvider).signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_completed');

      if (context.mounted) {
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Account deleted'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  
  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will wipe all local data including sales, inventory, and khata entries. This is useful for fixing "broken data" issues. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performClearData(context, ref);
            },
            child: const Text('Clear Everything', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _performClearData(BuildContext context, WidgetRef ref) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      const SnackBar(content: Text('Clearing data...')),
    );

    try {
      // 1. Clear Database
      await DatabaseHelper().clearAllData();
      
      // 2. Clear SharedPreferences (optional, maybe keep onboarding?)
      final prefs = await SharedPreferences.getInstance();
      // We might want to keep onboarding_completed so the user doesn't have to redo it, 
      // but if the data is "broken", maybe we should reset everything.
      // For now, let's just clear everything except onboarding.
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key != 'onboarding_completed') {
          await prefs.remove(key);
        }
      }

      if (context.mounted) {
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('All local data cleared successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
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