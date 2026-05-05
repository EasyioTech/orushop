import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/database/database_helper.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/home_screen.dart';
import 'core/widgets/error_boundary.dart';
import 'core/services/auth_service.dart';
import 'core/services/revenue_cat_service.dart';
import 'features/khata/screens/khata_screen.dart';
import 'presentation/screens/inventory_screen.dart';
import 'presentation/screens/products_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'features/onboarding/screens/onboarding_flow_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'providers/shared_prefs_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/navigation_provider.dart';
import 'core/providers/connectivity_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final results = await Future.wait([
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
    SharedPreferences.getInstance(),
    DatabaseHelper().database,
  ]);

  final prefs = results[1] as SharedPreferences;
  initializeSharedPrefs(prefs);

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
    // Initialize RevenueCat once when a user is first detected, not on every rebuild.
    ref.listenManual(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          ref.read(revenueCatServiceProvider).initialize(user.uid);
        }
      });
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final onboarding = ref.watch(onboardingProvider);

    // If onboarding is not completed, we always show the onboarding flow.
    // The onboarding flow itself handles the login/signup step.
    if (!onboarding.isCompleted) {
      return MaterialApp(
        title: 'OruShops',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const OnboardingFlowScreen(),
        builder: (context, child) => ErrorBoundary(child: child!),
      );
    }

    // If onboarding IS completed, we follow the standard auth flow.
    return MaterialApp(
      title: 'OruShops',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.when(
        data: (user) {
          if (user == null) return const LoginScreen();
          return const MyHomePage();
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.accentColor),
          ),
        ),
        error: (e, _) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 64),
                const SizedBox(height: 16),
                Text('Something went wrong', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(e.toString(), style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(authStateProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      builder: (context, child) {
        return ErrorBoundary(child: child!);
      },
    );
  }
}


class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  static const _navItems = [
    _NavItem(label: 'Home',    icon: Icons.home_outlined,          activeIcon: Icons.home_rounded),
    _NavItem(label: 'POS',     icon: Icons.storefront_outlined,    activeIcon: Icons.storefront_rounded),
    _NavItem(label: 'Stock',   icon: Icons.inventory_2_outlined,   activeIcon: Icons.inventory_2_rounded),
    _NavItem(label: 'Khata',   icon: Icons.book_outlined,          activeIcon: Icons.book_rounded),
    _NavItem(label: 'Profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded),
  ];

  List<Widget> _buildScreens() => const [
    HomeScreen(),
    ProductsScreen(),
    InventoryScreen(),
    KhataScreen(),
    ProfileScreen(),
  ];

  void _onNavTap(int index) {
    HapticFeedback.selectionClick();
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(navigationIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    final screens = _buildScreens();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (selectedIndex != 0) {
          ref.read(navigationIndexProvider.notifier).state = 0;
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: _OfflineAwareBody(selectedIndex: selectedIndex, screens: screens),
        bottomNavigationBar: _AppNavBar(
          selectedIndex: selectedIndex,
          items: _navItems,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}

class _OfflineAwareBody extends ConsumerWidget {
  final int selectedIndex;
  final List<Widget> screens;

  const _OfflineAwareBody({required this.selectedIndex, required this.screens});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    return OfflineBanner(
      isOffline: isOffline,
      child: IndexedStack(index: selectedIndex, children: screens),
    );
  }
}

// ── Nav data ─────────────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem({required this.label, required this.icon, required this.activeIcon});
}

// ── Custom bottom nav ─────────────────────────────────────────────────────────

class _AppNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _AppNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final active = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: _NavBarItem(item: item, active: active),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool active;

  const _NavBarItem({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Icon(
              active ? item.activeIcon : item.icon,
              key: ValueKey(active),
              size: 22,
              color: active ? AppTheme.primaryColor : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppTheme.primaryColor : const Color(0xFF94A3B8),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 18 : 0,
            height: 2,
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}
