// ignore_for_file: invalid_use_of_protected_member
part of '../edit_product_screen.dart';

extension _EditProductHelpers on _EditProductScreenState {
  Widget _stockCard(double stock, bool outOfStock, bool lowStock) {
    final color = outOfStock ? AppTheme.errorColor : lowStock ? AppTheme.warningColor : AppTheme.primaryColor;
    final msg = outOfStock
        ? 'Out of stock — add stock now'
        : lowStock
            ? 'Low stock — add more soon'
            : 'Stock is good';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.primaryDark.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.inventory_2_outlined, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stock % 1 == 0 ? stock.toInt() : stock.toStringAsFixed(2)} items',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                ),
                Text(msg, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitDropdown() {
    final options = _selectedCategory?.productFields.unitOptions ?? ['Piece'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(_selectedUnit) ? _selectedUnit : options.first,
          isExpanded: true,
          items: options.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
          onChanged: (val) { if (val != null) setState(() => _selectedUnit = val); },
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
    );
  }

  Widget _toggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: value ? AppTheme.primaryColor.withValues(alpha: 0.4) : AppTheme.slate200),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Icon(icon, color: value ? AppTheme.primaryColor : AppTheme.slate400, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.slate600)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    String? prefix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix,
        prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryColor),
        filled: true,
        fillColor: AppTheme.backgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
