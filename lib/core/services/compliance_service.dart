import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../providers/shared_prefs_provider.dart';

final complianceServiceProvider = Provider((ref) => ComplianceService(
  ref.watch(sharedPreferencesProvider),
));

class ComplianceService {
  final SharedPreferences _prefs;
  static const String _privacyAcceptedKey = 'privacy_policy_accepted_v1';
  static const String _termsAcceptedKey = 'terms_of_service_accepted_v1';
  static const String _analyticsConsentKey = 'analytics_consent_v1';

  ComplianceService(this._prefs);

  bool get hasAcceptedPrivacy => _prefs.getBool(_privacyAcceptedKey) ?? false;
  bool get hasAcceptedTerms => _prefs.getBool(_termsAcceptedKey) ?? false;
  bool get hasAnalyticsConsent => _prefs.getBool(_analyticsConsentKey) ?? false;

  Future<void> acceptPrivacy() async {
    await _prefs.setBool(_privacyAcceptedKey, true);
  }

  Future<void> acceptTerms() async {
    await _prefs.setBool(_termsAcceptedKey, true);
  }

  Future<void> acceptAnalytics(bool consent) async {
    await _prefs.setBool(_analyticsConsentKey, consent);
    // Enable or disable Crashlytics collection based on consent
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(consent);
  }

  bool isComplianceComplete() => hasAcceptedPrivacy && hasAcceptedTerms;

  Future<void> launchPrivacyPolicy() async {
    final url = Uri.parse('https://orushops.com/privacy');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> launchTermsOfService() async {
    final url = Uri.parse('https://orushops.com/terms');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> requestDataDeletion(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.orushops.com/api/users/$userId/request-deletion'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: jsonEncode({'userId': userId, 'requestedAt': DateTime.now().toIso8601String()}),
      );
      if (response.statusCode != 200) {
        throw Exception('Data deletion request failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Failed to retrieve auth token');
    }
    return token;
  }
}
