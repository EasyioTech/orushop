part of '../products_screen.dart';

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: onTap != null ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: onTap != null
              ? [BoxShadow(color: AppTheme.primaryDark.withValues(alpha: 0.06), blurRadius: 4)]
              : null,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}