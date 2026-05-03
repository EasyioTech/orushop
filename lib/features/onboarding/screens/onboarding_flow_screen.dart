import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orushops/providers/onboarding_provider.dart';
import 'onboarding_screen_1.dart';
import 'onboarding_screen_2.dart';
import 'onboarding_screen_7.dart';
import 'onboarding_screen_8.dart';
import 'onboarding_screen_9.dart';
import 'onboarding_screen_17.dart';
import 'onboarding_shop_basic_details_screen.dart';
import 'onboarding_shop_additional_details_screen.dart';
import 'onboarding_features_screen.dart';
import 'onboarding_categories_screen.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isLoading = false;

  Future<void> _handleSocialAuth(Future<void> Function() authMethod) async {
    setState(() => _isLoading = true);
    try {
      await authMethod();
      _pageController.jumpToPage(4); // Jump to Shop Basic Details
    } catch (e) {
      if (mounted) {
        String message = e.toString();
        if (message.contains('email-already-in-use') || message.contains('already in use')) {
          message = 'This email is already associated with an account. Please sign in via the Login screen or use a different account.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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
    if (_currentPage == 8) {
      // Back from Success to Categories
      _pageController.jumpToPage(_currentPage - 1);
    } else if (_currentPage == 6) {
      // Back from Features to Additional Shop Details
      _pageController.jumpToPage(_currentPage - 1);
    } else if (_currentPage == 5) {
      // Back from Additional to Basic Shop Details
      _pageController.jumpToPage(_currentPage - 1);
    } else if (_currentPage == 4) {
      // Back from Basic Shop Details to Selection (since social/phone auth landed here)
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
                  onNext: _nextPage,
                  onBack: () => _pageController.jumpToPage(1),
                ),
                OnboardingScreen8(
                  onNext: () => _pageController.jumpToPage(4),
                  onBack: _previousPage,
                ),
                // Shop Setup Path (Indices 4, 5, 6, 7)
                OnboardingShopBasicDetailsScreen(
                  onNext: _nextPage,
                  onBack: _goBack,
                ),
                OnboardingShopAdditionalDetailsScreen(
                  onNext: _nextPage,
                  onBack: _goBack,
                ),
                OnboardingFeaturesScreen(
                  onNext: _nextPage,
                  onBack: _goBack,
                ),
                OnboardingCategoriesScreen(
                  onNext: _nextPage,
                  onBack: _goBack,
                ),
                // Success & Upsell (Indices 8, 9)
                OnboardingScreen9(
                  onNext: _nextPage,
                  onBack: _goBack,
                ),
                OnboardingScreen17(
                  onNext: (planId) async {
                    setState(() => _isLoading = true);
                    try {
                      if (planId != null) {
                        ref.read(onboardingProvider.notifier).setPlan(planId);
                      }
                      await ref.read(onboardingProvider.notifier).completeOnboarding();
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
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

