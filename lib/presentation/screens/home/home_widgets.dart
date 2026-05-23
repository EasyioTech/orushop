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



// ── SALES HERO CARD ──────────────────────────────────────────────────────────

class _SalesHeroCard extends ConsumerWidget {
  final double revenue;
  final int count;
  final double growth;
  final String greeting;
  final String name;
  final String date;

  const _SalesHeroCard({
    required this.revenue,
    required this.count,
    required this.growth,
    required this.greeting,
    required this.name,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final topPadding = MediaQuery.of(context).padding.top;
    
    // Read dynamic sales target
    final target = ref.watch(dailySalesGoalProvider);
    final rawPercent = target > 0 ? (revenue / target) : 0.0;
    final percent = rawPercent.clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2E8F0),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFE2E8F0),
            spreadRadius: 1,
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Integrated Top Header ─────────────────────────────────────
                Row(
                  children: [
                    _ProfileAvatar(name: name),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting, $name',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
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
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.chart_bar_circle_fill, color: AppTheme.accentColor, size: 26),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                        );
                      },
                      tooltip: 'View Reports',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Main Today's Revenue Info ────────────────────────────────
                const Row(
                  children: [
                    Icon(CupertinoIcons.sparkles, color: AppTheme.accentColor, size: 13),
                    SizedBox(width: 6),
                    Text(
                      'TODAY\'S REVENUE',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  fmt.format(revenue),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2.0,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Interactive Daily Target Progress Bar ───────────────────
                GestureDetector(
                  onTap: () => _showEditGoalDialog(context, ref, target),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryDark.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(CupertinoIcons.flag_fill, color: AppTheme.accentColor, size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Daily Target: ${fmt.format(target)}',
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(CupertinoIcons.pencil_circle_fill, color: AppTheme.textSecondary, size: 14),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(rawPercent * 100).toStringAsFixed(0)}% achieved',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Sleek glowing progress track
                        Container(
                          height: 8,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: percent,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF007AFF), Color(0xFF3B82F6)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Frost Glass Stats Capsule ────────────────────────────────
                _HeroStatsRow(count: count, growth: growth),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context, WidgetRef ref, double currentGoal) {
    HapticFeedback.mediumImpact();
    final controller = TextEditingController(text: currentGoal.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Row(
          children: [
            Icon(CupertinoIcons.flag_circle_fill, color: AppTheme.accentColor, size: 28),
            SizedBox(width: 10),
            Text(
              'Daily Target',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set a target revenue to motivate your daily store sales progress.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              decoration: AppTheme.premiumDecoration(
                label: 'Target Revenue',
                hint: 'e.g. 10000',
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('₹', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textSecondary)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 10000.0;
              if (val > 0) {
                HapticFeedback.mediumImpact();
                ref.read(dailySalesGoalProvider.notifier).setGoal(val);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save Target', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
            color: const Color(0xFFE2E8F0),
          ),
          _HeroStatItem(
            icon: isUp ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_right,
            label: 'Growth Rate',
            value: '${isUp ? '+' : ''}${growth.toStringAsFixed(1)}%',
            valueColor: isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
              Icon(icon, color: AppTheme.accentColor, size: 14),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
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
  final String subtitle;
  final Color color; // The main high-contrast active color for icon and subtitle text
  final Color backgroundColor; // Solid opaque pastel background color
  final Color borderColor; // Solid opaque border color
  final Color iconBgColor; // Solid opaque icon background color
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFF1F5F9),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: -0.2,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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

