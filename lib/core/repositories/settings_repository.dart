import '../database/database_helper.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> save(AppSettings settings) async {
    final db = await _dbHelper.database;
    final existing = await db.query('app_settings', limit: 1);

    if (existing.isEmpty) {
      await db.insert('app_settings', settings.toMap());
    } else {
      await db.update(
        'app_settings',
        settings.toMap(),
      );
    }
  }

  Future<AppSettings?> get() async {
    final db = await _dbHelper.database;
    final result = await db.query('app_settings', limit: 1);

    if (result.isEmpty) return null;
    return AppSettings.fromMap(result.first);
  }

  Future<void> updateStoreName(String name) async {
    final settings = await get();
    if (settings != null) {
      await save(settings.copyWith(storeName: name));
    }
  }

  Future<void> updateStorePhone(String phone) async {
    final settings = await get();
    if (settings != null) {
      await save(settings.copyWith(storePhone: phone));
    }
  }

  Future<void> updateStoreAddress(String address) async {
    final settings = await get();
    if (settings != null) {
      await save(settings.copyWith(storeAddress: address));
    }
  }

  Future<void> updateCurrencySymbol(String symbol) async {
    final settings = await get();
    if (settings != null) {
      await save(settings.copyWith(currencySymbol: symbol));
    }
  }

  Future<void> updateEnableDiscounts(bool enabled) async {
    final settings = await get();
    if (settings != null) {
      await save(settings.copyWith(enableDiscounts: enabled));
    }
  }

  Future<void> updateEnableUpi(bool enabled) async {
    final settings = await get();
    if (settings != null) {
      await save(settings.copyWith(enableUpi: enabled));
    }
  }

  Future<void> updateDefaultDiscountPercent(double percent) async {
    final settings = await get();
    if (settings != null) {
      await save(settings.copyWith(defaultDiscountPercent: percent));
    }
  }

  Future<void> updateLastSyncTime(DateTime time) async {
    final settings = await get();
    if (settings != null) {
      await save(settings.copyWith(lastSyncTime: time));
    }
  }
}
