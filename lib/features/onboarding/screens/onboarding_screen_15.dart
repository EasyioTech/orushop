import 'package:flutter/material.dart';
import '../widgets/fullscreen_onboarding_page.dart';

class OnboardingScreen15 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingScreen15({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return FullscreenOnboardingPage(
      onBack: onBack,
      title: "Enable Face ID",
      subtitle: "With Face ID, you won't need to enter your password every time.",
      primaryButtonText: 'Enable',
      secondaryButtonText: 'Do this later',
      onPrimaryAction: onNext,
      onSecondaryAction: onNext,
      content: Center(
        child: Icon(
          Icons.face_retouching_natural_outlined,
          size: 120,
          color: Colors.grey[300],
        ),
      ),
    );
  }
}
