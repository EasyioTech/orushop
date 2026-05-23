part of '../home_screen.dart';

// ── SUB-COMPONENTS ───────────────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  const _ProfileAvatar({required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: photoUrl == null ? const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ) : null,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        image: photoUrl != null
            ? DecorationImage(
                image: NetworkImage(photoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: photoUrl == null
          ? Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'P',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
              ),
            )
          : null,
    );
  }
}



// ── SALES HERO CARD ──────────────────────────────────────────────────────────

class _SalesHeroCard extends ConsumerWidget {
  static final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  final double revenue;
  final int count;
  final double growth;
  final String greeting;
  final String name;
  final String? photoUrl;
  final String date;

  const _SalesHeroCard({
    required this.revenue,
    required this.count,
    required this.growth,
    required this.greeting,
    required this.name,
    this.photoUrl,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = _fmt;
    final topPadding = MediaQuery.of(context).padding.top;
    
    // Read dynamic sales target
    final target = ref.watch(dailySalesGoalProvider);
    final rawPercent = target > 0 ? (revenue / target) : 0.0;
    final percent = rawPercent.clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF064E3B)], // Premium Emerald Green
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Integrated Top Header ─────────────────────────────────────
          Row(
            children: [
              _ProfileAvatar(name: name, photoUrl: photoUrl),
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
                        color: Colors.white,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
          const SizedBox(height: 24),

          // ── Main Today's Revenue Info ────────────────────────────────
          Row(
            children: [
              Icon(CupertinoIcons.sparkles, color: Colors.white.withValues(alpha: 0.8), size: 13),
              const SizedBox(width: 6),
              Text(
                'TODAY\'S REVENUE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                fmt.format(revenue),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2.0,
                  height: 1.1,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SalesHistoryScreen()),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: const _OverlappingAvatars(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Interactive Daily Target Progress Bar ───────────────────
          GestureDetector(
            onTap: () => _showEditGoalDialog(context, ref, target),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.flag_fill, color: Colors.white.withValues(alpha: 0.9), size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Daily Target: ${fmt.format(target)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(CupertinoIcons.pencil_circle_fill, color: Colors.white.withValues(alpha: 0.5), size: 14),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${(rawPercent * 100).toStringAsFixed(0)}% achieved',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Sleek glowing progress track
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percent,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)], // Vibrant Amber/Gold
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 0),
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
          const SizedBox(height: 16),

          // ── Frost Glass Stats Capsule ────────────────────────────────
          _HeroStatsRow(count: count, growth: growth),
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
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
            color: Colors.white.withValues(alpha: 0.2),
          ),
          _HeroStatItem(
            icon: isUp ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_right,
            label: 'Growth Rate',
            value: '${isUp ? '+' : ''}${growth.toStringAsFixed(1)}%',
            valueColor: isUp ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
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
              Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 14),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w700),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

// ── OVERLAPPING AVATARS ──────────────────────────────────────────────────────

class _OverlappingAvatars extends StatelessWidget {
  const _OverlappingAvatars();

  @override
  Widget build(BuildContext context) {
    // Monochromatic/analogous colors based on Emerald green
    final colors = [
      const Color(0xFF047857), // Deep emerald
      const Color(0xFF059669), // Emerald
      const Color(0xFF10B981), // Light emerald
      const Color(0xFF34D399), // Sea green
      const Color(0xFF0D9488), // Teal
    ];
    final initials = ['S', 'M', 'R', 'K', 'A'];

    // 5 avatars total
    final count = colors.length;
    const avatarSize = 34.0;
    const overlap = 14.0;
    
    // The width is the size of one avatar, plus the visible part of the remaining avatars
    final totalWidth = avatarSize + ((count - 1) * (avatarSize - overlap));

    return SizedBox(
      width: totalWidth,
      height: avatarSize,
      child: Stack(
        children: List.generate(count, (index) {
          // We want the left-most avatar to be on top.
          // Stack paints first child at the bottom.
          // So the child at index 0 is painted at the bottom (right-most visually).
          // And index `count - 1` is painted at the top (left-most visually).
          final i = (count - 1) - index; 
          
          return Positioned(
            left: i * (avatarSize - overlap),
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[i],
                border: Border.all(color: const Color(0xFF064E3B), width: 2.5),
              ),
              child: Center(
                child: Text(
                  initials[i],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
