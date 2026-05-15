import 'package:flutter/material.dart';
import 'package:orushops/core/theme/app_theme.dart';
import '../widgets/onboarding_step_indicator.dart';

class OnboardingPage extends StatelessWidget {
  final Widget? illustration;
  final String title;
  final String description;
  final Widget content;
  final Widget? footer;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final String nextButtonText;
  final bool showBackButton;
  final bool showBottomBackButton;
  final bool showNextButton;
  final bool showIndicator;
  final bool blendIllustration;
  final VoidCallback? onBack;
  final Widget? headerAction;
  final int illustrationFlex;
  final int contentFlex;

  const OnboardingPage({
    super.key,
    this.illustration,
    required this.title,
    required this.description,
    required this.content,
    this.footer,
    required this.currentStep,
    this.totalSteps = 17,
    required this.onNext,
    this.nextButtonText = 'Continue',
    this.showBackButton = true,
    this.showBottomBackButton = false,
    this.showNextButton = true,
    this.showIndicator = true,
    this.blendIllustration = true,
    this.onBack,
    this.headerAction,
    this.illustrationFlex = 4,
    this.contentFlex = 5,
  });

  @override
  Widget build(BuildContext context) {
    final double safeTop = MediaQuery.paddingOf(context).top;

    return Material(
      color: Colors.white,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Main Scrollable Content
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                // Extra bottom padding to account for sticky buttons (approx 92px) + keyboard
                // Extra bottom padding to account for sticky buttons (approx 92px) or keyboard
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  children: [
                    // Top Illustration Area
                    if (illustration != null)
                      Container(
                        width: double.infinity,
                        height: MediaQuery.sizeOf(context).height * (illustrationFlex / 12),
                        color: Colors.white,
                        child: SafeArea(
                          bottom: false,
                          child: Center(
                            child: blendIllustration
                                ? ShaderMask(
                                    shaderCallback: (rect) {
                                      return const RadialGradient(
                                        center: Alignment.center,
                                        radius: 0.5,
                                        colors: [Colors.white, Colors.transparent],
                                        stops: [0.6, 1.0],
                                      ).createShader(rect);
                                    },
                                    blendMode: BlendMode.dstIn,
                                    child: illustration!,
                                  )
                                : illustration!,
                          ),
                        ),
                      )
                    else if (showBackButton)
                      SizedBox(height: safeTop + 70),

                    // Content Area
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (showIndicator) ...[
                            OnboardingStepIndicator(
                              currentStep: currentStep,
                              totalSteps: totalSteps,
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  fontSize: 28,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                  fontSize: 15,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Main Content (forms, buttons, etc.)
                          content,

                          if (footer != null) ...[
                            const SizedBox(height: 24),
                            footer!,
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sticky Action Buttons at the bottom - Hidden when keyboard is open
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
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
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

            // Top Floating Back Button
            if (showBackButton)
              Positioned(
                top: safeTop + 12,
                left: 12,
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    onBack?.call();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryDark.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.accentColor,
                      size: 20,
                    ),
                  ),
                ),
              ),

            if (headerAction != null)
              Positioned(
                top: safeTop + 12,
                right: 12,
                child: headerAction!,
              ),
          ],
        ),
      ),
    );
  }
}
