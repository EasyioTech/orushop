import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orushops/providers/onboarding_provider.dart' show onboardingProvider, OnboardingException;
import 'onboarding_screen_1.dart';
import 'onboarding_screen_2.dart';
import 'onboarding_screen_7.dart';
import 'onboarding_screen_8.dart';
import 'onboarding_screen_9.dart';
import 'onboarding_screen_17.dart';
import 'onboarding_shop_basic_details_screen.dart';
import 'onboarding_shop_additional_details_screen.dart';
import 'package:orushops/core/theme/app_theme.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isLoading = false;

  // OTP flow state — set by screen 7, consumed by screen 8
  String? _otpVerificationId;
  String? _otpPhone;

  Future<void> _handleSocialAuth(Future<void> Function() authMethod) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    try {
      await authMethod();
      if (!mounted) return;
      final onboardingState = ref.read(onboardingProvider);
      if (onboardingState.isCompleted) {
        debugPrint('Social auth complete: Existing shop details restored. Redirecting to home.');
      } else {
        _pageController.jumpToPage(4);
      }
    } catch (e) {
      String message = e.toString();
      if (message.contains('email-already-in-use') || message.contains('already in use')) {
        message = 'This email is already associated with an account. Please sign in via the Login screen or use a different account.';
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (!mounted) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    if (!mounted) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goBack() {
    if (!mounted) return;
    if (_currentPage == 7) {
      // Back from Upsell to Success
      _pageController.jumpToPage(6);
    } else if (_currentPage == 6) {
      // Back from Success to Additional Shop Details (skipped Features/Categories)
      _pageController.jumpToPage(5);
    } else if (_currentPage == 5) {
      // Back from Additional to Basic Shop Details
      _pageController.jumpToPage(4);
    } else if (_currentPage == 4) {
      // Back from Basic Shop Details to Selection
      _pageController.jumpToPage(1);
    } else if (_currentPage == 2) {
      _pageController.jumpToPage(1); // Back to Selection from Phone Path
    } else if (_currentPage > 0) {
      _pageController.jumpToPage(_currentPage - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch onboarding state to ensure children get fresh data if they read it in initState
    ref.watch(onboardingProvider);
    
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Defer to post-frame so the widget tree is stable before we
        // call ref.read() or touch the PageController.
        WidgetsBinding.instance.addPostFrameCallback((_) => _goBack());
      },
      child: Stack(
        children: [
          Scaffold(
            resizeToAvoidBottomInset: true,
            body: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                OnboardingScreen1(onNext: _nextPage),
                OnboardingScreen2(
                  onNext: _nextPage,
                  onBack: _previousPage,
                  onPhoneSelected: () => _pageController.jumpToPage(2),
                  onGoogleSelected: () => _handleSocialAuth(
                    () => ref.read(onboardingProvider.notifier).signInWithGoogle(complete: false),
                  ),
                  onAppleSelected: () => _handleSocialAuth(
                    () => ref.read(onboardingProvider.notifier).signInWithApple(complete: false),
                  ),
                ),
                // Phone Path (Indices 2, 3)
                OnboardingScreen7(
                  onOtpSent: (verificationId, phone) {
                    setState(() {
                      _otpVerificationId = verificationId;
                      _otpPhone = phone;
                    });
                    _pageController.jumpToPage(3);
                  },
                  onBack: () => _pageController.jumpToPage(1),
                ),
                OnboardingScreen8(
                  verificationId: _otpVerificationId ?? '',
                  phone: _otpPhone ?? '',
                  onNext: () {
                    final onboardingState = ref.read(onboardingProvider);
                    if (onboardingState.isCompleted) {
                      debugPrint('OTP verify complete: Existing shop details restored. Redirecting to home.');
                    } else {
                      _pageController.jumpToPage(4);
                    }
                  },
                  onBack: _goBack,
                ),
                // Shop Setup Path (Indices 4, 5)
                OnboardingShopBasicDetailsScreen(
                  onNext: _nextPage,
                  onBack: _goBack,
                ),
                OnboardingShopAdditionalDetailsScreen(
                  onNext: () => _pageController.jumpToPage(6), // Skip Features & Categories, go to Success
                  onBack: _goBack,
                ),
                // Hidden/Automated: OnboardingFeaturesScreen & OnboardingCategoriesScreen
                
                // Success & Upsell (Indices 6, 7)
                OnboardingScreen9(
                  onNext: _nextPage,
                  onBack: _goBack,
                ),
                OnboardingScreen17(
                  onNext: (planId) async {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _isLoading = true);
                    try {
                      if (planId != null) {
                        ref.read(onboardingProvider.notifier).setPlan(planId);
                      }
                      await ref.read(onboardingProvider.notifier).completeOnboarding();
                    } on OnboardingException catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(e.message),
                          backgroundColor: AppTheme.errorColor,
                          duration: const Duration(seconds: 6),
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text('Something went wrong. Please try again.'),
                          backgroundColor: AppTheme.errorColor,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                  onBack: _goBack,
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: AppTheme.primaryDark.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

