import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/database_helper.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/revenue_cat_service.dart';
import '../../core/theme/app_theme.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

part 'profile/profile_dialogs.dart';
part 'profile/profile_tiles.dart';

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
                            color: AppTheme.primaryDark.withValues(alpha: 0.2),
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
                title: 'Quick Actions',
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ActionPill(
                            icon: Icons.analytics_outlined,
                            label: 'Analytics',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AnalyticsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionPill(
                            icon: Icons.settings_outlined,
                            label: 'Settings',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Business Tools Section
              _Section(
                title: 'Business Tools',
                children: [
                  _ActionTile(
                    icon: Icons.people_alt_rounded,
                    label: 'Staff Roster',
                    subtitle: 'Manage staff, assignments, and rates',
                    onTap: () {
                      context.push('/staff');
                    },
                  ),
                  _ActionTile(
                    icon: Icons.category_rounded,
                    label: 'Service Categories',
                    subtitle: 'Configure default and custom service categories',
                    onTap: () {
                      context.push('/service-categories');
                    },
                  ),
                ],
              ),
              // Maintenance Section
              _Section(
                title: 'Maintenance',
                children: [
                  _ActionTile(
                    icon: Icons.cleaning_services_outlined,
                    label: 'Clear App Data',
                    subtitle: 'Reset local database and settings',
                    onTap: () => _showClearDataDialog(context, ref),
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

}
