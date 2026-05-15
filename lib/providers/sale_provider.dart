import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/repositories/sale_repository.dart';
import '../core/repositories/customer_repository.dart';

final saleRepositoryProvider = Provider((ref) => SaleRepository());
final customerRepositoryProvider = Provider((ref) => CustomerRepository());

