import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/error_boundary.dart';
import 'core/database/database_helper.dart';
import 'core/models/product.dart';
import 'presentation/screens/analytics_screen.dart';
import 'presentation/screens/cart_screen.dart';
import 'presentation/screens/inventory_screen.dart';
import 'presentation/screens/products_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'providers/cart_provider.dart' show initializeSharedPrefs, sharedPreferencesProvider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  initializeSharedPrefs(prefs);

  // Seed sample data if products table is empty
  await _seedSampleDataIfEmpty();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _seedSampleDataIfEmpty() async {
  final dbHelper = DatabaseHelper();
  final db = await dbHelper.database;

  final count = await db.rawQuery('SELECT COUNT(*) as count FROM products');
  final productCount = (count.first['count'] as int?) ?? 0;

  if (productCount == 0) {
    final now = DateTime.now();
    final sampleProducts = [
      Product(id: 1, name: 'Apparel - Cotton T-Shirt', sku: 'APPL-001', price: 299, quantity: 50, category: 'Apparel', createdAt: now, updatedAt: now),
      Product(id: 2, name: 'Electronics - USB Cable', sku: 'ELEC-001', price: 149, quantity: 100, category: 'Electronics', createdAt: now, updatedAt: now),
      Product(id: 3, name: 'Accessories - Phone Case', sku: 'ACC-001', price: 199, quantity: 75, category: 'Accessories', createdAt: now, updatedAt: now),
      Product(id: 4, name: 'Electronics - Power Bank', sku: 'ELEC-002', price: 899, quantity: 30, category: 'Electronics', createdAt: now, updatedAt: now),
      Product(id: 5, name: 'Apparel - Jeans', sku: 'APPL-002', price: 1499, quantity: 25, category: 'Apparel', createdAt: now, updatedAt: now),
      Product(id: 6, name: 'Home - LED Lamp', sku: 'HOME-001', price: 599, quantity: 40, category: 'Home', createdAt: now, updatedAt: now),
      Product(id: 7, name: 'Sports - Water Bottle', sku: 'SPORT-001', price: 399, quantity: 60, category: 'Sports', createdAt: now, updatedAt: now),
      Product(id: 8, name: 'Beauty - Face Wash', sku: 'BEAUTY-001', price: 249, quantity: 80, category: 'Beauty', createdAt: now, updatedAt: now),
    ];

    for (final product in sampleProducts) {
      await db.insert('products', product.toMap());
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RetailDost',
      theme: AppTheme.lightTheme,
      home: const MyHomePage(),
      builder: (context, child) {
        return ErrorBoundary(child: child!);
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  List<Widget> _buildScreens(BuildContext context) => [
    const ProductsScreen(),
    const CartScreen(),
    const InventoryScreen(),
    const AnalyticsScreen(),
    const SettingsScreen(),
  ];

  void _onNavBarTap(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreens(context)[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavBarTap,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: 'Shop',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
