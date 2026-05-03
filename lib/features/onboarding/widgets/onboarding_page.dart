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
    final double safeTop = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Top Illustration Area
                      if (illustration != null)
                        Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * (illustrationFlex / 12), // Reduced default height slightly
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
                        // Space for floating back button if no illustration
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

              // Sticky Action Buttons at the bottom
              if (showBackButton || showNextButton)
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
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
                            backgroundColor: const Color(0xFFF2F2F7),
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
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
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
                ),
            ],
          ),

          // Floating Back Button (Top Left)
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
              top: safeTop + 12,
              right: 12,
              child: headerAction!,
            ),
        ],
      ),
    );
  }
}
