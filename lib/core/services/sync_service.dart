import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../repositories/product_repository.dart';
import '../repositories/sale_repository.dart';
import '../repositories/refund_repository.dart';

class SyncService {
  final String baseUrl;
  final ProductRepository _productRepository;
  final SaleRepository _saleRepository;
  final RefundRepository _refundRepository;

  SyncService({
    required this.baseUrl,
    required ProductRepository productRepository,
    required SaleRepository saleRepository,
    required RefundRepository refundRepository,
  })  : _productRepository = productRepository,
        _saleRepository = saleRepository,
        _refundRepository = refundRepository;

  Future<bool> syncProducts() async {
    try {
      final products = await _productRepository.getAll();
      final response = await http.post(
        Uri.parse('$baseUrl/sync/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'products': products.map((p) => p.toMap()).toList(),
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 30));
      return response.statusCode == 200;
    } on TimeoutException {
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> syncSales(DateTime? since) async {
    try {
      final sales = await _saleRepository.getAll();
      final filtered = since != null
          ? sales.where((s) => s.createdAt.isAfter(since)).toList()
          : sales;

      final response = await http.post(
        Uri.parse('$baseUrl/sync/sales'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sales': filtered.map((s) => s.toMap()).toList(),
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 30));
      return response.statusCode == 200;
    } on TimeoutException {
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> syncRefunds(DateTime? since) async {
    try {
      final refunds = await _refundRepository.getAll();
      final filtered = since != null
          ? refunds.where((r) => r.createdAt.isAfter(since)).toList()
          : refunds;

      final response = await http.post(
        Uri.parse('$baseUrl/sync/refunds'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refunds': filtered.map((r) => r.toMap()).toList(),
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 30));
      return response.statusCode == 200;
    } on TimeoutException {
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> fullSync() async {
    try {
      final productSync = await syncProducts();
      final salesSync = await syncSales(null);
      final refundsSync = await syncRefunds(null);

      return productSync && salesSync && refundsSync;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getBackupData() async {
    try {
      final products = await _productRepository.getAll();
      final sales = await _saleRepository.getAll();
      final refunds = await _refundRepository.getAll();

      return {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'products': products.map((p) => p.toMap()).toList(),
        'sales': sales.map((s) => s.toMap()).toList(),
        'refunds': refunds.map((r) => r.toMap()).toList(),
      };
    } catch (e) {
      return null;
    }
  }

  Future<bool> uploadBackup(Map<String, dynamic> backup) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/backup/upload'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(backup),
      ).timeout(const Duration(seconds: 60));
      return response.statusCode == 200;
    } on TimeoutException {
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> restoreBackup(Map<String, dynamic> backup) async {
    try {
      if (!backup.containsKey('products') ||
          !backup.containsKey('sales') ||
          !backup.containsKey('refunds')) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
