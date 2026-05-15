import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/compliance_service.dart';

class PrivacyPolicyModal extends ConsumerWidget {
  final VoidCallback onAccept;

  const PrivacyPolicyModal({required this.onAccept, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complianceService = ref.read(complianceServiceProvider);

    return AlertDialog(
      title: const Text('Privacy Policy'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We respect your privacy. OruShops collects minimal data needed to operate your POS system:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Account email and authentication data (stored securely on Firebase)'),
            _buildBulletPoint('Your shop inventory and sales data (encrypted and stored locally)'),
            _buildBulletPoint('Camera access only for QR/barcode scanning (not stored)'),
            _buildBulletPoint('Biometric data never leaves your device'),
            const SizedBox(height: 12),
            Text(
              'We do NOT:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            _buildBulletPoint('Sell or share your data with third parties'),
            _buildBulletPoint('Use your data for advertising'),
            _buildBulletPoint('Store payment information (handled by RevenueCat)'),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => complianceService.launchPrivacyPolicy(),
              child: const Text('Read Full Policy'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Decline'),
        ),
        ElevatedButton(
          onPressed: () {
            complianceService.acceptPrivacy();
            Navigator.pop(context);
            onAccept();
          },
          child: const Text('Accept'),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 18)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class TermsOfServiceModal extends ConsumerWidget {
  final VoidCallback onAccept;

  const TermsOfServiceModal({required this.onAccept, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complianceService = ref.read(complianceServiceProvider);

    return AlertDialog(
      title: const Text('Terms of Service'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. License: You may use OruShops for personal and commercial POS operations.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              '2. Responsibility: You are responsible for keeping your login credentials secure.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              '3. Data Deletion: You may request deletion of all your data at any time from Settings > Account.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              '4. Prohibited Use: Do not use OruShops for illegal activities or to harm others.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => complianceService.launchTermsOfService(),
              child: const Text('Read Full Terms'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Decline'),
        ),
        ElevatedButton(
          onPressed: () {
            complianceService.acceptTerms();
            Navigator.pop(context);
            onAccept();
          },
          child: const Text('Accept'),
        ),
      ],
    );
  }
}

class AnalyticsConsentModal extends ConsumerWidget {
  final VoidCallback onAccept;

  const AnalyticsConsentModal({required this.onAccept, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complianceService = ref.read(complianceServiceProvider);

    return AlertDialog(
      title: const Text('Analytics & Crash Reporting'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help us improve OruShops by sharing crash reports and usage analytics.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              'What we collect:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '• App crashes and errors (anonymized)',
              style: TextStyle(fontSize: 13),
            ),
            Text(
              '• Feature usage patterns (not personal data)',
              style: TextStyle(fontSize: 13),
            ),
            Text(
              '• Device type and OS version',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              'You can disable this anytime in Settings > Privacy.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            complianceService.acceptAnalytics(false);
            Navigator.pop(context);
            onAccept();
          },
          child: const Text('No Thanks'),
        ),
        ElevatedButton(
          onPressed: () {
            complianceService.acceptAnalytics(true);
            Navigator.pop(context);
            onAccept();
          },
          child: const Text('Help Us Improve'),
        ),
      ],
    );
  }
}
