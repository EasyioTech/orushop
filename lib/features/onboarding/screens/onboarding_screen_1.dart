import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/shared_prefs_provider.dart';
import '../widgets/onboarding_page.dart';

class OnboardingScreen1 extends ConsumerWidget {
  final VoidCallback onNext;

  const OnboardingScreen1({
    super.key,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingPage(
      currentStep: 1,
      totalSteps: 6,
      title: 'Welcome to OruShops',
      description: 'The smartest offline-first POS system for your retail business. Empower your store with real-time data and seamless checkouts.',
      illustration: Image.asset(
        'images/logo.png',
        fit: BoxFit.contain,
      ),
      nextButtonText: 'Get Started',
      showBackButton: false,
      onNext: () {
        final prefs = ref.read(sharedPreferencesProvider);
        prefs.setBool('privacy_policy_accepted_v1', true);
        prefs.setBool('terms_of_service_accepted_v1', true);
        onNext();
      },
      illustrationFlex: 6,
      contentFlex: 4,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, color: AppTheme.accentColor, size: 12),
            const SizedBox(width: 4),
            Text(
              'Now with Offline Mode',
              style: TextStyle(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
