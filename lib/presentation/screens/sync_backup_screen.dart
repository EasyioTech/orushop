import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/sync_provider.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_boundary.dart';

class SyncBackupScreen extends ConsumerWidget {
  const SyncBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);
    final notifier = ref.read(syncStateProvider.notifier);
    final isOffline = ref.watch(isOfflineProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: OfflineBanner(
        isOffline: isOffline,
        child: RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            ref.invalidate(syncStateProvider);
            await Future.delayed(const Duration(milliseconds: 800));
          },
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Header
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
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Text(
                            'Sync & Backup',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 48),
                        child: Text(
                          isOffline
                              ? 'Working offline — local data only'
                              : 'Keep your data safe and updated',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cloud Sync Card
                      _SyncCard(
                        syncState: syncState,
                        isOffline: isOffline,
                        onSync: () => notifier.performSync(),
                      ),
                      const SizedBox(height: 24),
                      // Backup Card
                      _BackupCard(
                        syncState: syncState,
                        isOffline: isOffline,
                        onBackup: () => notifier.createBackup(),
                      ),
                      // Status / Error
                      if (syncState.lastSyncStatus != null &&
                          syncState.error == null) ...[
                        const SizedBox(height: 24),
                        _StatusCard(
                          message: syncState.lastSyncStatus!,
                          isSuccess: true,
                        ),
                      ],
                      if (syncState.error != null) ...[
                        const SizedBox(height: 24),
                        _StatusCard(
                          message: syncState.error!,
                          isSuccess: false,
                          isNetworkError: syncState.hasNetworkError,
                          retryCount: syncState.retryCount,
                          onDismiss: notifier.clearError,
                        ),
                      ],
                      if (syncState.lastSuccessfulSync != null) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Last successful sync: ${DateFormat('MMM d, y h:mm a').format(syncState.lastSuccessfulSync!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
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
}

class _SyncCard extends StatelessWidget {
  final SyncState syncState;
  final bool isOffline;
  final VoidCallback onSync;

  const _SyncCard({
    required this.syncState,
    required this.isOffline,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primaryDark.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isOffline
                        ? Icons.cloud_off_rounded
                        : Icons.cloud_sync_rounded,
                    color: isOffline ? AppTheme.slate500 : AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Cloud Sync',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            if (syncState.lastSyncTime != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Last synced: ${DateFormat('MMM d, y h:mm a').format(syncState.lastSyncTime!)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isOffline) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14, color: AppTheme.warningColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Connect to internet to sync your data.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (syncState.isSyncing || isOffline)
                    ? null
                    : onSync,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  disabledBackgroundColor:
                      AppTheme.primaryColor.withValues(alpha: 0.4),
                ),
                icon: syncState.isSyncing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(isOffline
                        ? Icons.wifi_off_rounded
                        : Icons.sync_rounded),
                label: Text(
                  syncState.isSyncing
                      ? 'SYNCING...'
                      : isOffline
                          ? 'OFFLINE'
                          : 'SYNC NOW',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  final SyncState syncState;
  final bool isOffline;
  final VoidCallback onBackup;

  const _BackupCard({
    required this.syncState,
    required this.isOffline,
    required this.onBackup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primaryDark.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.backup_rounded, color: AppTheme.warningColor),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Data Backup',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Create a secure cloud backup of all your store data, including products and sales history.',
              style: TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (syncState.isBackingUp || isOffline)
                    ? null
                    : onBackup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  backgroundColor: AppTheme.warningColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  disabledBackgroundColor: AppTheme.warningColor.withValues(alpha: 0.4),
                ),
                icon: syncState.isBackingUp
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(isOffline
                        ? Icons.wifi_off_rounded
                        : Icons.save_rounded),
                label: Text(
                  syncState.isBackingUp
                      ? 'BACKING UP...'
                      : isOffline
                          ? 'OFFLINE'
                          : 'CREATE BACKUP',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String message;
  final bool isSuccess;
  final bool isNetworkError;
  final int retryCount;
  final VoidCallback? onDismiss;

  const _StatusCard({
    required this.message,
    required this.isSuccess,
    this.isNetworkError = false,
    this.retryCount = 0,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSuccess
        ? AppTheme.successColor
        : isNetworkError
            ? AppTheme.warningColor
            : AppTheme.errorColor;
    final icon = isSuccess
        ? Icons.check_circle_rounded
        : isNetworkError
            ? Icons.wifi_off_rounded
            : Icons.error_rounded;

    return Card(
      color: color.withValues(alpha: 0.08),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isSuccess && retryCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Attempt $retryCount',
                      style: TextStyle(
                          color: color.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            if (onDismiss != null)
              GestureDetector(
                onTap: onDismiss,
                child: Icon(Icons.close_rounded,
                    color: color.withValues(alpha: 0.6), size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
