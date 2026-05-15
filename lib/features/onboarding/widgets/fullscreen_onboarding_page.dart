import 'package:flutter/material.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'onboarding_step_indicator.dart';

class FullscreenOnboardingPage extends StatelessWidget {
  final String title;
  final String? subtitle; // Also maps to description
  final Widget content;
  final Widget? footer;
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onPrimaryAction; // Also maps to onNext
  final String? primaryButtonText; // Also maps to nextButtonText
  final bool isPrimaryButtonEnabled;
  final bool showBackButton;
  final bool showNextButton;
  final bool showIndicator;
  final VoidCallback? onBack;
  final Widget? headerAction;
  final Widget? icon;

  const FullscreenOnboardingPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.footer,
    this.currentStep = 1,
    this.totalSteps = 10,
    this.onPrimaryAction,
    this.primaryButtonText,
    this.isPrimaryButtonEnabled = true,
    this.showBackButton = true,
    this.showNextButton = true,
    this.showIndicator = true,
    this.onBack,
    this.headerAction,
    this.icon,
    // Support legacy parameter names from screens
    String? description,
    VoidCallback? onNext,
    String? nextButtonText,
  })  : description = description ?? subtitle ?? '',
        onNext = onNext ?? onPrimaryAction ?? _dummyAction,
        nextButtonText = nextButtonText ?? primaryButtonText ?? 'Continue';

  final String description;
  final VoidCallback onNext;
  final String nextButtonText;

  static void _dummyAction() {}

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Main Content
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  children: [
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (showBackButton)
                            IconButton(
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                onBack?.call();
                              },
                              icon: const Icon(Icons.arrow_back_ios_new_rounded),
                              color: AppTheme.primaryColor,
                              iconSize: 20,
                            )
                          else
                            const SizedBox(width: 48),
                          
                          if (showIndicator)
                            OnboardingStepIndicator(
                              currentStep: currentStep,
                              totalSteps: totalSteps,
                            ),
                          
                          if (headerAction != null)
                            headerAction!
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    // Scrollable Area
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (icon != null) ...[
                              icon!,
                              const SizedBox(height: 24),
                            ],
                            Text(
                              title,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                description,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),
                            content,
                            if (footer != null) ...[
                              const SizedBox(height: 24),
                              footer!,
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Button - Hidden when keyboard is open
            if (showNextButton)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    16,
                    24,
                    MediaQuery.paddingOf(context).bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryDark.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isPrimaryButtonEnabled ? onNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.accentColor.withValues(alpha: 0.3),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      nextButtonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
