import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'firebase_options.dart';

import 'core/database/database_helper.dart';
import 'core/router/app_router.dart';
import 'core/widgets/error_boundary.dart';
import 'core/services/revenue_cat_service.dart';
import 'providers/shared_prefs_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  debugPrint('App starting...');
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('Initializing SharedPreferences...');
  final prefs = await SharedPreferences.getInstance();

  debugPrint('Initializing Firebase...');
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      debugPrint('Firebase init error: $e');
    }
  }

  debugPrint('Initializing Database...');
  await DatabaseHelper().database;

  debugPrint('Initializing SharedPrefs Provider...');
  initializeSharedPrefs(prefs);

  debugPrint('Initializing Crashlytics...');
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);

  FlutterError.onError = (errorDetails) {
    final hasConsent = prefs.getBool('analytics_consent_v1') ?? false;
    if (hasConsent) {
      FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
    }
  };

  debugPrint('Running App...');
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize RevenueCat when the user signs in
    ref.listenManual(authStateProvider, (previous, next) async {
      final user = next.value;
      if (user != null) {
        try {
          final isTestMode = await ref.read(revenueCatTestModeProvider.future);
          ref.read(revenueCatServiceProvider).initialize(user.uid, testMode: isTestMode);
        } catch (_) {
          ref.read(revenueCatServiceProvider).initialize(user.uid, testMode: true);
        }
      }
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'OruShops',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) => ErrorBoundary(child: child!),
    );
  }
}
