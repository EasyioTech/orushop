import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/order.dart';
import '../core/repositories/order_repository.dart';

final ordersProvider = FutureProvider<List<Order>>((ref) async {
  final repo = OrderRepository();
  return repo.getAll();
});

final pendingOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final repo = OrderRepository();
  return repo.getByStatus('pending');
});

final receivedOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final repo = OrderRepository();
  return repo.getByStatus('received');
});

final orderByIdProvider = FutureProvider.family<Order?, int>((ref, orderId) async {
  final repo = OrderRepository();
  return repo.getById(orderId);
});

