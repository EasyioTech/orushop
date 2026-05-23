import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/products_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/cart_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/models/product.dart';
import '../../core/models/sale.dart';
import '../../core/models/sale_item.dart';
import '../../core/widgets/error_boundary.dart';
import '../../providers/khata_provider.dart';

import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/products_screen.dart';
import '../../presentation/screens/inventory_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/receipt_screen.dart';
import '../../presentation/screens/edit_product_screen.dart';
import '../../features/khata/screens/khata_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/onboarding/screens/onboarding_flow_screen.dart';
import '../../features/inventory/screens/create_product/create_product_screen.dart';
import '../../features/inventory/screens/create_service/create_service_screen.dart';
import '../../features/inventory/screens/service_detail_screen.dart';
import '../../features/inventory/screens/service_categories_screen.dart';
import '../../features/staff/screens/staff_list_screen.dart';
import '../../features/staff/screens/create_staff_screen.dart';
import '../../features/staff/screens/staff_detail_screen.dart';


// Route name constants — use these everywhere instead of raw strings
abstract class AppRoutes {
  static const splash      = '/';
  static const login       = '/login';
  static const onboarding  = '/onboarding';
  static const home        = '/home';
  static const pos         = '/pos';
  static const posReceipt  = 'receipt';       // relative — full path: /pos/receipt
  static const stock       = '/stock';
  static const stockCreate = 'create';        // relative — full path: /stock/create
  static const stockCreateService = 'create-service'; // relative — full path: /stock/create-service
  static const stockEdit   = 'edit';          // relative — full path: /stock/edit
  static const stockEditService = 'edit-service'; // relative — full path: /stock/edit-service
  static const stockServiceDetail = 'service/:id'; // relative — full path: /stock/service/:id
  static const staff       = '/staff';
  static const staffCreate = 'create';        // relative — full path: /staff/create
  static const staffDetail = ':staffId';      // relative — full path: /staff/:staffId
  static const serviceCategories = '/service-categories';
  static const khata       = '/khata';
  static const profile     = '/profile';
}

// go_router integration with Riverpod — listens to auth + onboarding state
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider,   (prev, next) => notifyListeners());
    _ref.listen(onboardingProvider,  (prev, next) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync   = _ref.read(authStateProvider);
    final onboarding  = _ref.read(onboardingProvider);
    final loc         = state.matchedLocation;

    // While Firebase Auth is still initializing, stay on the splash screen
    if (authAsync.isLoading) {
      return loc == AppRoutes.splash ? null : AppRoutes.splash;
    }

    // Onboarding not done → force /onboarding
    if (!onboarding.isCompleted) {
      return loc == AppRoutes.onboarding ? null : AppRoutes.onboarding;
    }

    final isLoggedIn = authAsync.value != null;

    // Not authenticated → /login
    if (!isLoggedIn) {
      return loc == AppRoutes.login ? null : AppRoutes.login;
    }

    // Authenticated — get off splash/login/onboarding
    if (loc == AppRoutes.splash ||
        loc == AppRoutes.login  ||
        loc == AppRoutes.onboarding) {
      return AppRoutes.home;
    }

    return null; // no redirect needed
  }
}

// --------------------------------------------------------------------------
// Route argument types — typed extras for routes that need data
// --------------------------------------------------------------------------

class ReceiptRouteArgs {
  final Sale sale;
  final List<SaleItem> items;
  final String? storeName;
  final String? storePhone;
  final String? storeAddress;
  final String? upiId;

  const ReceiptRouteArgs({
    required this.sale,
    required this.items,
    this.storeName,
    this.storePhone,
    this.storeAddress,
    this.upiId,
  });
}

// --------------------------------------------------------------------------
// Router provider — single GoRouter instance shared across the app
// --------------------------------------------------------------------------

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: false,
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
    routes: [
      // ── Splash (shown while Firebase Auth resolves) ──────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),

      // ── Auth ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingFlowScreen(),
      ),
      GoRoute(
        path: AppRoutes.staff,
        builder: (context, state) => const StaffListScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.staffCreate,
            builder: (context, state) => const CreateStaffScreen(),
          ),
          GoRoute(
            path: AppRoutes.staffDetail,
            builder: (context, state) {
              final idStr = state.pathParameters['staffId'] ?? '';
              final id = int.tryParse(idStr) ?? 0;
              return StaffDetailScreen(staffId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.serviceCategories,
        builder: (context, state) => const ServiceCategoriesScreen(),
      ),

      // ── Main shell (bottom nav with StatefulShellRoute) ──────────────────
      // StatefulShellRoute.indexedStack preserves each branch's scroll/state
      // — same behaviour as the old IndexedStack in MyHomePage, but with
      // proper named routing and deep-link support on top.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _AppShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0 — Home
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ]),

          // Tab 1 — POS
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.pos,
              builder: (context, state) => const ProductsScreen(),
              routes: [
                GoRoute(
                  path: AppRoutes.posReceipt,
                  builder: (context, state) {
                    final args = state.extra as ReceiptRouteArgs;
                    return ReceiptScreen(
                      sale: args.sale,
                      items: args.items,
                      storeName: args.storeName,
                      storePhone: args.storePhone,
                      storeAddress: args.storeAddress,
                      upiId: args.upiId,
                    );
                  },
                ),
              ],
            ),
          ]),

          // Tab 2 — Stock / Inventory
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.stock,
              builder: (context, state) => const InventoryScreen(),
              routes: [
                GoRoute(
                  path: AppRoutes.stockCreate,
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const CreateProductScreen(),
                ),
                GoRoute(
                  path: AppRoutes.stockCreateService,
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const CreateServiceScreen(),
                ),
                GoRoute(
                  path: AppRoutes.stockEdit,
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final product = state.extra as Product;
                    return EditProductScreen(product: product);
                  },
                ),
                GoRoute(
                  path: AppRoutes.stockEditService,
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final product = state.extra as Product;
                    return CreateServiceScreen(editProduct: product);
                  },
                ),
                GoRoute(
                  path: AppRoutes.stockServiceDetail,
                  builder: (context, state) {
                    final idStr = state.pathParameters['id'] ?? '';
                    final id = int.tryParse(idStr) ?? 0;
                    return ServiceDetailScreen(serviceId: id);
                  },
                ),
              ],
            ),
          ]),

          // Tab 3 — Khata
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.khata,
              builder: (context, state) => const KhataScreen(),
            ),
          ]),

          // Tab 4 — Profile
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});

// --------------------------------------------------------------------------
// Shell scaffold — replaces MyHomePage; wraps each tab with the bottom nav
// --------------------------------------------------------------------------

class _AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const _AppShell({required this.navigationShell});

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> with WidgetsBindingObserver {
  static const _navItems = [
    _NavItem(label: 'Home',    icon: CupertinoIcons.house,          activeIcon: CupertinoIcons.house_fill,          activeColor: AppTheme.primaryColor),
    _NavItem(label: 'POS',     icon: CupertinoIcons.cart,           activeIcon: CupertinoIcons.cart_fill,           activeColor: Color(0xFF10B981)),
    _NavItem(label: 'Stock',   icon: CupertinoIcons.cube_box,       activeIcon: CupertinoIcons.cube_box_fill,       activeColor: Color(0xFF6D28D9)),
    _NavItem(label: 'Khata',   icon: CupertinoIcons.book,           activeIcon: CupertinoIcons.book_fill,           activeColor: Color(0xFFB45309)),
    _NavItem(label: 'Profile', icon: CupertinoIcons.person_circle,  activeIcon: CupertinoIcons.person_circle_fill,  activeColor: Color(0xFF3B82F6)),
  ];

  bool _isNavBarVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Auto-refresh data silently when app returns to foreground
      ref.read(analyticsRevisionProvider.notifier).state++;
      ref.read(paginatedProductsProvider.notifier).silentRefresh();
      ref.invalidate(productsProvider);
      ref.read(khataListProvider.notifier).load();
    }
  }

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    HapticFeedback.selectionClick();
    FocusManager.instance.primaryFocus?.unfocus();

    // Tapping the active tab scrolls back to top (standard mobile UX)
    // Tapping a different tab switches to that branch, restoring its state
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );

    // Keep the same auto-refresh logic as before, but use silent updates where possible
    if (index == 1) {
      ref.read(paginatedProductsProvider.notifier).silentRefresh();
    } else if (index == 2) {
      ref.read(paginatedProductsProvider.notifier).silentRefresh();
      ref.read(analyticsRevisionProvider.notifier).state++;
    } else if (index == 0) {
      ref.read(analyticsRevisionProvider.notifier).state++;
    } else if (index == 3) {
      ref.read(khataListProvider.notifier).load();
    }
  }

  void _handleSwipe(DragEndDetails details, int currentIndex) {
    if (details.primaryVelocity == null) return;
    
    // threshold for swipe speed to avoid accidental touches
    const double threshold = 300.0;
    int nextIndex = currentIndex;

    // primaryVelocity < 0 means swiping left (moving to the right tab)
    if (details.primaryVelocity! < -threshold) {
      nextIndex = currentIndex + 1;
    } 
    // primaryVelocity > 0 means swiping right (moving to the left tab)
    else if (details.primaryVelocity! > threshold) {
      nextIndex = currentIndex - 1;
    }

    if (nextIndex != currentIndex && nextIndex >= 0 && nextIndex < _AppShellState._navItems.length) {
      _onTap(context, ref, nextIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(isOfflineProvider);
    final currentIndex = widget.navigationShell.currentIndex;
    final cartItems = ref.watch(cartProvider);
    final isMakingSale = currentIndex == 1 && cartItems.isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (currentIndex != 0) {
          widget.navigationShell.goBranch(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        body: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction == ScrollDirection.forward) {
              if (!_isNavBarVisible) setState(() => _isNavBarVisible = true);
            } else if (notification.direction == ScrollDirection.reverse) {
              if (_isNavBarVisible) setState(() => _isNavBarVisible = false);
            }
            return false;
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) => _handleSwipe(details, currentIndex),
            child: OfflineBanner(
              isOffline: isOffline,
              child: widget.navigationShell,
            ),
          ),
        ),
        bottomNavigationBar: isMakingSale
            ? null
            : AnimatedSlide(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                offset: _isNavBarVisible ? Offset.zero : const Offset(0, 1.5),
                child: RepaintBoundary(
                  child: _AppNavBar(
                    selectedIndex: currentIndex,
                    items: _AppShellState._navItems,
                    onTap: (i) => _onTap(context, ref, i),
                  ),
                ),
              ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Splash screen — shown while Firebase Auth cold-starts
// --------------------------------------------------------------------------

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.accentColor),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Nav bar widgets (identical visual to old _AppNavBar / _NavBarItem)
// --------------------------------------------------------------------------

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color activeColor;
  const _NavItem({
    required this.label, 
    required this.icon, 
    required this.activeIcon,
    required this.activeColor,
  });
}

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

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (i) {
                return Expanded(
                  child: _NavBarItem(
                    item: items[i],
                    active: i == selectedIndex,
                    onTap: () => onTap(i),
                  ),
                );
              }),
            ),
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
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          padding: EdgeInsets.symmetric(
            horizontal: active ? 16 : 8,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: active
                ? item.activeColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Icon(
                  active ? item.activeIcon : item.icon,
                  key: ValueKey(active),
                  size: active ? 26 : 24,
                  color: active
                      ? item.activeColor
                      : AppTheme.textSecondary.withValues(alpha: 0.4),
                ),
              ),
              if (active) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: item.activeColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
