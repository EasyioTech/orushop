import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/khata_customer.dart';
import '../../../core/repositories/owner_provider.dart';
import '../../../core/services/khata_action_service.dart';
import '../../../providers/khata_provider.dart';
import '../widgets/add_entry_sheet.dart';
import '../widgets/payment_sheet.dart';

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

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _BigAvatar extends StatelessWidget {
  final String name;
  const _BigAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value, 
          style: TextStyle(
            color: color, 
            fontWeight: FontWeight.w900, 
            fontSize: 20,
            letterSpacing: -0.5,
          )
        ),
        const SizedBox(height: 2),
        Text(
          label, 
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5), 
            fontSize: 10, 
            fontWeight: FontWeight.w800, 
            letterSpacing: 0.5,
          )
        ),
      ],
    );
  }
}

class _ModernActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModernActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 10, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _ModernLedgerTile extends StatelessWidget {
  final Map<String, dynamic> record;
  final KhataCustomer customer;
  final String storeName;
  final String storePhone;
  final String storeAddress;
  final String? upiId;

  const _ModernLedgerTile({
    required this.record,
    required this.customer,
    required this.storeName,
    required this.storePhone,
    required this.storeAddress,
    this.upiId,
  });

  void _showTransactionActions(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionActionSheet(
        record: record,
        customer: customer,
        storeName: storeName,
        storePhone: storePhone,
        storeAddress: storeAddress,
        upiId: upiId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = record['type'] as String;
    final recordType = record['recordType'] as String;
    final amount = (record['amount'] as num).toDouble();
    final note = record['note'] as String;
    final createdAt = DateTime.parse(record['createdAt'] as String);
    final isCredit = type == 'credit';
    final isPayment = recordType == 'payment';
    
    final color = isCredit ? const Color(0xFF2D9E64) : const Color(0xFFD64545);
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return InkWell(
      onTap: () => _showTransactionActions(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.3)),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPayment ? Icons.account_balance_wallet_rounded : isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.isEmpty ? (isPayment ? 'Payment' : 'General Entry') : note, 
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, h:mm a').format(createdAt),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmt.format(amount),
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPayment ? 'PAYMENT' : isCredit ? 'CREDIT' : 'DEBIT',
                    style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditCustomerSheet extends ConsumerStatefulWidget {
  final KhataCustomer customer;
  const _EditCustomerSheet({required this.customer});

  @override
  ConsumerState<_EditCustomerSheet> createState() => _EditCustomerSheetState();
}

class _EditCustomerSheetState extends ConsumerState<_EditCustomerSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _limitCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.customer.name);
    _phoneCtrl = TextEditingController(text: widget.customer.phone);
    _addressCtrl = TextEditingController(text: widget.customer.address ?? '');
    _notesCtrl = TextEditingController(text: widget.customer.notes ?? '');
    _limitCtrl = TextEditingController(text: widget.customer.creditLimit > 0 ? widget.customer.creditLimit.toStringAsFixed(0) : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _addressCtrl.dispose();
    _notesCtrl.dispose(); _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final updated = widget.customer.copyWith(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      creditLimit: double.tryParse(_limitCtrl.text) ?? 0,
    );
    final ok = await ref.read(khataListProvider.notifier).updateCustomer(updated);
    if (!mounted) return;
    if (ok) {
      ref.read(khataDetailProvider(widget.customer.id).notifier).load();
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.slate300.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Icon(Icons.edit_rounded, color: AppTheme.navy900, size: 24),
              SizedBox(width: 12),
              Text(
                'Edit Customer Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy900),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          _field(_nameCtrl, 'Customer Name', Icons.person_outline_rounded),
          const SizedBox(height: 16),
          _field(_phoneCtrl, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _field(_limitCtrl, 'Credit Limit ₹', Icons.credit_card_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 16),
          _field(_addressCtrl, 'Location Address', Icons.location_on_outlined),
          const SizedBox(height: 16),
          _field(_notesCtrl, 'Internal Notes', Icons.note_outlined, maxLines: 2),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navy900,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _saving
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Update Account', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.navy900),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.slate500, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: AppTheme.slate400),
        filled: true,
        fillColor: AppTheme.slate50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.navy900, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── STATEMENT & REMINDERS SHEET ──────────────────────────────────────────────

class _StatementRemindersSheet extends StatefulWidget {
  final KhataCustomer customer;
  final List<Map<String, dynamic>> ledger;
  final String storeName;
  final String storePhone;
  final String storeAddress;
  final String? upiId;

  const _StatementRemindersSheet({
    required this.customer,
    required this.ledger,
    required this.storeName,
    required this.storePhone,
    required this.storeAddress,
    this.upiId,
  });

  @override
  State<_StatementRemindersSheet> createState() => _StatementRemindersSheetState();
}

class _StatementRemindersSheetState extends State<_StatementRemindersSheet> {
  final _actionService = KhataActionService();
  bool _isLoading = false;

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppTheme.navy900,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.customer.balance;
    final isReceivable = balance > 0;
    final balanceStr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(balance.abs());

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.slate300.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.share_rounded, color: AppTheme.navy900, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share Statement / Reminders',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.navy900, letterSpacing: -0.5),
                    ),
                    Text(
                      widget.customer.name,
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary.withValues(alpha: 0.6), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Mini outstanding status card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isReceivable ? const Color(0xFFD64545).withValues(alpha: 0.06) : const Color(0xFF2D9E64).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isReceivable ? const Color(0xFFD64545).withValues(alpha: 0.15) : const Color(0xFF2D9E64).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT OUTSTANDING',
                      style: TextStyle(
                        fontSize: 9, 
                        fontWeight: FontWeight.w900, 
                        color: isReceivable ? const Color(0xFFD64545) : const Color(0xFF2D9E64),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isReceivable ? 'Customer owes you' : balance < 0 ? 'You owe customer' : 'Settled account',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.navy900),
                    ),
                  ],
                ),
                Text(
                  balanceStr,
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.w900, 
                    color: isReceivable ? const Color(0xFFD64545) : const Color(0xFF2D9E64),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppTheme.navy900, strokeWidth: 3),
              ),
            )
          else ...[
            // Quick Send Options
            _reminderActionTile(
              label: 'Direct WhatsApp Reminder',
              subtitle: 'Send instant text message directly to customer',
              icon: Icons.chat_bubble_outline_rounded,
              color: const Color(0xFF2D9E64),
              onTap: () async {
                setState(() => _isLoading = true);
                await _actionService.shareLedgerStatementWhatsApp(
                  customerName: widget.customer.name,
                  customerPhone: widget.customer.phone,
                  currentBalance: balance,
                  storeName: widget.storeName,
                  upiId: widget.upiId,
                );
                setState(() => _isLoading = false);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _reminderActionTile(
              label: 'Direct SMS Reminder',
              subtitle: 'Send direct template message via cellular network',
              icon: Icons.sms_outlined,
              color: Colors.indigo,
              onTap: () async {
                setState(() => _isLoading = true);
                await _actionService.sendLedgerStatementSms(
                  customerName: widget.customer.name,
                  customerPhone: widget.customer.phone,
                  currentBalance: balance,
                  storeName: widget.storeName,
                  upiId: widget.upiId,
                );
                setState(() => _isLoading = false);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _reminderActionTile(
              label: 'Share PDF Account Statement',
              subtitle: 'Generate A4 Ledger Statement with running balance',
              icon: Icons.picture_as_pdf_outlined,
              color: Colors.redAccent,
              onTap: () async {
                setState(() => _isLoading = true);
                try {
                  await _actionService.shareLedgerStatementPdf(
                    customerName: widget.customer.name,
                    customerPhone: widget.customer.phone,
                    ledger: widget.ledger,
                    storeName: widget.storeName,
                    storePhone: widget.storePhone,
                    storeAddress: widget.storeAddress,
                    upiId: widget.upiId,
                    currentBalance: balance,
                  );
                } catch (e) {
                  _toast('Failed to share PDF statement: $e');
                }
                setState(() => _isLoading = false);
                Navigator.pop(context);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _reminderActionTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.navy900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── INDIVIDUAL TRANSACTION ACTION SHEET ──────────────────────────────────────

class _TransactionActionSheet extends StatefulWidget {
  final Map<String, dynamic> record;
  final KhataCustomer customer;
  final String storeName;
  final String storePhone;
  final String storeAddress;
  final String? upiId;

  const _TransactionActionSheet({
    required this.record,
    required this.customer,
    required this.storeName,
    required this.storePhone,
    required this.storeAddress,
    this.upiId,
  });

  @override
  State<_TransactionActionSheet> createState() => _TransactionActionSheetState();
}

class _TransactionActionSheetState extends State<_TransactionActionSheet> {
  final _actionService = KhataActionService();
  bool _isLoading = false;

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppTheme.navy900,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordType = widget.record['recordType'] as String;
    final type = widget.record['type'] as String;
    final amount = (widget.record['amount'] as num).toDouble();
    final note = widget.record['note'] as String;
    final createdAt = DateTime.parse(widget.record['createdAt'] as String);

    final isCredit = type == 'credit';
    final isPayment = recordType == 'payment';
    final color = isCredit ? const Color(0xFF2D9E64) : const Color(0xFFD64545);
    final amtStr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.slate300.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isPayment ? Icons.account_balance_wallet_rounded : isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
                  color: color, size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.isEmpty ? (isPayment ? 'Payment Received' : 'General Entry') : note,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.navy900, letterSpacing: -0.5),
                    ),
                    Text(
                      DateFormat('MMMM d, yyyy • h:mm a').format(createdAt),
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Text(
                amtStr,
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppTheme.navy900, strokeWidth: 3),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    label: 'WhatsApp',
                    icon: Icons.chat_bubble_outline_rounded,
                    color: const Color(0xFF2D9E64),
                    onTap: () async {
                      setState(() => _isLoading = true);
                      await _actionService.shareLedgerEntryToWhatsAppWithSmsFallback(
                        customerName: widget.customer.name,
                        customerPhone: widget.customer.phone,
                        amount: amount,
                        recordType: recordType,
                        type: type,
                        note: note,
                        createdAt: createdAt,
                        storeName: widget.storeName,
                        storePhone: widget.storePhone,
                        storeAddress: widget.storeAddress,
                        upiId: widget.upiId,
                        currentBalance: widget.customer.balance,
                        receiptImageBytes: null,
                        onRedirectingToSms: () => _toast('Opening SMS fallback...'),
                      );
                      setState(() => _isLoading = false);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    label: 'SMS Text',
                    icon: Icons.sms_outlined,
                    color: Colors.indigo,
                    onTap: () async {
                      setState(() => _isLoading = true);
                      await _actionService.sendLedgerEntrySms(
                        customerName: widget.customer.name,
                        customerPhone: widget.customer.phone,
                        amount: amount,
                        recordType: recordType,
                        type: type,
                        note: note,
                        createdAt: createdAt,
                        storeName: widget.storeName,
                        currentBalance: widget.customer.balance,
                      );
                      setState(() => _isLoading = false);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    label: 'Share PDF',
                    icon: Icons.picture_as_pdf_outlined,
                    color: Colors.redAccent,
                    onTap: () async {
                      setState(() => _isLoading = true);
                      try {
                        await _actionService.shareLedgerEntryPdf(
                          customerName: widget.customer.name,
                          customerPhone: widget.customer.phone,
                          amount: amount,
                          recordType: recordType,
                          type: type,
                          note: note,
                          createdAt: createdAt,
                          storeName: widget.storeName,
                          storePhone: widget.storePhone,
                          storeAddress: widget.storeAddress,
                          upiId: widget.upiId,
                          currentBalance: widget.customer.balance,
                        );
                      } catch (e) {
                        _toast('Failed to generate PDF: $e');
                      }
                      setState(() => _isLoading = false);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    label: 'Print Voucher',
                    icon: Icons.print_rounded,
                    color: AppTheme.navy900,
                    onTap: () async {
                      setState(() => _isLoading = true);
                      try {
                        await _actionService.printLedgerEntry(
                          customerName: widget.customer.name,
                          customerPhone: widget.customer.phone,
                          amount: amount,
                          recordType: recordType,
                          type: type,
                          note: note,
                          createdAt: createdAt,
                          storeName: widget.storeName,
                          storePhone: widget.storePhone,
                          storeAddress: widget.storeAddress,
                          upiId: widget.upiId,
                          currentBalance: widget.customer.balance,
                        );
                      } catch (e) {
                        _toast('Failed to print: $e');
                      }
                      setState(() => _isLoading = false);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 12, letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
