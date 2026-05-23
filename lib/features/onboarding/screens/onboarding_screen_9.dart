import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orushops/core/theme/app_theme.dart';

part 'onboarding_screen_9/widgets.dart';
part 'onboarding_screen_9/confetti.dart';

class OnboardingScreen9 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingScreen9({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingScreen9> createState() => _OnboardingScreen9State();
}

class _OnboardingScreen9State extends State<OnboardingScreen9>
    with TickerProviderStateMixin {

  // Controllers
  late final AnimationController _confettiCtrl;
  late final AnimationController _circleCtrl;
  late final AnimationController _checkCtrl;
  late final AnimationController _headlineCtrl;
  late final AnimationController _card1Ctrl;
  late final AnimationController _card2Ctrl;
  late final AnimationController _card3Ctrl;
  late final AnimationController _unlockedCtrl;
  late final AnimationController _buttonCtrl;
  late final AnimationController _pulseCtrl;

  // Derived animations
  late final Animation<double> _confettiAnim;
  late final Animation<double> _circleScale;
  late final Animation<double> _checkScale;
  late final Animation<double> _checkFade;
  late final Animation<double> _headlineSlide;
  late final Animation<double> _headlineFade;
  late final Animation<double> _pulseAnim;

  // Card animations (pre-cached so all three controllers drive the builder)
  late final Animation<double> _card1Fade;
  late final Animation<double> _card1Slide;
  late final Animation<double> _card2Fade;
  late final Animation<double> _card2Slide;
  late final Animation<double> _card3Fade;
  late final Animation<double> _card3Slide;

  Animation<double> _slideUp(AnimationController c) =>
      Tween<double>(begin: 28, end: 0)
          .animate(CurvedAnimation(parent: c, curve: Curves.easeOut));

  Animation<double> _fadeIn(AnimationController c) =>
      Tween<double>(begin: 0, end: 1)
          .animate(CurvedAnimation(parent: c, curve: Curves.easeIn));

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();

    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _confettiAnim = CurvedAnimation(parent: _confettiCtrl, curve: Curves.easeOut);

    _circleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _circleScale = CurvedAnimation(parent: _circleCtrl, curve: Curves.elasticOut);

    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _checkScale = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _checkCtrl, curve: Curves.easeOutBack));
    _checkFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _checkCtrl, curve: Curves.easeIn));

    _headlineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _headlineSlide = _slideUp(_headlineCtrl);
    _headlineFade = _fadeIn(_headlineCtrl);

    _card1Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _card2Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _card3Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));

    // Pre-cache card animations so all 3 controllers drive the shared builder
    _card1Fade = _fadeIn(_card1Ctrl);
    _card1Slide = _slideUp(_card1Ctrl);
    _card2Fade = _fadeIn(_card2Ctrl);
    _card2Slide = _slideUp(_card2Ctrl);
    _card3Fade = _fadeIn(_card3Ctrl);
    _card3Slide = _slideUp(_card3Ctrl);

    _unlockedCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));

    _buttonCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));

    // Idle glow pulse on circle
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 80));
    _circleCtrl.forward();
    _confettiCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 360));
    HapticFeedback.lightImpact();
    _checkCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 240));
    _headlineCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 180));
    _card1Ctrl.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    _card2Ctrl.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    _card3Ctrl.forward();

    await Future.delayed(const Duration(milliseconds: 160));
    _unlockedCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 120));
    _buttonCtrl.forward();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _circleCtrl.dispose();
    _checkCtrl.dispose();
    _headlineCtrl.dispose();
    _card1Ctrl.dispose();
    _card2Ctrl.dispose();
    _card3Ctrl.dispose();
    _unlockedCtrl.dispose();
    _buttonCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // Helper: wrap any widget in a slide+fade transition
  Widget _animated(
    AnimationController ctrl,
    Animation<double> slide,
    Animation<double> fade,
    Widget child,
  ) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, animChild) => Transform.translate(
        offset: Offset(0, slide.value),
        child: Opacity(opacity: fade.value, child: animChild),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Confetti
            AnimatedBuilder(
              animation: _confettiAnim,
              builder: (context, child) => CustomPaint(
                size: Size(size.width, size.height),
                painter: _ConfettiPainter(_confettiAnim.value),
              ),
            ),

            // Content
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Checkmark circle ──────────────────────────────
                  ScaleTransition(
                    scale: _circleScale,
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, child) =>
                          Transform.scale(scale: _pulseAnim.value, child: child),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF007AFF), Color(0xFF0040CC)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF007AFF).withValues(alpha: 0.32),
                              blurRadius: 28,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: FadeTransition(
                          opacity: _checkFade,
                          child: ScaleTransition(
                            scale: _checkScale,
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Headline ──────────────────────────────────────
                  _animated(
                    _headlineCtrl,
                    _headlineSlide,
                    _headlineFade,
                    Column(
                      children: [
                        Text(
                          'You\'re all set',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1C1C1E),
                                fontSize: 28,
                                letterSpacing: -0.5,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your store is powered by OruShops.\nLet\'s make your first sale.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                                height: 1.55,
                                fontSize: 15,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Three stat cards (one row) ────────────────────
                  AnimatedBuilder(
                    animation: Listenable.merge(
                        [_card1Ctrl, _card2Ctrl, _card3Ctrl]),
                    builder: (context, _) => Row(
                      children: [
                        Expanded(
                          child: Transform.translate(
                            offset: Offset(0, _card1Slide.value),
                            child: Opacity(
                              opacity: _card1Fade.value,
                              child: const _CompactStatCard(
                                icon: Icons.store_rounded,
                                iconColor: Color(0xFF007AFF),
                                iconBg: Color(0xFFEAF2FF),
                                value: '100%',
                                label: 'Free to start',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Transform.translate(
                            offset: Offset(0, _card2Slide.value),
                            child: Opacity(
                              opacity: _card2Fade.value,
                              child: const _CompactStatCard(
                                icon: Icons.wifi_off_rounded,
                                iconColor: Color(0xFF34C759),
                                iconBg: Color(0xFFE8F8EC),
                                value: 'Offline',
                                label: 'Works offline',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Transform.translate(
                            offset: Offset(0, _card3Slide.value),
                            child: Opacity(
                              opacity: _card3Fade.value,
                              child: const _CompactStatCard(
                                icon: Icons.receipt_long_rounded,
                                iconColor: Color(0xFFFF9500),
                                iconBg: Color(0xFFFFF3E0),
                                value: 'GST',
                                label: 'GST billing',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Unlocked features ─────────────────────────────
                  _animated(
                    _unlockedCtrl,
                    _slideUp(_unlockedCtrl),
                    _fadeIn(_unlockedCtrl),
                    _UnlockedCard(),
                  ),

                  const SizedBox(height: 28),

                  // ── CTA button ────────────────────────────────────
                  _animated(
                    _buttonCtrl,
                    _slideUp(_buttonCtrl),
                    _fadeIn(_buttonCtrl),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: widget.onNext,
                            icon: const Icon(Icons.arrow_forward_rounded,
                                size: 20),
                            label: const Text(
                              'Open My Store',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007AFF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline_rounded,
                                size: 13, color: Color(0xFF8E8E93)),
                            const SizedBox(width: 5),
                            Text(
                              'Your data is encrypted and never sold.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }
}
