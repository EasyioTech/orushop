part of '../receipt_screen.dart';





// PRIMARY ACTION — tall, solid filled, prominent
class _PrimaryAction extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? customIcon;
  final String label;
  final Color color;
  final bool isLoading;

  const _PrimaryAction({
    required this.onPressed,
    this.customIcon,
    required this.label,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    final Color buttonColor = isEnabled ? color : color.withValues(alpha: 0.5);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: isEnabled
            ? [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 4))]
            : null,
      ),
      child: Material(
        color: buttonColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              else
                customIcon ?? const SizedBox.shrink(),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.1)),
            ],
          ),
        ),
      ),
    );
  }
}

// SECONDARY ACTION — shorter, outlined style, less prominent
class _SecondaryAction extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final String label;
  final Color color;
  final bool isLoading;

  const _SecondaryAction({
    required this.onPressed,
    this.icon,
    required this.label,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    final Color activeColor = isEnabled ? color : color.withValues(alpha: 0.4);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: activeColor, width: 1.5),
        color: activeColor.withValues(alpha: 0.06),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  height: 15, width: 15,
                  child: CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation<Color>(activeColor)),
                )
              else if (icon != null)
                Icon(icon!, size: 16, color: activeColor),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: activeColor, letterSpacing: 0.1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.slate500)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.slate400, letterSpacing: 1)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primaryColor),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(30, (index) => Expanded(
        child: Container(color: index % 2 == 0 ? AppTheme.slate200 : Colors.transparent, height: 1),
      )),
    );
  }
}

class ReceiptPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);

    double x = size.width;
    double y = size.height;
    double toothWidth = 12;
    double toothHeight = 6;

    while (x > 0) {
      path.lineTo(x - toothWidth / 2, y - toothHeight);
      x -= toothWidth;
      path.lineTo(x, y);
    }

    path.lineTo(0, size.height);
    path.close();

    canvas.drawShadow(path.shift(const Offset(0, 4)), Colors.black.withValues(alpha: 0.1), 10.0, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


