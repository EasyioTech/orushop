import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../repositories/product_repository.dart';
import '../repositories/sale_repository.dart';
import '../repositories/refund_repository.dart';
import '../repositories/khata_repository.dart';
import 'connectivity_service.dart';

enum SyncErrorType { offline, timeout, serverError, dataError, unknown }

class SyncException implements Exception {
  final SyncErrorType type;
  final String message;

  SyncException(this.type, this.message);

  @override
  String toString() => message;

  String toUserMessage() {
    switch (type) {
      case SyncErrorType.offline:
        return 'No internet connection. Data saved locally.';
      case SyncErrorType.timeout:
        return 'Connection timed out. Will retry when connection improves.';
      case SyncErrorType.serverError:
        return 'Server error. Please try again later.';
      case SyncErrorType.dataError:
        return 'Data error during sync. Local data is safe.';
      case SyncErrorType.unknown:
        return 'Sync failed. Your local data is safe.';
    }
  }
}

class SyncResult {
  final bool success;
  final SyncErrorType? errorType;
  final String? errorMessage;

  SyncResult.success() : success = true, errorType = null, errorMessage = null;
  SyncResult.failure(this.errorType, this.errorMessage) : success = false;
}

class SyncService {
  final String baseUrl;
  final ProductRepository _productRepository;
  final SaleRepository _saleRepository;
  final RefundRepository _refundRepository;
  final KhataRepository _khataRepository;
  final ConnectivityService _connectivity;

  static const _requestTimeout = Duration(seconds: 12);
  static const _backupTimeout = Duration(seconds: 25);
  static const _maxRetries = 2;

  SyncService({
    required this.baseUrl,
    required ProductRepository productRepository,
    required SaleRepository saleRepository,
    required RefundRepository refundRepository,
    required KhataRepository khataRepository,
    required ConnectivityService connectivity,
  })  : _productRepository = productRepository,
        _saleRepository = saleRepository,
        _refundRepository = refundRepository,
        _khataRepository = khataRepository,
        _connectivity = connectivity;

  Future<SyncResult> _post(
    String path,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    if (_connectivity.isOffline) {
      return SyncResult.failure(SyncErrorType.offline, 'Device is offline');
    }

    final effectiveTimeout = timeout ?? _requestTimeout;
    int attempt = 0;

    while (attempt <= _maxRetries) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl$path'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(effectiveTimeout);

        if (response.statusCode == 200) return SyncResult.success();
        if (response.statusCode >= 500) {
          return SyncResult.failure(
            SyncErrorType.serverError,
            'Server returned ${response.statusCode}',
          );
        }
        return SyncResult.failure(
          SyncErrorType.serverError,
          'Unexpected status ${response.statusCode}',
        );
      } on TimeoutException {
        if (attempt == _maxRetries) {
          return SyncResult.failure(SyncErrorType.timeout, 'Request timed out after $effectiveTimeout');
        }
      } on SocketException catch (e) {
        return SyncResult.failure(SyncErrorType.offline, e.message);
      } on HandshakeException catch (e) {
        return SyncResult.failure(SyncErrorType.serverError, 'SSL error: ${e.message}');
      } catch (e) {
        if (attempt == _maxRetries) {
          debugPrint('[SyncService] $path failed: $e');
          return SyncResult.failure(SyncErrorType.unknown, e.toString());
        }
      }
      attempt++;
      await Future.delayed(Duration(seconds: attempt * 2));
    }

    return SyncResult.failure(SyncErrorType.unknown, 'Max retries exceeded');
  }

  Future<SyncResult> syncProducts() async {
    try {
      final products = await _productRepository.getAll();
      return _post('/sync/products', {
        'products': products.map((p) => p.toMap()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SyncService] syncProducts data error: $e');
      return SyncResult.failure(SyncErrorType.dataError, e.toString());
    }
  }

  Future<SyncResult> syncSales(DateTime? since) async {
    try {
      final sales = await _saleRepository.getAll();
      final filtered = since != null
          ? sales.where((s) => s.createdAt.isAfter(since)).toList()
          : sales;
      return _post('/sync/sales', {
        'sales': filtered.map((s) => s.toMap()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SyncService] syncSales data error: $e');
      return SyncResult.failure(SyncErrorType.dataError, e.toString());
    }
  }

  Future<SyncResult> syncRefunds(DateTime? since) async {
    try {
      final refunds = await _refundRepository.getAll();
      final filtered = since != null
          ? refunds.where((r) => r.createdAt.isAfter(since)).toList()
          : refunds;
      return _post('/sync/refunds', {
        'refunds': filtered.map((r) => r.toMap()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SyncService] syncRefunds data error: $e');
      return SyncResult.failure(SyncErrorType.dataError, e.toString());
    }
  }

  Future<SyncResult> syncKhata() async {
    try {
      final customers = await _khataRepository.getAllCustomers();
      final entries = await _khataRepository.getAllEntries();
      final payments = await _khataRepository.getAllPayments();

      return _post('/sync/khata', {
        'customers': customers.map((c) => c.toMap()).toList(),
        'entries': entries.map((e) => e.toMap()).toList(),
        'payments': payments.map((p) => p.toMap()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SyncService] syncKhata data error: $e');
      return SyncResult.failure(SyncErrorType.dataError, e.toString());
    }
  }

  Future<SyncResult> fullSync() async {
    if (_connectivity.isOffline) {
      return SyncResult.failure(SyncErrorType.offline, 'Device is offline');
    }

    final productResult = await syncProducts();
    if (!productResult.success) return productResult;

    final salesResult = await syncSales(null);
    if (!salesResult.success) return salesResult;

    final refundsResult = await syncRefunds(null);
    if (!refundsResult.success) return refundsResult;

    return syncKhata();
  }

  Future<Map<String, dynamic>?> getBackupData() async {
    try {
      final products = await _productRepository.getAll();
      final sales = await _saleRepository.getAll();
      final refunds = await _refundRepository.getAll();
      final khataCustomers = await _khataRepository.getAllCustomers();
      final khataEntries = await _khataRepository.getAllEntries();
      final khataPayments = await _khataRepository.getAllPayments();

      return {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'products': products.map((p) => p.toMap()).toList(),
        'sales': sales.map((s) => s.toMap()).toList(),
        'refunds': refunds.map((r) => r.toMap()).toList(),
        'khata': {
          'customers': khataCustomers.map((c) => c.toMap()).toList(),
          'entries': khataEntries.map((e) => e.toMap()).toList(),
          'payments': khataPayments.map((p) => p.toMap()).toList(),
        },
      };
    } catch (e) {
      debugPrint('[SyncService] getBackupData error: $e');
      return null;
    }
  }

  Future<SyncResult> uploadBackup(Map<String, dynamic> backup) async {
    return _post('/backup/upload', backup, timeout: _backupTimeout);
  }

  Future<bool> restoreBackup(Map<String, dynamic> backup) async {
    try {
      return backup.containsKey('products') &&
          backup.containsKey('sales') &&
          backup.containsKey('refunds');
    } catch (e) {
      debugPrint('[SyncService] restoreBackup error: $e');
      return false;
    }
  }
}
