import 'package:flutter/material.dart';
import 'package:orushops/core/theme/app_theme.dart';

class OnboardingStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == (currentStep - 1) % 3;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.accentColor : AppTheme.borderColor,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
