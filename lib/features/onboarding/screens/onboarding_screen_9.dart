import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orushops/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────
//  Screen
// ─────────────────────────────────────────────────────────────────
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
    final size = MediaQuery.of(context).size;

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                                value: '12K+',
                                label: 'Stores',
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
                                icon: Icons.currency_rupee_rounded,
                                iconColor: Color(0xFF34C759),
                                iconBg: Color(0xFFE8F8EC),
                                value: '2.4Cr+',
                                label: 'Daily sales',
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
                                icon: Icons.flash_on_rounded,
                                iconColor: Color(0xFFFF9500),
                                iconBg: Color(0xFFFFF3E0),
                                value: '< 2s',
                                label: 'Checkout',
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
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Compact stat card  (1/3 width column layout for horizontal row)
// ─────────────────────────────────────────────────────────────────
class _CompactStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  const _CompactStatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: Color(0xFF1C1C1E),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF8E8E93),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
//  "What you unlocked" card
// ─────────────────────────────────────────────────────────────────
class _UnlockedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF007AFF).withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lock_open_rounded,
                  size: 16, color: Color(0xFF007AFF)),
              SizedBox(width: 8),
              Text(
                'What you unlocked',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1C1C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _UnlockRow(
            icon: Icons.wifi_off_rounded,
            text: 'Offline billing — sell even without internet',
          ),
          _UnlockRow(
            icon: Icons.sync_rounded,
            text: 'Instant inventory sync across devices',
          ),
          _UnlockRow(
            icon: Icons.payments_rounded,
            text: 'UPI, Cash & Card in one tap',
          ),
          _UnlockRow(
            icon: Icons.bar_chart_rounded,
            text: 'Daily sales report delivered to you',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _UnlockRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isLast;

  const _UnlockRow({
    required this.icon,
    required this.text,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF007AFF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF3A3A3C),
                height: 1.4,
              ),
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              size: 16, color: Color(0xFF34C759)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Confetti painter
// ─────────────────────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter(this.progress);

  static const _count = 44;
  static final _rng = math.Random(7);

  static final List<_Particle> _particles = List.generate(
    _count,
    (_) => _Particle(
      x: _rng.nextDouble(),
      speed: 0.25 + _rng.nextDouble() * 0.75,
      drift: (_rng.nextDouble() - 0.5) * 0.35,
      size: 6 + _rng.nextDouble() * 7,
      rotation: _rng.nextDouble() * math.pi * 2,
      rotSpeed: (_rng.nextDouble() - 0.5) * 7,
      color: _palette[_rng.nextInt(_palette.length)],
      delay: _rng.nextDouble() * 0.35,
    ),
  );

  static const _palette = [
    Color(0xFF007AFF), Color(0xFFFF3B30), Color(0xFF34C759),
    Color(0xFFFFCC00), Color(0xFFFF9500), Color(0xFF5856D6),
    Color(0xFFFF2D55), Color(0xFF30B0C7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final x = (p.x + p.drift * t) * size.width;
      final y = -50.0 + t * (size.height + 100) * p.speed;
      final opacity = (1.0 - ((t - 0.65) / 0.35).clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + t * p.rotSpeed);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(2),
        ),
        Paint()
          ..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0) * 0.88)
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _Particle {
  final double x, speed, drift, size, rotation, rotSpeed, delay;
  final Color color;

  const _Particle({
    required this.x, required this.speed, required this.drift,
    required this.size, required this.rotation, required this.rotSpeed,
    required this.color, required this.delay,
  });
}
