import 'dart:async';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Initialize FFI for sqflite in tests
  sqfliteFfiInit();
  
  // Change the default factory to FFI factory
  databaseFactory = databaseFactoryFfi;
  
  // Run tests
  await testMain();
}
