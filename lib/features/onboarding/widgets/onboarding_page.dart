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
    this.showBottomBackButton = true,
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
          // Top Illustration Area
          Expanded(
            flex: illustrationFlex,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: illustration != null
                      ? (blendIllustration
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
                            : illustration!)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // Bottom Content Area
          Expanded(
            flex: contentFlex,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
                      child: Column(
                        children: [
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (showIndicator) ...[
                                  OnboardingStepIndicator(
                                    currentStep: currentStep,
                                    totalSteps: totalSteps,
                                  ),
                                  const SizedBox(height: 12),
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
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),

                                // Main Content (forms, buttons, etc.)
                                content,

                                if (footer != null) ...[
                                  const SizedBox(height: 8),
                                  footer!,
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Action Buttons
                          if (showBackButton || showNextButton) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (showBackButton && showBottomBackButton) ...[
                                  IconButton(
                                    onPressed: () {
                                      FocusScope.of(context).unfocus();
                                      onBack?.call();
                                    },
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppTheme.dividerColor,
                                      padding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                if (showNextButton)
                                  Expanded(
                                    child: SizedBox(
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          FocusScope.of(context).unfocus();
                                          onNext();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.accentColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          nextButtonText,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      if (showBackButton)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
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
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF007AFF),
                    size: 20,
                  ),
                ),
              ),
            ),
          if (headerAction != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 12,
              child: headerAction!,
            ),
        ],
      ),
    );
  }
}
