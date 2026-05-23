import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/owner_provider.dart';
import '../../../core/repositories/owner_repository.dart';

class ReceiptBannerSettingsScreen extends ConsumerStatefulWidget {
  const ReceiptBannerSettingsScreen({super.key});

  @override
  ConsumerState<ReceiptBannerSettingsScreen> createState() => _ReceiptBannerSettingsScreenState();
}

class _ReceiptBannerSettingsScreenState extends ConsumerState<ReceiptBannerSettingsScreen> {
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _urlController;
  
  String _selectedStyle = 'classic';
  String _selectedIcon = 'storefront';
  int? _selectedColor;
  int? _selectedTextColor;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _subtitleController = TextEditingController();
    _urlController = TextEditingController();

    // Initialize with existing values if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ownerDetails = ref.read(ownerDetailsStreamProvider).value;
      if (ownerDetails != null) {
        setState(() {
          _titleController.text = ownerDetails['receiptBannerTitle'] ?? 'Powered by OruShops';
          _subtitleController.text = ownerDetails['receiptBannerSubtitle'] ?? 'Smart POS for Indian Retailers';
          _urlController.text = ownerDetails['receiptBannerUrl'] ?? 'orushops.in';
          _selectedStyle = ownerDetails['receiptBannerStyle'] ?? 'classic';
          _selectedIcon = ownerDetails['receiptBannerIcon'] ?? 'storefront';
          _selectedColor = ownerDetails['receiptBannerColor'];
          _selectedTextColor = ownerDetails['receiptBannerTextColor'];
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveBannerSettings() async {
    setState(() => _isLoading = true);
    try {
      await OwnerRepository().updateReceiptBanner(
        _titleController.text.trim(),
        _subtitleController.text.trim(),
        _urlController.text.trim(),
        _selectedStyle,
        _selectedIcon,
        _selectedColor,
        _selectedTextColor,
      );
      
      ref.invalidate(ownerDetailsStreamProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt banner updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getBannerIcon(String iconName) {
    switch (iconName) {
      case 'shopping_bag': return Icons.shopping_bag_rounded;
      case 'star': return Icons.star_rounded;
      case 'favorite': return Icons.favorite_rounded;
      case 'local_mall': return Icons.local_mall_rounded;
      case 'discount': return Icons.discount_rounded;
      case 'emoji_emotions': return Icons.emoji_emotions_rounded;
      case 'storefront':
      default:
        return Icons.storefront_rounded;
    }
  }

  Widget _buildPreviewBanner() {
    final title = _titleController.text.trim().isEmpty ? 'Powered by OruShops' : _titleController.text.trim();
    final subtitle = _subtitleController.text.trim();
    final url = _urlController.text.trim();
    final iconData = _getBannerIcon(_selectedIcon);
    final primary = _selectedColor != null ? Color(_selectedColor!) : AppTheme.primaryColor;
    final textPrimary = _selectedTextColor != null ? Color(_selectedTextColor!) : null;

    if (_selectedStyle == 'minimal') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.slate200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: AppTheme.slate100, shape: BoxShape.circle),
              child: Icon(iconData, color: primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: textPrimary ?? AppTheme.slate900, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.2),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(color: textPrimary?.withValues(alpha: 0.7) ?? AppTheme.slate500, fontSize: 10),
                    ),
                ],
              ),
            ),
            if (url.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(url, style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 10)),
              ),
          ],
        ),
      );
    } else if (_selectedStyle == 'dark') {
      final darkBg = _selectedColor != null ? primary : const Color(0xFF064E3B);
      final txtColor = textPrimary ?? Colors.white;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: darkBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: txtColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(iconData, color: txtColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: txtColor, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.2),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(color: txtColor.withValues(alpha: 0.7), fontSize: 10),
                    ),
                ],
              ),
            ),
            if (url.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: txtColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(url, style: TextStyle(color: txtColor, fontWeight: FontWeight.w700, fontSize: 10)),
              ),
          ],
        ),
      );
    } else if (_selectedStyle == 'accent') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: primary.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(iconData, color: primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: textPrimary ?? primary, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.2),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(color: (textPrimary ?? primary).withValues(alpha: 0.8), fontSize: 10),
                    ),
                ],
              ),
            ),
            if (url.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(url, style: TextStyle(color: textPrimary ?? Colors.white, fontWeight: FontWeight.w700, fontSize: 10)),
              ),
          ],
        ),
      );
    }

    // Classic (Default)
    final txtColor = textPrimary ?? Colors.white;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withValues(alpha: 0.85), primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: txtColor.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(iconData, color: txtColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: txtColor, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.2),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(color: txtColor.withValues(alpha: 0.8), fontSize: 10),
                  ),
              ],
            ),
          ),
          if (url.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: txtColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(url, style: TextStyle(color: txtColor, fontWeight: FontWeight.w700, fontSize: 10)),
            ),
        ],
      ),
    );
  }

  Widget _buildStyleSelector() {
    const styles = [
      {'id': 'classic', 'name': 'Classic Gradient'},
      {'id': 'minimal', 'name': 'Minimal Light'},
      {'id': 'dark', 'name': 'Dark Premium'},
      {'id': 'accent', 'name': 'Brand Accent'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Design Template',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.slate600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: styles.map((style) {
            final isSelected = _selectedStyle == style['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedStyle = style['id']!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white,
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.slate200,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  style['name']!,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.slate600,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showCustomColorPicker(String label, int? currentValue, void Function(int) onSelected) {
    int tempColor = currentValue ?? 0xFF000000;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Select $label', style: const TextStyle(color: AppTheme.slate900, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Color(tempColor),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.slate200),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const SizedBox(width: 40, child: Text('R', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                      Expanded(
                        child: Slider(
                          value: ((Color(tempColor).r) * 255.0).round().clamp(0, 255).toDouble(),
                          min: 0, max: 255,
                          activeColor: Colors.red,
                          onChanged: (v) => setDialogState(() {
                            final c = Color(tempColor);
                            tempColor = Color.fromARGB(255, v.toInt(), (c.g * 255.0).round().clamp(0, 255), (c.b * 255.0).round().clamp(0, 255)).toARGB32();
                          }),
                        ),
                      ),
                      SizedBox(width: 30, child: Text(((Color(tempColor).r) * 255.0).round().clamp(0, 255).toString())),
                    ],
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 40, child: Text('G', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                      Expanded(
                        child: Slider(
                          value: ((Color(tempColor).g) * 255.0).round().clamp(0, 255).toDouble(),
                          min: 0, max: 255,
                          activeColor: Colors.green,
                          onChanged: (v) => setDialogState(() {
                            final c = Color(tempColor);
                            tempColor = Color.fromARGB(255, (c.r * 255.0).round().clamp(0, 255), v.toInt(), (c.b * 255.0).round().clamp(0, 255)).toARGB32();
                          }),
                        ),
                      ),
                      SizedBox(width: 30, child: Text(((Color(tempColor).g) * 255.0).round().clamp(0, 255).toString())),
                    ],
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 40, child: Text('B', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                      Expanded(
                        child: Slider(
                          value: ((Color(tempColor).b) * 255.0).round().clamp(0, 255).toDouble(),
                          min: 0, max: 255,
                          activeColor: Colors.blue,
                          onChanged: (v) => setDialogState(() {
                            final c = Color(tempColor);
                            tempColor = Color.fromARGB(255, (c.r * 255.0).round().clamp(0, 255), (c.g * 255.0).round().clamp(0, 255), v.toInt()).toARGB32();
                          }),
                        ),
                      ),
                      SizedBox(width: 30, child: Text(((Color(tempColor).b) * 255.0).round().clamp(0, 255).toString())),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('CANCEL', style: TextStyle(color: AppTheme.slate600)),
                ),
                ElevatedButton(
                  onPressed: () {
                    onSelected(tempColor);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: const Text('SELECT', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildColorSelector(String label, int? selectedValue, void Function(int?) onChanged) {
    final defaultColors = [
      AppTheme.primaryColor.toARGB32(),
      0xFF000000, // Black
      0xFFE53935, // Red
      0xFF43A047, // Green
      0xFF1E88E5, // Blue
      0xFF8E24AA, // Purple
      0xFFF4511E, // Orange
      0xFF3949AB, // Indigo
      0xFF00897B, // Teal
      0xFFFFFFFF, // White
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.slate600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Default "None" or "Theme Default"
            GestureDetector(
              onTap: () => onChanged(null),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.slate100,
                  border: Border.all(color: selectedValue == null ? AppTheme.primaryColor : AppTheme.slate300, width: selectedValue == null ? 2 : 1),
                ),
                child: const Icon(Icons.close, size: 18, color: AppTheme.slate500),
              ),
            ),
            ...defaultColors.map((colValue) {
              final isSelected = selectedValue == colValue;
              return GestureDetector(
                onTap: () => onChanged(colValue),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(colValue),
                    border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.slate300, width: isSelected ? 3 : 1),
                  ),
                ),
              );
            }),
            // Custom Color Button
            GestureDetector(
              onTap: () => _showCustomColorPicker(label, selectedValue, (c) => onChanged(c)),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(colors: [Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.red]),
                  border: Border.all(
                    color: (selectedValue != null && !defaultColors.contains(selectedValue)) ? AppTheme.primaryColor : AppTheme.slate300, 
                    width: (selectedValue != null && !defaultColors.contains(selectedValue)) ? 3 : 1
                  ),
                ),
                child: const Icon(Icons.colorize, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconSelector() {
    const icons = [
      {'id': 'storefront', 'icon': Icons.storefront_rounded},
      {'id': 'shopping_bag', 'icon': Icons.shopping_bag_rounded},
      {'id': 'local_mall', 'icon': Icons.local_mall_rounded},
      {'id': 'star', 'icon': Icons.star_rounded},
      {'id': 'favorite', 'icon': Icons.favorite_rounded},
      {'id': 'discount', 'icon': Icons.discount_rounded},
      {'id': 'emoji_emotions', 'icon': Icons.emoji_emotions_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Banner Icon',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.slate600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: icons.map((item) {
            final isSelected = _selectedIcon == item['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedIcon = item['id'] as String),
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white,
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.slate200,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.slate500,
                  size: 24,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Receipt Banner', style: TextStyle(color: AppTheme.slate900, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.slate900),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customize the banner that appears at the bottom of customer receipts. Use this space to advertise your store, an upcoming sale, or your website.',
              style: TextStyle(color: AppTheme.slate600, height: 1.4),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Live Preview',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.slate600),
            ),
            const SizedBox(height: 12),
            _buildPreviewBanner(),
            const SizedBox(height: 32),

            _buildStyleSelector(),
            const SizedBox(height: 32),

            _buildIconSelector(),
            const SizedBox(height: 32),

            _buildColorSelector('Background / Accent Color', _selectedColor, (c) => setState(() => _selectedColor = c)),
            const SizedBox(height: 32),

            _buildColorSelector('Text Color', _selectedTextColor, (c) => setState(() => _selectedTextColor = c)),
            const SizedBox(height: 32),

            const Text(
              'Banner Content',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.slate600),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Powered by MyShop',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _subtitleController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Subtitle',
                hintText: 'e.g. Visit us again for 10% off',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _urlController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Action / URL',
                hintText: 'e.g. myshop.com',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveBannerSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
