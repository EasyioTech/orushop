import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/repositories/product_repository.dart';
import '../core/repositories/sale_repository.dart';
import '../core/repositories/refund_repository.dart';
import '../core/services/sync_service.dart';
import '../core/providers/connectivity_provider.dart';

import '../core/repositories/khata_repository.dart';
import '../core/database/database_helper.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  const baseUrl = 'https://api.OruShops.com';
  return SyncService(
    baseUrl: baseUrl,
    productRepository: ProductRepository(),
    saleRepository: SaleRepository(),
    refundRepository: RefundRepository(),
    khataRepository: KhataRepository(DatabaseHelper()),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

final syncStateProvider = StateNotifierProvider<SyncStateNotifier, SyncState>(
  (ref) => SyncStateNotifier(ref.watch(syncServiceProvider)),
);

class SyncState {
  final bool isSyncing;
  final bool isBackingUp;
  final DateTime? lastSyncTime;
  final DateTime? lastSuccessfulSync;
  final String? lastSyncStatus;
  final String? error;
  final SyncErrorType? errorType;
  final int retryCount;

  const SyncState({
    this.isSyncing = false,
    this.isBackingUp = false,
    this.lastSyncTime,
    this.lastSuccessfulSync,
    this.lastSyncStatus,
    this.error,
    this.errorType,
    this.retryCount = 0,
  });

  bool get hasNetworkError =>
      errorType == SyncErrorType.offline || errorType == SyncErrorType.timeout;

  SyncState copyWith({
    bool? isSyncing,
    bool? isBackingUp,
    DateTime? lastSyncTime,
    DateTime? lastSuccessfulSync,
    String? lastSyncStatus,
    String? error,
    bool clearError = false,
    SyncErrorType? errorType,
    bool clearErrorType = false,
    int? retryCount,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastSuccessfulSync: lastSuccessfulSync ?? this.lastSuccessfulSync,
      lastSyncStatus: lastSyncStatus ?? this.lastSyncStatus,
      error: clearError ? null : error ?? this.error,
      errorType: clearErrorType ? null : errorType ?? this.errorType,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

class SyncStateNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;

  SyncStateNotifier(this._syncService) : super(const SyncState());

  Future<bool> performSync() async {
    state = state.copyWith(isSyncing: true, clearError: true, clearErrorType: true);
    final result = await _syncService.fullSync();
    if (result.success) {
      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        lastSuccessfulSync: DateTime.now(),
        lastSyncStatus: 'Sync successful',
        retryCount: 0,
      );
      return true;
    } else {
      final err = SyncException(result.errorType!, result.errorMessage ?? '');
      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        lastSyncStatus: 'Sync failed',
        error: err.toUserMessage(),
        errorType: result.errorType,
        retryCount: state.retryCount + 1,
      );
      return false;
    }
  }

  Future<bool> createBackup() async {
    state = state.copyWith(isBackingUp: true, clearError: true, clearErrorType: true);
    try {
      final backup = await _syncService.getBackupData();
      if (backup == null) {
        state = state.copyWith(
          isBackingUp: false,
          error: 'Failed to read local data for backup.',
          errorType: SyncErrorType.dataError,
        );
        return false;
      }
      final result = await _syncService.uploadBackup(backup);
      if (result.success) {
        state = state.copyWith(
          isBackingUp: false,
          lastSyncStatus: 'Backup created',
          retryCount: 0,
        );
        return true;
      } else {
        final err = SyncException(result.errorType!, result.errorMessage ?? '');
        state = state.copyWith(
          isBackingUp: false,
          error: err.toUserMessage(),
          errorType: result.errorType,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isBackingUp: false,
        error: 'Backup failed. Your local data is safe.',
        errorType: SyncErrorType.unknown,
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true, clearErrorType: true);
  }
}
