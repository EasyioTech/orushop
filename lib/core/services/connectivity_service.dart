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
      return NetworkStatus.online;
    }

    // Try multiple reliable hosts to avoid regional blocks or single-host failure
    final hosts = ['google.com', 'cloudflare.com', 'opendns.com'];
    bool hasLookupSuccess = false;

    for (final host in hosts) {
      try {
        final result = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 3));
        if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
          hasLookupSuccess = true;
          break;
        }
      } catch (_) {
        // Continue to next host
        continue;
      }
    }

    if (hasLookupSuccess) {
      return NetworkStatus.online;
    }

    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return NetworkStatus.offline;
    }

    return NetworkStatus.limited;
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
