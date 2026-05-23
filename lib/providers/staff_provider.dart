import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/staff_member.dart';
import '../core/repositories/staff_repository.dart';

final staffRepositoryProvider = Provider((ref) => StaffRepository());

final staffListProvider = FutureProvider<List<StaffMember>>((ref) async {
  final repository = ref.watch(staffRepositoryProvider);
  return repository.getAll();
});

final activeStaffProvider = FutureProvider<List<StaffMember>>((ref) async {
  final repository = ref.watch(staffRepositoryProvider);
  return repository.getActive();
});

final staffByIdProvider = FutureProvider.family<StaffMember?, int>((ref, staffId) async {
  final repository = ref.watch(staffRepositoryProvider);
  return repository.getById(staffId);
});
