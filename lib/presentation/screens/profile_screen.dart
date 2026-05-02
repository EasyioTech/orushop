import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/revenue_cat_service.dart';
import '../../core/theme/app_theme.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Not logged in')),
          );
        }
        return _ProfileContent(user: user);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  final User user;

  const _ProfileContent({required this.user});

  String _getInitials() {
    final name = user.displayName ?? user.email ?? 'User';
    return name
        .split(' ')
        .take(2)
        .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
        .join();
  }

  String? _getPhoneProvider() {
    for (var provider in user.providerData) {
      if (provider.providerId == 'phone') {
        return provider.phoneNumber;
      }
    }
    return null;
  }

  String _getAuthProvider() {
    final providers = user.providerData.map((p) => p.providerId).toList();
    if (providers.contains('google.com')) return 'Google';
    if (providers.contains('apple.com')) return 'Apple';
    if (providers.contains('password')) return 'Email';
    if (providers.contains('phone')) return 'Phone';
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneNumber = _getPhoneProvider() ?? user.phoneNumber;
    final authProvider = _getAuthProvider();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
        },
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header with Profile Info
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
                  children: [
                    // Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: user.photoURL != null && user.photoURL!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                user.photoURL!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildAvatarPlaceholder(),
                              ),
                            )
                          : _buildAvatarPlaceholder(),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      user.displayName ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Auth Method Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Connected via $authProvider',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Account Section
              _Section(
                title: 'Account Information',
                children: [
                  _InfoTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email ?? 'Not provided',
                  ),
                  if (phoneNumber != null)
                    _InfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: phoneNumber,
                    ),
                  _InfoTile(
                    icon: Icons.verified_user_outlined,
                    label: 'Account ID',
                    value: user.uid,
                    copyable: true,
                  ),
                  _InfoTile(
                    icon: Icons.check_circle_outlined,
                    label: 'Email Verified',
                    value: user.emailVerified ? 'Yes' : 'No',
                    valueColor: user.emailVerified ? AppTheme.successColor : AppTheme.warningColor,
                  ),
                ],
              ),
              // Settings Section
              _Section(
                title: 'Account Settings',
                children: [
                  _ActionTile(
                    icon: Icons.edit_outlined,
                    label: 'Edit Profile',
                    subtitle: 'Update your name and photo',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit profile coming soon')),
                      );
                    },
                  ),
                  _ActionTile(
                    icon: Icons.security_outlined,
                    label: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password change coming soon')),
                      );
                    },
                  ),
                  _ActionTile(
                    icon: Icons.analytics_outlined,
                    label: 'Analytics',
                    subtitle: 'View sales and performance reports',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AnalyticsScreen(),
                        ),
                      );
                    },
                  ),
                  _ActionTile(
                    icon: Icons.settings_outlined,
                    label: 'App Settings',
                    subtitle: 'Configure store and app preferences',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              // Danger Zone
              _Section(
                title: 'Danger Zone',
                children: [
                  _DangerActionTile(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    subtitle: 'Sign out of your account',
                    onTap: () => _showLogoutDialog(context, ref),
                  ),
                  _DangerActionTile(
                    icon: Icons.delete_outline,
                    label: 'Delete Account',
                    subtitle: 'Permanently delete your account',
                    onTap: () => _showDeleteDialog(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

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
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
    this.valueColor,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: copyable
            ? IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              )
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.textSecondary.withValues(alpha: 0.5),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _DangerActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _DangerActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(icon, color: AppTheme.errorColor),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppTheme.errorColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.errorColor.withValues(alpha: 0.5),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
