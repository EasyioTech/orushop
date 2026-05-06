import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
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

    if (!onboarding.isCompleted) {
      return MaterialApp(
        title: 'OruShops',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const OnboardingFlowScreen(),
        builder: (context, child) => ErrorBoundary(child: child!),
      );
    }

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
                const Icon(CupertinoIcons.exclamationmark_circle, color: AppTheme.errorColor, size: 64),
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
      builder: (context, child) => ErrorBoundary(child: child!),
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
    _NavItem(label: 'Home',    icon: CupertinoIcons.house,          activeIcon: CupertinoIcons.house_fill),
    _NavItem(label: 'POS',     icon: CupertinoIcons.cart,           activeIcon: CupertinoIcons.cart_fill),
    _NavItem(label: 'Stock',   icon: CupertinoIcons.cube_box,       activeIcon: CupertinoIcons.cube_box_fill),
    _NavItem(label: 'Khata',   icon: CupertinoIcons.book,           activeIcon: CupertinoIcons.book_fill),
    _NavItem(label: 'Profile', icon: CupertinoIcons.person_circle, activeIcon: CupertinoIcons.person_circle_fill),
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

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem({required this.label, required this.icon, required this.activeIcon});
}

// ── MINIMALIST ATTACHED NAV BAR ─────────────────────────────────────────────

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
          top: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.8), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final active = i == selectedIndex;
              return Expanded(
                child: _NavBarItem(
                  item: item,
                  active: active,
                  onTap: () => onTap(i),
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
  final VoidCallback onTap;

  const _NavBarItem({required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Icon(
            active ? item.activeIcon : item.icon,
            size: 24,
            color: active ? AppTheme.primaryColor : AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w900 : FontWeight.w600,
              color: active ? AppTheme.primaryColor : AppTheme.textSecondary.withValues(alpha: 0.5),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          // Elegant Bottom Indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: active ? 16 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
