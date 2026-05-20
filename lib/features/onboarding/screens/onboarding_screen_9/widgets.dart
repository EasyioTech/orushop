part of '../onboarding_screen_9.dart';

/// Compact stat card (1/3 width column layout for horizontal row)
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

/// "What you unlocked" card
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
