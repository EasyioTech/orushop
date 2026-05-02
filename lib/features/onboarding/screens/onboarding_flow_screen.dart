import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orushops/providers/onboarding_provider.dart';
import 'onboarding_screen_1.dart';
import 'onboarding_screen_2.dart';
import 'onboarding_screen_3.dart';
import 'onboarding_screen_4.dart';
import 'onboarding_screen_5.dart';
import 'onboarding_screen_7.dart';
import 'onboarding_screen_8.dart';
import 'onboarding_screen_9.dart';
import 'onboarding_screen_10.dart';
import 'onboarding_screen_17.dart';

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
      _pageController.jumpToPage(7);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed: $e')),
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
    if (_currentPage == 7) {
      // Read provider only when mounted and stable
      final emailOrPhone =
          ref.read(onboardingProvider).emailOrPhone ?? '';
      if (emailOrPhone.contains('@')) {
        _pageController.jumpToPage(4); // Back to Email Confirm
      } else if (emailOrPhone.isNotEmpty) {
        _pageController.jumpToPage(6); // Back to Phone Confirm
      } else {
        _pageController.jumpToPage(1); // Back to Selection
      }
    } else if (_currentPage == 2 || _currentPage == 5) {
      _pageController.jumpToPage(1); // Back to Selection
    } else if (_currentPage > 0) {
      // Use jumpToPage on back-gesture paths to avoid animated scroll
      // notifications firing on a deactivated page widget.
      _pageController.jumpToPage(_currentPage - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  onEmailSelected: () => _pageController.jumpToPage(2),
                  onPhoneSelected: () => _pageController.jumpToPage(5),
                  onGoogleSelected: () => _handleSocialAuth(
                    () => ref.read(onboardingProvider.notifier).signInWithGoogle(complete: false),
                  ),
                  onAppleSelected: () => _handleSocialAuth(
                    () => ref.read(onboardingProvider.notifier).signInWithApple(complete: false),
                  ),
                ),
                // Email Path (Indices 2, 3, 4)
                OnboardingScreen3(
                  onNext: _nextPage,
                  onBack: () => _pageController.jumpToPage(1),
                  currentLanguage: 'en',
                ),
                OnboardingScreen4(
                  onNext: _nextPage,
                  onBack: _previousPage,
                ),
                OnboardingScreen5(
                  onNext: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _isLoading = true);
                    try {
                      final state = ref.read(onboardingProvider);
                      await ref.read(onboardingProvider.notifier).signUpWithEmail(
                        state.emailOrPhone!,
                        state.password!,
                        complete: false,
                      );
                      _pageController.jumpToPage(7);
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text('Sign up failed: $e')),
                      );
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                  onBack: _previousPage,
                ),
                // Phone Path (Indices 5, 6)
                OnboardingScreen7(
                  onNext: _nextPage,
                  onBack: () => _pageController.jumpToPage(1),
                ),
                OnboardingScreen8(
                  onNext: () => _pageController.jumpToPage(7),
                  onBack: _previousPage,
                ),
                // Essential Personal Info (Index 7)
                OnboardingScreen10(
                  onNext: (firstName, lastName) async {
                    setState(() => _isLoading = true);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ref.read(onboardingProvider.notifier).updateUserDetails(
                            firstName: firstName,
                            lastName: lastName,
                          );
                      _nextPage();
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to update details: $e')),
                      );
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                  onBack: _goBack,
                ),
                // Success & Upsell (Indices 8, 9)
                OnboardingScreen9(
                  onNext: _nextPage,
                  onBack: _previousPage,
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
                  onBack: _previousPage,
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

