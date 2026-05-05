import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:orushops/core/providers/connectivity_provider.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/providers/onboarding_provider.dart';
import 'package:orushops/core/widgets/error_boundary.dart';

// ── Real Google SVG logo (multicolour) ─────────────────────────────
const String _googleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.18 1.48-4.97 2.31-8.16 2.31-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>''';

// ── Real Apple SVG logo (black) ────────────────────────────────────
const String _appleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 814 1000">
  <path fill="#1C1C1E" d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76 0-103.7 40.8-165.9 40.8s-105-43.4-150.3-113.4c-52.2-81.3-99.2-209-99.2-330.5 0-199.4 131.4-305 260.4-305 66.2 0 121.2 43.4 162.7 43.4 39.5 0 101.1-46 176.3-46 28.5 0 130.9 2.6 198.3 99.2zm-234-181.5c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1-50.6 1.9-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 7.8 1.3 15.6 1.9 18.1 3.2.6 8.4 1.3 13.6 1.3 45.4 0 102.5-30.4 135.5-71.3z"/>
</svg>''';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final bool _isLoading = false;
  bool _isGoogleLoading = false;
  final bool _isAppleLoading  = false;

  String _friendlyError(dynamic e, bool isOffline) {
    if (isOffline) {
      return 'Authentication requires an internet connection. Please connect and try again.';
    }
    final msg = e.toString();
    if (msg.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (msg.contains('network-request-failed') || msg.contains('SocketException')) {
      return 'Network connection failed. Check your internet and try again.';
    }
    return 'Login failed. Please try again.';
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF1C1C1E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }


  Future<void> _handleGoogleLogin() async {
    FocusScope.of(context).unfocus();

    final isOffline = ref.read(isOfflineProvider);
    if (isOffline) {
      _showSnack(_friendlyError(null, true));
      return;
    }

    setState(() => _isGoogleLoading = true);
    try {
      await ref
          .read(onboardingProvider.notifier)
          .signInWithGoogle(complete: true);
    } catch (e) {
      _showSnack(_friendlyError(e, false));
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleAppleLogin() async {
    _showSnack('Apple Sign-In coming soon.');
  }


  @override
  Widget build(BuildContext context) {
    final anyLoading = _isLoading || _isGoogleLoading || _isAppleLoading;
    final isOffline = ref.watch(isOfflineProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: OfflineBanner(
        isOffline: isOffline,
        child: SafeArea(
          child: Column(
          children: [
            // ── SVG illustration (top 40%) ───────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Image.asset(
                  'images/logo.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),

            // ── Scrollable form (bottom 60%) ─────────────────────
            Expanded(
              flex: 6,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Title ──────────────────────────────────────
                    const Text(
                      'Welcome back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C1C1E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to your OruShops account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const SizedBox(height: 32),

                    // ── Social rectangle button ────────────────────
                    _SocialRectButton(
                      onTap: anyLoading ? null : _handleGoogleLogin,
                      isLoading: _isGoogleLoading,
                      label: 'Continue with Google',
                      iconSvg: _googleSvg,
                    ),

                    const SizedBox(height: 12),

                    _SocialRectButton(
                      onTap: anyLoading ? null : _handleAppleLogin,
                      isLoading: _isAppleLoading,
                      label: 'Continue with Apple',
                      iconSvg: _appleSvg,
                    ),

                    const SizedBox(height: 8),

                  ],
                ),
              ),
            ),

            // ── Pinned bottom CTA + sign-up ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: anyLoading
                            ? null
                            : () => ref
                                .read(onboardingProvider.notifier)
                                .resetOnboarding(),
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}


// ── Social rectangle button ────────────────────────────────────────
// Full-width outlined pill with real SVG brand icon + label
class _SocialRectButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final String label;
  final String iconSvg;

  const _SocialRectButton({
    required this.onTap,
    required this.isLoading,
    required this.label,
    required this.iconSvg,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E5EA), width: 1.5),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF007AFF),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.string(
                      iconSvg,
                      width: 22,
                      height: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
