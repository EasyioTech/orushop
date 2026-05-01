import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/repositories/sale_repository.dart';

final saleRepositoryProvider = Provider((ref) => SaleRepository());
