import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum NetworkStatus { online, offline, limited }

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<NetworkStatus> _controller =
      StreamController<NetworkStatus>.broadcast();

  NetworkStatus _currentStatus = NetworkStatus.online;
  StreamSubscription? _subscription;

  NetworkStatus get currentStatus => _currentStatus;
  bool get isOffline => _currentStatus == NetworkStatus.offline;
  Stream<NetworkStatus> get statusStream => _controller.stream;

  ConnectivityService() {
    _init();
  }

  void _init() {
    _checkConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen((_) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    final status = await _getNetworkStatus();
    if (status != _currentStatus) {
      _currentStatus = status;
      _controller.add(status);
    }
  }

  Future<NetworkStatus> _getNetworkStatus() async {
    if (kIsWeb) {
      // Web can't use dart:io sockets; trust connectivity_plus
      final result = await _connectivity.checkConnectivity();
      return result == ConnectivityResult.none
          ? NetworkStatus.offline
          : NetworkStatus.online;
    }
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        return NetworkStatus.online;
      }
      return NetworkStatus.limited;
    } on SocketException {
      return NetworkStatus.offline;
    } on TimeoutException {
      return NetworkStatus.limited;
    } catch (_) {
      return NetworkStatus.offline;
    }
  }

  Future<NetworkStatus> checkNow() async {
    await _checkConnectivity();
    return _currentStatus;
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
