import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_helper.dart';
import '../core/database/table_constants.dart';
import '../core/models/khata_customer.dart';
import '../core/models/khata_entry.dart';
import '../core/models/sale.dart';
import '../core/repositories/khata_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final khataRepositoryProvider = Provider<KhataRepository>((ref) {
  return KhataRepository(DatabaseHelper());
});

// ── Customer list state ───────────────────────────────────────────────────────

class KhataListState {
  final List<KhataCustomer> customers;
  final Map<String, double> summary;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const KhataListState({
    this.customers = const [],
    this.summary = const {},
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  KhataListState copyWith({
    List<KhataCustomer>? customers,
    Map<String, double>? summary,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) =>
      KhataListState(
        customers: customers ?? this.customers,
        summary: summary ?? this.summary,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

class KhataListNotifier extends Notifier<KhataListState> {
  KhataRepository get _repo => ref.read(khataRepositoryProvider);

  @override
  KhataListState build() {
    Future.microtask(load);
    return const KhataListState();
  }

  Future<void> load({String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final customers = await _repo.getAllCustomers(search: search ?? state.searchQuery);
      final summary = await _repo.getOverallSummary();
      state = state.copyWith(customers: customers, summary: summary, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query);
    await load(search: query);
  }

  Future<bool> addCustomer({
    required String name,
    required String phone,
    String? address,
    String? notes,
    double creditLimit = 0,
  }) async {
    try {
      final now = DateTime.now();
      await _repo.addCustomer(KhataCustomer(
        id: 0,
        name: name,
        phone: phone,
        address: address,
        notes: notes,
        creditLimit: creditLimit,
        createdAt: now,
        updatedAt: now,
      ));
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateCustomer(KhataCustomer customer) async {
    try {
      await _repo.updateCustomer(customer);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteCustomer(int id) async {
    try {
      await _repo.deleteCustomer(id);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final khataListProvider = NotifierProvider<KhataListNotifier, KhataListState>(
  KhataListNotifier.new,
);

// ── Customer detail (ledger) state ────────────────────────────────────────────

class KhataDetailState {
  final KhataCustomer? customer;
  final List<Map<String, dynamic>> ledger;
  final bool isLoading;
  final String? error;

  const KhataDetailState({
    this.customer,
    this.ledger = const [],
    this.isLoading = false,
    this.error,
  });

  KhataDetailState copyWith({
    KhataCustomer? customer,
    List<Map<String, dynamic>>? ledger,
    bool? isLoading,
    String? error,
  }) =>
      KhataDetailState(
        customer: customer ?? this.customer,
        ledger: ledger ?? this.ledger,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class KhataDetailNotifier extends FamilyNotifier<KhataDetailState, int> {
  KhataRepository get _repo => ref.read(khataRepositoryProvider);

  @override
  KhataDetailState build(int arg) {
    Future.microtask(load);
    return const KhataDetailState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final customer = await _repo.getCustomerById(arg);
      final ledger = await _repo.getLedgerForCustomer(arg);
      state = state.copyWith(customer: customer, ledger: ledger, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addEntry({
    required KhataEntryType type,
    required double amount,
    required String description,
  }) async {
    try {
      await _repo.addEntry(
        customerId: arg,
        type: type,
        amount: amount,
        description: description,
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> recordPayment({
    required double amount,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      await _repo.recordPayment(
        customerId: arg,
        amount: amount,
        paymentMethod: paymentMethod,
        notes: notes,
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final khataDetailProvider = NotifierProvider.family<KhataDetailNotifier, KhataDetailState, int>(
  KhataDetailNotifier.new,
);

// ── Sales history for a customer (by phone) ───────────────────────────────────

final customerSalesByPhoneProvider = FutureProvider.family<List<Sale>, String>((ref, phone) async {
  if (phone.isEmpty) return [];
  final db = await DatabaseHelper().database;
  final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
  final result = await db.query(
    TableConstants.sales,
    where: 'customerPhone = ? OR customerPhone = ?',
    whereArgs: [cleanPhone, phone],
    orderBy: 'createdAt DESC',
  );
  return result.map((row) => Sale.fromMap(row)).toList();
});
