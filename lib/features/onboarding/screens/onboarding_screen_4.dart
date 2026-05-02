import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/onboarding_provider.dart';
import '../widgets/fullscreen_onboarding_page.dart';

class OnboardingScreen4 extends ConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingScreen4({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(onboardingProvider).emailOrPhone ?? 'some@email.com';

    return FullscreenOnboardingPage(
      onBack: onBack,
      icon: const Icon(
        Icons.send_outlined,
        color: AppTheme.textSecondary,
        size: 32,
      ),
      title: "Confirm your email address",
      subtitle: "Check your inbox and tap the link in the email we've just sent to:",
      primaryButtonText: 'Open email app',
      onPrimaryAction: onNext, // Mock transition for now
      content: Center(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              email,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 48),
            Text(
              "Didn't receive an email?",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            TextButton(
              onPressed: () {
                // Resend link logic
              },
              child: const Text(
                "Resend link",
                style: TextStyle(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
