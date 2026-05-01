import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/repositories/analytics_repository.dart';

final analyticsRepositoryProvider = Provider((ref) => AnalyticsRepository());

final dailySalesTotalProvider =
    FutureProvider.family<DailySalesTotal, DateTime>((ref, date) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getDailySalesTotal(date);
});

final topProductsProvider = FutureProvider<List<TopProduct>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getTopProductsLast30Days();
});

final lowStockProductsProvider =
    FutureProvider.family<List<LowStockProduct>, int>((ref, threshold) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getLowStockProducts(threshold);
});

final expiringBatchesProvider =
    FutureProvider.family<List<ExpiringBatch>, int>((ref, alertDays) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getExpiringBatches(alertDays);
});

final salesHistoryProvider = FutureProvider.family<List<SalesHistoryItem>, ({int limit, int offset, DateTime? startDate, DateTime? endDate})>(
  (ref, params) async {
    final repository = ref.watch(analyticsRepositoryProvider);
    return repository.getSalesHistory(
      limit: params.limit,
      offset: params.offset,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  },
);

final saleDetailProvider =
    FutureProvider.family<SaleDetail?, int>((ref, saleId) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getSaleDetail(saleId);
});

final salesTrendProvider = FutureProvider.family<List<DailySalesData>, ({DateTime start, DateTime end})>(
  (ref, params) async {
    final repository = ref.watch(analyticsRepositoryProvider);
    return repository.getSalesTrend(params.start, params.end);
  },
);

final periodAnalyticsProvider = FutureProvider.family<PeriodAnalytics, ({DateTime start, DateTime end})>(
  (ref, params) async {
    final repository = ref.watch(analyticsRepositoryProvider);
    return repository.getPeriodAnalytics(params.start, params.end);
  },
);

final paymentBreakdownProvider = FutureProvider.family<List<PaymentMethodBreakdown>, ({DateTime start, DateTime end})>(
  (ref, params) async {
    final repository = ref.watch(analyticsRepositoryProvider);
    return repository.getPaymentMethodBreakdown(params.start, params.end);
  },
);
