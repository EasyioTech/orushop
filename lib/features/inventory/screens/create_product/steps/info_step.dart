import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orushops/features/inventory/controllers/product_form_notifier.dart';
import 'package:orushops/core/theme/app_theme.dart';
import 'package:orushops/features/inventory/screens/create_product/components/product_creation_scanner_modal.dart';

class InfoStep extends ConsumerWidget {
  const InfoStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(productFormNotifierProvider.notifier);
    final state = ref.watch(productFormNotifierProvider);
    final nameController = notifier.controllers['name']!;

    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Basic Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Enter the name, barcode, and upload photos for your item',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBigCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRODUCT INFO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: AppTheme.slate500,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: AppTheme.premiumDecoration(
                    label: 'Product Name',
                    hint: 'e.g. Sugar, Milk, Paracetamol',
                    prefixIcon: const Icon(CupertinoIcons.square_grid_2x2, color: AppTheme.primaryColor),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                if (!state.isService) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: notifier.controllers['sku']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: AppTheme.premiumDecoration(
                      label: 'Barcode / SKU (Optional)',
                      hint: 'Enter manual barcode or scan',
                      prefixIcon: const Icon(CupertinoIcons.barcode, color: AppTheme.primaryColor),
                      suffixIcon: IconButton(
                        icon: const Icon(CupertinoIcons.barcode_viewfinder, color: AppTheme.accentColor),
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          final String? scannedBarcode = await showModalBottomSheet<String>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const ProductCreationScannerModal(),
                          );
                          if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
                            notifier.applyScannedBarcode(scannedBarcode);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (state.catalogSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryDark.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: state.catalogSuggestions.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: AppTheme.slate100),
                itemBuilder: (context, index) {
                  final item = state.catalogSuggestions[index];
                  return ListTile(
                    leading: const Icon(CupertinoIcons.sparkles, color: AppTheme.primaryColor, size: 20),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: item.category != null ? Text(item.category!) : null,
                    onTap: () => notifier.applyCatalogSuggestion(item),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  onPressed: () {
                    notifier.pickProductImage(source: ImageSource.camera);
                    HapticFeedback.lightImpact();
                  },
                  icon: CupertinoIcons.camera_fill,
                  label: 'Take Photo',
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionBtn(
                  onPressed: () {
                    notifier.pickProductImage(source: ImageSource.gallery);
                    HapticFeedback.lightImpact();
                  },
                  icon: CupertinoIcons.photo_on_rectangle,
                  label: 'Choose Gallery',
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          if (state.productImage != null) ...[
            const SizedBox(height: 24),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.file(state.productImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: () => notifier.clearProductImage(),
                    child: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          _buildBigCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Is this a Service?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Repairs, labor, salon, etc.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                CupertinoSwitch(
                  value: state.isService,
                  activeTrackColor: AppTheme.accentColor,
                  onChanged: (val) => notifier.setIsService(val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigCard({required Widget child, Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildActionBtn({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
