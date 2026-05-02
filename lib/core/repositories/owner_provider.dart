import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'owner_repository.dart';

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {
  return OwnerRepository();
});

final ownerDetailsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repo = ref.watch(ownerRepositoryProvider);
  return repo.getOwnerDetails();
});

final ownerDetailsStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final repo = ref.watch(ownerRepositoryProvider);
  return repo.ownerDetailsStream();
});
