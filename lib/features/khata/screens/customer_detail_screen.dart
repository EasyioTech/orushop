import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/khata_customer.dart';
import '../../../core/repositories/owner_provider.dart';
import '../../../core/repositories/sale_repository.dart';
import '../../../presentation/screens/receipt_screen.dart';
import '../../../core/services/khata_action_service.dart';
import '../../../providers/khata_provider.dart';
import '../widgets/add_entry_sheet.dart';
import '../widgets/payment_sheet.dart';

part 'customer_detail/customer_detail_widgets.dart';
part 'customer_detail/edit_customer_sheet.dart';
part 'customer_detail/statement_reminders_sheet.dart';
part 'customer_detail/transaction_action_sheet.dart';
class CustomerDetailScreen extends ConsumerWidget {
  final int customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(khataDetailProvider(customerId));
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: state.isLoading && state.customer == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor, strokeWidth: 3))
          : state.customer == null
              ? const Center(child: Text('Customer not found'))
              : _DetailBody(
                  customerId: customerId,
                  customer: state.customer!,
                  ledger: state.ledger,
                  fmt: fmt,
                ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final int customerId;
  final KhataCustomer customer;
  final List<Map<String, dynamic>> ledger;
  final NumberFormat fmt;

  const _DetailBody({
    required this.customerId,
    required this.customer,
    required this.ledger,
    required this.fmt,
  });

  void _showAddEntry(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEntrySheet(customerId: customerId, customerName: customer.name),
    );
  }

  void _showPayment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentSheet(
        customerId: customerId,
        customerName: customer.name,
        currentBalance: customer.balance,
      ),
    );
  }

  void _showEditCustomer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditCustomerSheet(customer: customer),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = customer.balance;
    final isReceivable = balance > 0;
    final isSettled = balance == 0;
    final balanceColor = isSettled
        ? AppTheme.textSecondary
        : isReceivable
            ? AppTheme.successColor
            : AppTheme.errorColor;

    // Fetch store details dynamically
    final ownerDetailsAsync = ref.watch(ownerDetailsStreamProvider);
    final ownerDetails = ownerDetailsAsync.valueOrNull;
    final storeName = ownerDetails?['storeName'] as String? ?? 'OruShops Store';
    final storePhone = ownerDetails?['phoneNumber'] as String? ?? '';
    final storeAddress = ownerDetails?['address'] as String? ?? '';
    final upiId = ownerDetails?['upiId'] as String?;
    final receiptBannerTitle = ownerDetails?['receiptBannerTitle'] as String?;

    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text('Customer Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_rounded, size: 22),
              tooltip: 'Reminders & Statement',
              onPressed: () {
                HapticFeedback.mediumImpact();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _StatementRemindersSheet(
                    customer: customer,
                    ledger: ledger,
                    storeName: storeName,
                    storePhone: storePhone,
                    storeAddress: storeAddress,
                    upiId: upiId,
                    receiptBannerTitle: receiptBannerTitle,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, size: 24),
              tooltip: 'Edit Profile',
              onPressed: () => _showEditCustomer(context),
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _BigAvatar(name: customer.name),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                customer.phone,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _HeaderStat(label: 'NET BALANCE', value: fmt.format(balance.abs()), color: balanceColor),
                          _HeaderStat(label: 'LIMIT', value: fmt.format(customer.creditLimit), color: Colors.white70),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Status banner
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: balanceColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: balanceColor.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(
                  isSettled ? Icons.check_circle_rounded : isReceivable ? Icons.info_rounded : Icons.info_rounded,
                  color: balanceColor, size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isSettled
                        ? 'Account is fully settled'
                        : isReceivable
                            ? '${customer.name} owes you ${fmt.format(balance)}'
                            : 'You owe ${customer.name} ${fmt.format(balance.abs())}',
                    style: TextStyle(color: balanceColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action buttons
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _ModernActionButton(
                    label: 'GIVE CREDIT',
                    icon: Icons.remove_circle_outline_rounded,
                    color: const Color(0xFFD64545),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _showAddEntry(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModernActionButton(
                    label: 'GOT PAYMENT',
                    icon: Icons.add_circle_outline_rounded,
                    color: const Color(0xFF2D9E64),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _showPayment(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Ledger section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              children: [
                Text('TRANSACTIONS', 
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w900, 
                    color: AppTheme.textPrimary.withValues(alpha: 0.4),
                    letterSpacing: 1,
                  )
                ),
                const Spacer(),
                Text('${ledger.length} ENTRIES', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary.withValues(alpha: 0.5))
                ),
              ],
            ),
          ),
        ),

        // Ledger list
        ledger.isEmpty
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    children: [
                      Icon(Icons.history_rounded, size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.1)),
                      const SizedBox(height: 12),
                      Text('No history found', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 13)),
                    ],
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _ModernLedgerTile(
                    record: ledger[i],
                    customer: customer,
                    storeName: storeName,
                    storePhone: storePhone,
                    storeAddress: storeAddress,
                    upiId: upiId,
                  ),
                  childCount: ledger.length,
                ),
              ),

        // Sales History section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Row(
              children: [
                Text('SALES HISTORY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary.withValues(alpha: 0.4),
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.receipt_long_rounded, size: 14, color: AppTheme.accentColor),
              ],
            ),
          ),
        ),

        _SalesHistorySliver(
          phone: customer.phone,
          storeName: storeName,
          storePhone: storePhone,
          storeAddress: storeAddress,
          upiId: upiId,
          ownerDetails: ownerDetails,
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _SalesHistorySliver extends ConsumerWidget {
  final String phone;
  final String storeName;
  final String storePhone;
  final String storeAddress;
  final String? upiId;
  final Map<String, dynamic>? ownerDetails;

  const _SalesHistorySliver({
    required this.phone,
    required this.storeName,
    required this.storePhone,
    required this.storeAddress,
    required this.upiId,
    required this.ownerDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(customerSalesByPhoneProvider(phone));
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return salesAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentColor)),
        ),
      ),
      error: (e, st) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (sales) {
        if (sales.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_outlined, size: 32, color: AppTheme.textSecondary.withValues(alpha: 0.2)),
                    const SizedBox(width: 16),
                    Text('No sales recorded', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 13)),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final sale = sales[i];
              final dateFmt = DateFormat('d MMM yyyy, h:mm a');
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      final saleRepo = SaleRepository();
                      final items = await saleRepo.getSaleItems(sale.id);
                      if (!context.mounted) return;
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ReceiptScreen(
                          sale: sale,
                          items: items,
                          storeName: storeName,
                          storePhone: storePhone,
                          storeAddress: storeAddress,
                          upiId: upiId,
                        ),
                      ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.receipt_rounded, color: AppTheme.accentColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bill #${sale.id}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                                Text(
                                  dateFmt.format(sale.createdAt),
                                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                fmt.format(sale.finalAmount),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.successColor),
                              ),
                              Text(
                                sale.paymentMethod.toUpperCase(),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.slate300),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            childCount: sales.length,
          ),
        );
      },
    );
  }
}

