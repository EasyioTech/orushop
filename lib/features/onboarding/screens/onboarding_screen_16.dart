import 'package:flutter/material.dart';
import 'package:orushops/core/theme/app_theme.dart';
import '../widgets/fullscreen_onboarding_page.dart';

class OnboardingScreen16 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingScreen16({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return FullscreenOnboardingPage(
      onBack: onBack,
      title: "Turn on notifications?",
      subtitle: "Don't miss important messages like check-in details and account activity.",
      primaryButtonText: 'Enable notifications',
      secondaryButtonText: 'Skip',
      onPrimaryAction: onNext,
      onSecondaryAction: onNext,
      content: Center(
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notifications_active_outlined,
            size: 100,
            color: AppTheme.accentColor.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
