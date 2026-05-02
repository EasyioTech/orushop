import 'package:flutter/material.dart';
import 'package:orushops/core/theme/app_theme.dart';
import '../widgets/fullscreen_onboarding_page.dart';

class OnboardingScreen17 extends StatefulWidget {
  final Function(String?) onNext;
  final VoidCallback onBack;

  const OnboardingScreen17({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingScreen17> createState() => _OnboardingScreen17State();
}

class _OnboardingScreen17State extends State<OnboardingScreen17> {
  bool _isAnnual = false;

  @override
  Widget build(BuildContext context) {
    return FullscreenOnboardingPage(
      onBack: widget.onBack,
      title: "Get OruShops+",
      subtitle: "Choose the plan that's right for your business.",
      primaryButtonText: 'Subscribe',
      onPrimaryAction: () => widget.onNext(_isAnnual ? 'annual' : 'monthly'),
      footer: TextButton(
        onPressed: () => widget.onNext(null),
        child: const Text("Skip", style: TextStyle(color: AppTheme.accentColor)),
      ),
      content: Column(
        children: [
          _buildFeatureRow(Icons.message_outlined, "In-app messaging", "Send real-time updates to keep your audience engaged."),
          _buildFeatureRow(Icons.person_outline, "Personalization", "User interface that adapts to your specific needs."),
          _buildFeatureRow(Icons.bar_chart, "Analytics and reporting", "Gain insights into audience behavior."),
          const SizedBox(height: 32),
          _buildPlanTile(
            title: "Annual",
            subtitle: "30-day free trial",
            price: "\$47.99/year",
            monthlyPrice: "\$4.00/month",
            selected: _isAnnual,
            onTap: () => setState(() => _isAnnual = true),
          ),
          const SizedBox(height: 16),
          _buildPlanTile(
            title: "Monthly",
            subtitle: "Cancel anytime",
            price: "\$5.99/month",
            monthlyPrice: "\$71.88/year",
            selected: !_isAnnual,
            onTap: () => setState(() => _isAnnual = false),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTile({
    required String title,
    required String subtitle,
    required String price,
    required String monthlyPrice,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.accentColor : Colors.grey[300]!,
            width: 2,
          ),
          color: selected ? AppTheme.accentColor.withValues(alpha: 0.02) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppTheme.accentColor : Colors.grey[400],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(monthlyPrice, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
