import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:orushops/core/models/product.dart';
import 'package:orushops/core/theme/app_theme.dart';

class QRScannerModal extends StatefulWidget {
  final List<Product> products;
  final Function(String) onScanned;

  const QRScannerModal({
    super.key,
    required this.products,
    required this.onScanned,
  });

  @override
  State<QRScannerModal> createState() => QRScannerModalState();
}

class QRScannerModalState extends State<QRScannerModal> {
  late MobileScannerController controller;
  String? errorMessage;
  Timer? _errorTimer;
  String? _lastScanned;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() {
      errorMessage = message;
    });
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          errorMessage = null;
          _lastScanned = null;
        });
      }
    });
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp) {
        HapticFeedback.lightImpact();
        controller.toggleTorch();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
        HapticFeedback.lightImpact();
        controller.stop().then((_) => controller.start());
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scan Product SKU',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Position the QR code within the frame',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  MobileScanner(
                    controller: controller,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        final sku = barcode.rawValue?.trim() ?? '';
                        if (sku.isNotEmpty && sku != _lastScanned) {
                          _lastScanned = sku;

                          final product = widget.products.cast<Product?>().firstWhere(
                            (p) => p?.sku.toLowerCase() == sku.toLowerCase(),
                            orElse: () => null,
                          );

                          if (product != null) {
                            if (product.displayQuantity > 0) {
                              HapticFeedback.mediumImpact();
                              Navigator.pop(context);
                              widget.onScanned(sku);
                            } else {
                              HapticFeedback.heavyImpact();
                              _showError('"${product.name}" is out of stock');
                            }
                          } else {
                            HapticFeedback.heavyImpact();
                            _showError('SKU "$sku" not found in inventory');
                          }
                          break;
                        }
                      }
                    },
                    errorBuilder: (context, error, child) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.no_photography_rounded, size: 48, color: AppTheme.textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              'Camera access required',
                              style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Scanner Frame Overlay (Rectangle)
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        width: 280,
                        height: 160,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            ScannerCorner(isTop: true, isLeft: true),
                            ScannerCorner(isTop: true, isLeft: false),
                            ScannerCorner(isTop: false, isLeft: true),
                            ScannerCorner(isTop: false, isLeft: false),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Controls (Torch & Refocus)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Column(
                      children: [
                        ScannerActionButton(
                          icon: Icons.flashlight_on_rounded,
                          onPressed: () => controller.toggleTorch(),
                          label: 'Torch',
                        ),
                        const SizedBox(height: 16),
                        ScannerActionButton(
                          icon: Icons.filter_center_focus_rounded,
                          onPressed: () async {
                            await controller.stop();
                            await controller.start();
                          },
                          label: 'Focus',
                        ),
                      ],
                    ),
                  ),

                  // Error Message Overlay
                  if (errorMessage != null)
                    Positioned(
                      bottom: 40,
                      left: 40,
                      right: 40,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.errorColor.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class ScannerCorner extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const ScannerCorner({super.key, required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: isTop ? -2 : null,
      bottom: !isTop ? -2 : null,
      left: isLeft ? -2 : null,
      right: !isLeft ? -2 : null,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: AppTheme.primaryColor, width: 3) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: AppTheme.primaryColor, width: 3) : BorderSide.none,
            left: isLeft ? const BorderSide(color: AppTheme.primaryColor, width: 3) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: AppTheme.primaryColor, width: 3) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(8) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(8) : Radius.zero,
            bottomLeft: !isTop && isLeft ? const Radius.circular(8) : Radius.zero,
            bottomRight: !isTop && !isLeft ? const Radius.circular(8) : Radius.zero,
          ),
        ),
      ),
    );
  }
}

class ScannerActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String label;

  const ScannerActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryDark.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              onPressed();
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
