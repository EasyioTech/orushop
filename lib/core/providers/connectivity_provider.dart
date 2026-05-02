import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final svc = ref.watch(connectivityServiceProvider);
  return svc.statusStream;
});

final isOfflineProvider = Provider<bool>((ref) {
  final status = ref.watch(networkStatusProvider);
  return status.whenData((s) => s == NetworkStatus.offline).value ?? false;
});
