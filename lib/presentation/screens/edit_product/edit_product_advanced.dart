// ignore_for_file: invalid_use_of_protected_member
part of '../edit_product_screen.dart';

extension _EditProductAdvanced on _EditProductScreenState {
  Widget _advancedSection() {
    if (_selectedCategory == null) return const SizedBox.shrink();
    final fields = _selectedCategory!.productFields;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('SKU / Barcode'),
          const SizedBox(height: 8),
          _field(controller: _skuController, hint: 'Scan or type barcode', icon: Icons.qr_code_rounded),

          if (fields.hasMrp) ...[
            const SizedBox(height: 20),
            _label('MRP (Printed Price)'),
            const SizedBox(height: 8),
            _field(controller: _mrpController, hint: '0', icon: Icons.tag_rounded, keyboard: TextInputType.number, prefix: '₹ '),
          ],

          if (fields.hasBrand) ...[
            const SizedBox(height: 20),
            _label('Brand Name'),
            const SizedBox(height: 8),
            _field(controller: _brandController, hint: 'e.g. Samsung, Tata', icon: Icons.branding_watermark_outlined),
          ],

          if (fields.hasWeight) ...[
            const SizedBox(height: 20),
            _label('Weight / Volume'),
            const SizedBox(height: 8),
            _field(controller: _weightController, hint: 'e.g. 500g, 1kg, 750ml', icon: Icons.scale_outlined),
          ],

          const SizedBox(height: 20),
          _toggleTile(
            title: 'Service / No Stock',
            subtitle: 'No inventory deducted on sale (repairs, labor, sessions)',
            value: _isService,
            onChanged: (v) => setState(() { _isService = v; if (v) _isLoose = false; }),
            icon: Icons.design_services_outlined,
          ),

          const SizedBox(height: 12),
          _toggleTile(
            title: 'Loose / Fractional Qty',
            subtitle: 'Sell by weight, volume, or partial units (grams, ml, tablets)',
            value: _isLoose,
            onChanged: (v) => setState(() { _isLoose = v; if (v) _isService = false; }),
            icon: Icons.scale_outlined,
          ),

          if (_currentTemplate == ProductTemplate.batchExpiry || fields.hasBatchNumber) ...[
            const SizedBox(height: 20),
            _label('Batch Number'),
            const SizedBox(height: 8),
            _field(controller: _batchNumberController, hint: 'Enter batch number', icon: Icons.layers_outlined),
          ],

          if (_currentTemplate == ProductTemplate.batchExpiry || fields.hasExpiryDate) ...[
            const SizedBox(height: 20),
            _label('Expiry Date'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _expiryDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (date != null) setState(() => _expiryDate = date);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.slate200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _expiryDate == null ? 'Select Expiry Date' : _EditProductScreenState._expiryFmt.format(_expiryDate!),
                      style: TextStyle(color: _expiryDate == null ? AppTheme.slate500 : AppTheme.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (fields.hasImei) ...[
            const SizedBox(height: 20),
            _label('IMEI Number'),
            const SizedBox(height: 8),
            _field(controller: _imeiController, hint: '15-digit IMEI', icon: Icons.phone_android_rounded, keyboard: TextInputType.number),
          ],

          if (fields.hasSerialNumber) ...[
            const SizedBox(height: 20),
            _label('Serial Number'),
            const SizedBox(height: 8),
            _field(controller: _serialNumberController, hint: 'Manufacturer Serial No', icon: Icons.vibration_rounded),
          ],

          if (fields.hasTaxRate || fields.hasHsnCode) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                if (fields.hasHsnCode)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('HSN Code'),
                        const SizedBox(height: 8),
                        _field(controller: _hsnController, hint: '123456', icon: Icons.numbers_rounded),
                      ],
                    ),
                  ),
                if (fields.hasHsnCode && fields.hasTaxRate) const SizedBox(width: 12),
                if (fields.hasTaxRate)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Tax (%)'),
                        const SizedBox(height: 8),
                        _field(controller: _taxController, hint: '18', icon: Icons.percent_rounded, keyboard: TextInputType.number),
                      ],
                    ),
                  ),
              ],
            ),
          ],

          if (fields.hasWarranty) ...[
            const SizedBox(height: 20),
            _label('Warranty'),
            const SizedBox(height: 8),
            _field(controller: _warrantyController, hint: 'e.g. 1 Year', icon: Icons.verified_user_outlined),
          ],

          if (fields.hasIsbn) ...[
            const SizedBox(height: 20),
            _label('ISBN Number'),
            const SizedBox(height: 8),
            _field(controller: _isbnController, hint: '978-3...', icon: Icons.menu_book_rounded),
          ],

          if (fields.hasSchedule) ...[
            const SizedBox(height: 20),
            _label('Drug Schedule'),
            const SizedBox(height: 4),
            Text('H = prescription, H1 = dangerous, X = narcotic', style: TextStyle(fontSize: 12, color: AppTheme.slate500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _scheduleController.text.isEmpty ? null : _scheduleController.text,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.warning_amber_outlined),
              ),
              hint: const Text('Not scheduled (OTC)'),
              items: const [
                DropdownMenuItem(value: 'H', child: Text('Schedule H — Prescription Only')),
                DropdownMenuItem(value: 'H1', child: Text('Schedule H1 — Dangerous Drug')),
                DropdownMenuItem(value: 'X', child: Text('Schedule X — Narcotic/Psychotropic')),
              ],
              onChanged: (v) => setState(() => _scheduleController.text = v ?? ''),
            ),
          ],

          if (fields.hasRecipe) ...[
            const SizedBox(height: 20),
            _label('Recipe / Ingredients'),
            const SizedBox(height: 8),
            TextField(
              controller: _recipeController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'List ingredients or cooking notes...',
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.restaurant_menu_outlined),
              ),
            ),
          ],

          if (fields.template == ProductTemplate.variantMatrix) ...[
            const SizedBox(height: 20),
            _buildVariantEditor(),
          ] else if (fields.hasSizeVariant) ...[
            const SizedBox(height: 20),
            _label('Size'),
            const SizedBox(height: 8),
            _field(controller: _sizeController, hint: 'e.g. S, M, L, XL', icon: Icons.straighten_rounded),
          ],
        ],
      ),
    );
  }
}
