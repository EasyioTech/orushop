import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:orushops/core/services/revenue_cat_service.dart';
import 'package:orushops/providers/subscription_provider.dart';
import 'package:intl/intl.dart';

class CustomerCenterScreen extends ConsumerStatefulWidget {
  final VoidCallback? onDismiss;

  const CustomerCenterScreen({
    super.key,
    this.onDismiss,
  });

  @override
  ConsumerState<CustomerCenterScreen> createState() => _CustomerCenterScreenState();
}

class _CustomerCenterScreenState extends ConsumerState<CustomerCenterScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final customerInfoAsync = ref.watch(customerInfoProvider);
    final oruShopsProAsync = ref.watch(oruShopsProInfoProvider);
    final hasProAccess = ref.watch(oruShopsProAccessProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Management'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onDismiss ?? () => Navigator.pop(context),
          ),
        ],
      ),
      body: customerInfoAsync.when(
        data: (customerInfo) {
          if (customerInfo == null) {
            return const Center(child: Text('Unable to load customer info'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active Subscription Card
                _buildSubscriptionCard(context, customerInfo, oruShopsProAsync, hasProAccess),
                const SizedBox(height: 24),

                // Active Entitlements
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Entitlements',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildEntitlements(customerInfo),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Actions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _restorePurchases,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Restore Purchases'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Account Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Info',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoTile(
                        'User ID',
                        customerInfo.originalAppUserId,
                      ),
                      _buildInfoTile(
                        'Request Date',
                        customerInfo.requestDate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(customerInfoProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    CustomerInfo customerInfo,
    AsyncValue<EntitlementInfo?> oruShopsProAsync,
    AsyncValue<bool> hasProAccess,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OruShops Pro',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      hasProAccess.when(
                        data: (hasAccess) => Text(
                          hasAccess ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasAccess ? Colors.green : Colors.grey,
                          ),
                        ),
                        loading: () => const SizedBox(
                          height: 12,
                          width: 50,
                          child: LinearProgressIndicator(),
                        ),
                        error: (error, stack) => const Text(
                          'Unknown',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              oruShopsProAsync.when(
                data: (entitlement) {
                  if (entitlement == null) {
                    return const Text('No active subscription');
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entitlement.expirationDate != null)
                        _buildInfoTile('Expires', entitlement.expirationDate!),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Unable to load details'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntitlements(CustomerInfo customerInfo) {
    final activeEntitlements = customerInfo.entitlements.active;

    if (activeEntitlements.isEmpty) {
      return const Text('No active entitlements');
    }

    return Column(
      children: activeEntitlements.entries.map((entry) {
        final entitlement = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                if (entitlement.expirationDate != null)
                  Text(
                    'Expires: ${entitlement.expirationDate}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoTile(String label, dynamic value) {
    final displayValue = value is DateTime ? _formatDate(value) : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            displayValue,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

    try {
      final rcService = RevenueCatService.instance;
      await rcService.restorePurchases();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(customerInfoProvider);
        ref.invalidate(oruShopsProAccessProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
