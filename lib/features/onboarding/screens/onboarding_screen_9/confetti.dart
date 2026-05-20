part of '../onboarding_screen_9.dart';

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
