import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/features/payment/paywall_screen.dart';
import 'package:orushops/providers/subscription_provider.dart';

class SubscriptionGuard extends ConsumerWidget {
  final Widget child;

  const SubscriptionGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);

    return subscriptionStatus.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, st) => Scaffold(
        body: Center(
          child: Text('Error checking subscription: $error'),
        ),
      ),
      data: (hasSubscription) {
        if (hasSubscription) {
          return child;
        }
        return const PaywallScreen();
      },
    );
  }
}
