import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/supabase_service.dart';

final supabaseServiceProvider = Provider((ref) => SupabaseService());

final supabaseConnectivityProvider = FutureProvider((ref) async {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.isOnline();
});

final backupProvider = FutureProvider.family<void, String>((ref, userId) async {
  final supabase = ref.watch(supabaseServiceProvider);
  await supabase.backupDatabase(userId);
});

final restoreProvider = FutureProvider.family<void, (String userId, Map<String, dynamic> backup)>((ref, params) async {
  final supabase = ref.watch(supabaseServiceProvider);
  await supabase.restoreDatabase(params.$1, params.$2);
});

final lastBackupProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.getLastBackup(userId);
});

final syncSalesProvider = FutureProvider.family<void, String>((ref, userId) async {
  final supabase = ref.watch(supabaseServiceProvider);
  await supabase.syncSalesData(userId);
});
