part of '../home_screen.dart';

// ── SUB-COMPONENTS ───────────────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  final String name;
  const _ProfileAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'P',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
    );
  }
}

class _GreetingTitle extends StatelessWidget {
  final String greeting;
  final String name;
  final String date;

  const _GreetingTitle({required this.greeting, required this.name, required this.date});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $name',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: -0.8,
          ),
        ),
        Text(
          date,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}


// ── SALES HERO CARD ──────────────────────────────────────────────────────────

class _SalesHeroCard extends StatelessWidget {
  final double revenue;
  final int count;
  final double growth;

  const _SalesHeroCard({required this.revenue, required this.count, required this.growth});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: _HeroDecorations()),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeroBadge(),
                const SizedBox(height: 24),
                Text(
                  fmt.format(revenue),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2.0,
                  ),
                ),
                const SizedBox(height: 30),
                _HeroStatsRow(count: count, growth: growth),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDecorations extends StatelessWidget {
  const _HeroDecorations();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: -60,
          top: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: -40,
          child: Icon(
            CupertinoIcons.graph_circle_fill,
            size: 150,
            color: Colors.white.withValues(alpha: 0.03),
          ),
        ),
      ],
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(CupertinoIcons.sparkles, color: Colors.white, size: 14),
              SizedBox(width: 8),
              Text(
                'TODAY\'S PERFORMANCE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const Icon(CupertinoIcons.ellipsis, color: Colors.white54, size: 24),
      ],
    );
  }
}

class _HeroStatsRow extends StatelessWidget {
  final int count;
  final double growth;

  const _HeroStatsRow({required this.count, required this.growth});

  @override
  Widget build(BuildContext context) {
    final isUp = growth >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          _HeroStatItem(
            icon: CupertinoIcons.shopping_cart,
            label: 'Total Orders',
            value: '$count',
          ),
          Container(
            width: 1,
            height: 35,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            color: Colors.white.withValues(alpha: 0.15),
          ),
          _HeroStatItem(
            icon: isUp ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_right,
            label: 'Growth Rate',
            value: '${isUp ? '+' : ''}${growth.toStringAsFixed(1)}%',
            valueColor: isUp ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
          ),
        ],
      ),
    );
  }
}

class _HeroStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _HeroStatItem({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54, size: 14),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ACTION PILL ──────────────────────────────────────────────────────────────

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.8), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

