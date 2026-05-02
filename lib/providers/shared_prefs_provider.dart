import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences _sharedPrefsInstance;

void initializeSharedPrefs(SharedPreferences prefs) {
  _sharedPrefsInstance = prefs;
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  return _sharedPrefsInstance;
});
