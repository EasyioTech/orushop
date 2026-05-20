part of '../products_screen.dart';

// ── Qty Input Bottom Sheet ────────────────────────────────────────────────────

class _QtyInputSheet extends StatefulWidget {
  final Product product;
  final double remaining; // double.infinity for services

  const _QtyInputSheet({required this.product, required this.remaining});

  @override
  State<_QtyInputSheet> createState() => _QtyInputSheetState();
}

class _QtyInputSheetState extends State<_QtyInputSheet> {
  final _controller = TextEditingController();
  String _display = '';
  String? _error;

  /// When true the numpad counts whole packs (e.g. Strips); otherwise it
  /// counts the product's base unit (e.g. Tablets).
  bool _packMode = false;

  /// Pack/wholesale unit name, or null when the product has none.
  String? get _packName {
    final p = widget.product.packagingUnit;
    return (p != null && p.trim().isNotEmpty) ? p.trim() : null;
  }

  /// Base units contained in one pack. Always >= 1.
  double get _factor {
    final f = widget.product.conversionFactor ?? 1;
    return f > 0 ? f : 1;
  }

  /// A pack toggle is only meaningful when a pack holds more than one unit.
  bool get _hasPack => _packName != null && _factor > 1;

  /// The quantity in base units, regardless of which input mode is active.
  double get _baseQty {
    final parsed = double.tryParse(_display) ?? 0;
    return _packMode ? parsed * _factor : parsed;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setPackMode(bool pack) {
    if (_packMode == pack) return;
    setState(() {
      _packMode = pack;
      _display = '';
      _error = null;
    });
  }

  void _tap(String value) {
    setState(() {
      if (value == '⌫') {
        if (_display.isNotEmpty) _display = _display.substring(0, _display.length - 1);
      } else if (value == '.') {
        if (!_display.contains('.')) _display += '.';
      } else {
        if (_display == '0') {
          _display = value;
        } else {
          _display += value;
        }
      }
      _validateDisplay();
    });
  }

  void _validateDisplay() {
    final parsed = double.tryParse(_display);
    if (_display.isEmpty || parsed == null || parsed <= 0) {
      _error = null; // empty = not yet entered, keep button disabled silently
    } else if (widget.remaining != double.infinity && _baseQty > widget.remaining) {
      _error = 'Only ${_fmtQty(widget.remaining)} ${widget.product.unit} left';
    } else {
      _error = null;
    }
  }

  String _fmtQty(double q) {
    if (q == q.truncateToDouble()) return q.toInt().toString();
    return q.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  bool get _canAdd {
    final parsed = double.tryParse(_display);
    return parsed != null && parsed > 0 && _error == null;
  }

  Widget _numKey(String label, {Color? color}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _tap(label),
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: label == '⌫' ? AppTheme.errorColor.withValues(alpha: 0.1) : AppTheme.slate100,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          height: 64,
          child: Text(
            label,
            style: TextStyle(
              fontSize: label == '⌫' ? 22 : 26,
              fontWeight: FontWeight.w700,
              color: color ?? (label == '⌫' ? AppTheme.errorColor : AppTheme.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _packToggle({required String label, required bool selected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoose = widget.product.isLoose;
    final unit = widget.product.unit;
    final price = widget.product.price;
    final parsed = double.tryParse(_display);
    // What the numpad currently counts, and the matching per-unit price.
    final dispUnit = _packMode ? _packName! : unit;
    final dispPrice = _packMode ? price * _factor : price;
    final previewAmount = parsed != null ? _baseQty * price : null;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.slate300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),

            // Product name + unit
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isLoose ? 'How much? (in $dispUnit)' : 'How many?',
                          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${dispPrice % 1 == 0 ? dispPrice.toInt() : dispPrice.toStringAsFixed(2)} / $dispUnit',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                      ),
                      if (widget.remaining != double.infinity)
                        Text(
                          'Stock: ${_fmtQty(widget.remaining)} $unit',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pack / unit selector — only when a pack holds more than one unit.
            if (_hasPack) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.slate100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _packToggle(label: 'By $unit', selected: !_packMode, onTap: () => _setPackMode(false)),
                      _packToggle(
                        label: 'By ${_packName!}',
                        selected: _packMode,
                        onTap: () => _setPackMode(true),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '1 ${_packName!} = ${_fmtQty(_factor)} $unit',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Big display
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: _error != null ? AppTheme.errorColor.withValues(alpha: 0.1) : AppTheme.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _error != null ? AppTheme.errorColor.withValues(alpha: 0.3) : AppTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _display.isEmpty ? '0' : _display,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: _display.isEmpty ? AppTheme.slate300 : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Text(dispUnit, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 28),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_error!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            if (previewAmount != null && _error == null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 28),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _packMode && parsed != null && parsed > 0
                        ? '${_fmtQty(_baseQty)} $unit  •  = ₹${previewAmount % 1 == 0 ? previewAmount.toInt() : previewAmount.toStringAsFixed(2)}'
                        : '= ₹${previewAmount % 1 == 0 ? previewAmount.toInt() : previewAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.successColor),
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Numpad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Row(children: ['1', '2', '3'].map((k) => _numKey(k)).toList()),
                  Row(children: ['4', '5', '6'].map((k) => _numKey(k)).toList()),
                  Row(children: ['7', '8', '9'].map((k) => _numKey(k)).toList()),
                  Row(children: [
                    isLoose ? _numKey('.') : Expanded(child: SizedBox(height: 64)),
                    _numKey('0'),
                    _numKey('⌫'),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Add button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _canAdd ? () => Navigator.pop(context, _baseQty) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    disabledBackgroundColor: AppTheme.slate200,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: Text(
                    _canAdd
                        ? 'Add to Bill  +${_fmtQty(_baseQty)} $unit'
                        : 'Enter Qty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _canAdd ? Colors.white : AppTheme.slate400,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
