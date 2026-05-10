import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/onboarding_page.dart';

class OnboardingScreen2 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onPhoneSelected;
  final VoidCallback onGoogleSelected;
  final VoidCallback onAppleSelected;

  const OnboardingScreen2({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.onPhoneSelected,
    required this.onGoogleSelected,
    required this.onAppleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingPage(
      currentStep: 2,
      totalSteps: 6,
      title: 'Login or sign up',
      description:
          'Please select your preferred method\nto continue setting up your account',
      illustration: SvgPicture.asset('images/launching.svg', fit: BoxFit.contain),
      blendIllustration: false,
      onNext: onNext,
      onBack: onBack,
      showBackButton: true,
      showBottomBackButton: false,
      showNextButton: false,
      showIndicator: false,
      nextButtonText: 'Next',
      illustrationFlex: 4,
      contentFlex: 5,
      content: Column(
        children: [
          _AuthButton(
            icon: Icons.phone_android_rounded,
            label: 'Continue with Phone',
            onTap: onPhoneSelected,
            isPrimary: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Divider(color: AppTheme.borderColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ),
              Expanded(child: Divider(color: AppTheme.borderColor)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SocialButton(
                  label: 'Google',
                  onTap: onGoogleSelected,
                  svgContent:
                      '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
<path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
<path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z" fill="#FBBC05"/>
<path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 12-4.53z" fill="#EA4335"/>
</svg>''',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SocialButton(
                  label: 'Apple',
                  onTap: onAppleSelected,
                  svgContent:
                      '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M17.05 20.28c-.96.95-2.04 1.95-3.32 1.95s-1.68-.78-3.18-.78c-1.5 0-2.02.76-3.18.78-1.16.02-2.18-.88-3.16-1.85C2.21 18.38 1 15.42 1 12.63c0-4.48 2.91-6.85 5.76-6.85 1.5 0 2.84.94 3.76.94s2.1-.96 3.86-.96c1.47 0 3.41.76 4.6 2.19-3.04 1.76-2.55 5.75.47 6.94-.74 1.88-1.74 3.73-2.4 5.39zM12.03 5.4c-.02-2.31 1.9-4.32 4.13-4.4.2 2.65-2.48 4.54-4.13 4.4z" fill="black"/>
</svg>''',
                ),
              ),
            ],
          ),
        ],
      ),
      footer: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
            children: [
              const TextSpan(text: 'By continuing, you agree to our '),
              TextSpan(
                text: 'Terms of Service',
                recognizer: TapGestureRecognizer()
                  ..onTap = () => launchUrl(Uri.parse('https://orushops.com/terms'), mode: LaunchMode.externalApplication),
                style: const TextStyle(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              const TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                recognizer: TapGestureRecognizer()
                  ..onTap = () => launchUrl(Uri.parse('https://orushops.com/privacy'), mode: LaunchMode.externalApplication),
                style: const TextStyle(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _AuthButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color blueColor = AppTheme.accentColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isPrimary ? blueColor : Colors.white,
          border: isPrimary ? null : Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: blueColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isPrimary ? Colors.white : AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isPrimary ? Colors.white : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final String svgContent;

  const _SocialButton({
    required this.label,
    required this.onTap,
    required this.svgContent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(svgContent, width: 24, height: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
