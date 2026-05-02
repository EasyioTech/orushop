import 'package:flutter/material.dart';
import '../widgets/fullscreen_onboarding_page.dart';

class OnboardingScreen14 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingScreen14({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return FullscreenOnboardingPage(
      onBack: onBack,
      title: "Upload profile photo",
      subtitle: "Take a new photo or upload from your library to set your profile photo.",
      primaryButtonText: 'Select photo',
      secondaryButtonText: 'Take photo',
      onPrimaryAction: onNext,
      onSecondaryAction: onNext,
      content: Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person, size: 100, color: Colors.grey[400]),
        ),
      ),
    );
  }
}
