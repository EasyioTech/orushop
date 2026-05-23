// ignore_for_file: invalid_use_of_protected_member
part of '../products_screen.dart';

extension _CheckoutCustomerDialog on _CheckoutSheetState {
  void _showCustomerDialog(VoidCallback onSaved) {
    final phoneCtrl = TextEditingController(text: _customerPhone);
    final nameCtrl = TextEditingController(text: _customerName);
    final customerRepo = ref.read(customerRepositoryProvider);
    final phoneFocusNode = FocusNode();
    List<Customer> suggestions = [];

    Future.delayed(const Duration(milliseconds: 350), () {
      if (phoneFocusNode.canRequestFocus) {
        phoneFocusNode.requestFocus();
      }
    });

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            left: 24,
            right: 24,
            top: 12,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person_add_rounded, color: AppTheme.primaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Lookup',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                        Text(
                          'Search existing or add new customer',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ),
                ],
              ),
              const Text(
                'PHONE NUMBER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.slate500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                focusNode: phoneFocusNode,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: 1.5),
                decoration: InputDecoration(
                  hintText: '00000 00000',
                  hintStyle: TextStyle(color: AppTheme.slate300, letterSpacing: 1.5),
                  prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppTheme.primaryColor),
                  prefixText: '+91 ',
                  prefixStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w900, fontSize: 18),
                  filled: true,
                  fillColor: AppTheme.slate50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppTheme.slate200, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2.5),
                  ),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (val) async {
                  if (val.length >= 3) {
                    final results = await customerRepo.searchByQuery(val);
                    setD(() => suggestions = results);
                  } else {
                    setD(() => suggestions = []);
                  }
                },
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuart,
                constraints: BoxConstraints(
                  maxHeight: suggestions.isEmpty ? 0 : 200,
                ),
                child: suggestions.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 180),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: suggestions.length,
                              separatorBuilder: (_, _) => Padding(
                                padding: const EdgeInsets.only(left: 56),
                                child: Divider(height: 1, thickness: 1, color: AppTheme.slate100),
                              ),
                              itemBuilder: (ctx, i) {
                                final c = suggestions[i];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                  dense: true,
                                  leading: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppTheme.primaryColor.withValues(alpha: 0.1), AppTheme.primaryColor.withValues(alpha: 0.05)],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    c.name, 
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.slate900),
                                  ),
                                  subtitle: Text(
                                    c.phone, 
                                    style: const TextStyle(fontSize: 11, color: AppTheme.slate500, fontWeight: FontWeight.w600),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.slate300),
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    setD(() {
                                      String p = c.phone.replaceAll(RegExp(r'\D'), '');
                                      if (p.length > 10 && p.startsWith('91')) p = p.substring(2);
                                      phoneCtrl.text = p;
                                      nameCtrl.text = c.name;
                                      suggestions = [];
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 16),
              const Text(
                'CUSTOMER NAME (OPTIONAL)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.slate500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'John Doe',
                  hintStyle: TextStyle(color: AppTheme.slate300),
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.slate400),
                  filled: true,
                  fillColor: AppTheme.slate50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppTheme.slate200, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2.5),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              if (MediaQuery.of(ctx).viewInsets.bottom == 0) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      String phone = phoneCtrl.text.trim();
                      final name = nameCtrl.text.trim();

                      phone = phone.replaceAll(RegExp(r'\D'), '');
                      if (phone.length == 12 && phone.startsWith('91')) {
                        phone = phone.substring(2);
                      }

                      if (phone.length != 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid 10-digit mobile number'),
                            backgroundColor: AppTheme.errorColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _customerPhone = phone;
                        _customerName = name.isEmpty ? null : name;
                      });
                      Navigator.pop(ctx);
                      onSaved();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 8,
                      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('PROCEED TO PAYMENT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        SizedBox(width: 12),
                        Icon(Icons.arrow_forward_ios_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }
}