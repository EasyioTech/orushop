import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/repositories/product_repository.dart';
import '../core/repositories/sale_repository.dart';
import '../core/repositories/refund_repository.dart';
import '../core/services/sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  const baseUrl = 'https://api.retaildost.com';
  return SyncService(
    baseUrl: baseUrl,
    productRepository: ProductRepository(),
    saleRepository: SaleRepository(),
    refundRepository: RefundRepository(),
  );
});

final syncStateProvider = StateNotifierProvider<SyncStateNotifier, SyncState>(
  (ref) => SyncStateNotifier(ref.watch(syncServiceProvider)),
);

class SyncState {
  final bool isSyncing;
  final bool isBackingUp;
  final DateTime? lastSyncTime;
  final String? lastSyncStatus;
  final String? error;

  SyncState({
    this.isSyncing = false,
    this.isBackingUp = false,
    this.lastSyncTime,
    this.lastSyncStatus,
    this.error,
  });

  SyncState copyWith({
    bool? isSyncing,
    bool? isBackingUp,
    DateTime? lastSyncTime,
    String? lastSyncStatus,
    String? error,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastSyncStatus: lastSyncStatus ?? this.lastSyncStatus,
      error: error ?? this.error,
    );
  }
}

class SyncStateNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;

  SyncStateNotifier(this._syncService) : super(SyncState());

  Future<bool> performSync() async {
    state = state.copyWith(isSyncing: true, error: null);
    try {
      final result = await _syncService.fullSync();
      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        lastSyncStatus: result ? 'Sync successful' : 'Sync failed',
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> createBackup() async {
    state = state.copyWith(isBackingUp: true, error: null);
    try {
      final backup = await _syncService.getBackupData();
      if (backup != null) {
        final uploaded = await _syncService.uploadBackup(backup);
        state = state.copyWith(
          isBackingUp: false,
          lastSyncStatus: uploaded ? 'Backup created' : 'Backup failed',
        );
        return uploaded;
      }
      state = state.copyWith(
        isBackingUp: false,
        error: 'Failed to prepare backup',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isBackingUp: false,
        error: e.toString(),
      );
      return false;
    }
  }
}
