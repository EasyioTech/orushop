import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:orushops/core/theme/app_theme.dart';

class ProductCreationScannerModal extends StatefulWidget {
  const ProductCreationScannerModal({super.key});

  @override
  State<ProductCreationScannerModal> createState() => _ProductCreationScannerModalState();
}

class _ProductCreationScannerModalState extends State<ProductCreationScannerModal> {
  MobileScannerController? controller;
  bool _hasCameraPermission = false;
  bool _isCheckingPermission = true;
  String? _lastScanned;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  Future<void> _checkAndRequestPermission() async {
    setState(() {
      _isCheckingPermission = true;
    });

    final status = await Permission.camera.status;
    if (status.isGranted) {
      _initScanner();
    } else {
      final requestStatus = await Permission.camera.request();
      if (requestStatus.isGranted) {
        _initScanner();
      } else {
        if (mounted) {
          setState(() {
            _hasCameraPermission = false;
            _isCheckingPermission = false;
          });
        }
      }
    }
  }

  void _initScanner() {
    if (mounted) {
      setState(() {
        controller = MobileScannerController();
        _hasCameraPermission = true;
        _isCheckingPermission = false;
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.slate200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Barcode / SKU',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Align the barcode inside the frame to scan',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.slate100,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),

          // Main scanner viewport
          Expanded(
            child: _buildScannerContent(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildScannerContent() {
    if (_isCheckingPermission) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      );
    }

    if (!_hasCameraPermission) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 48,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Camera permission is required to scan barcodes. Please grant permission to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _checkAndRequestPermission,
                icon: const Icon(Icons.security_rounded),
                label: const Text('GRANT CAMERA PERMISSION'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        if (controller != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: MobileScanner(
              controller: controller!,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final sku = barcode.rawValue?.trim() ?? '';
                  if (sku.isNotEmpty && sku != _lastScanned) {
                    _lastScanned = sku;
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context, sku);
                    break;
                  }
                }
              },
              errorBuilder: (context, error, child) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.no_photography_rounded, size: 48, color: AppTheme.errorColor),
                      const SizedBox(height: 16),
                      Text(
                        'Camera failed to initialize',
                        style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        // Scanning Frame Overlay
        IgnorePointer(
          child: Center(
            child: Container(
              width: 280,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Stack(
                children: [
                  ScannerCorner(isTop: true, isLeft: true),
                  ScannerCorner(isTop: true, isLeft: false),
                  ScannerCorner(isTop: false, isLeft: true),
                  ScannerCorner(isTop: false, isLeft: false),
                  _ScanningLine(),
                ],
              ),
            ),
          ),
        ),

        // Scanner Controls
        Positioned(
          top: 20,
          right: 20,
          child: Column(
            children: [
              ScannerActionButton(
                icon: Icons.flashlight_on_rounded,
                onPressed: () => controller?.toggleTorch(),
                label: 'Torch',
              ),
              const SizedBox(height: 16),
              ScannerActionButton(
                icon: Icons.filter_center_focus_rounded,
                onPressed: () async {
                  await controller?.stop();
                  await controller?.start();
                },
                label: 'Focus',
              ),
            ],
          ),
        ),
      ],
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
            top: isTop ? const BorderSide(color: AppTheme.accentColor, width: 3) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: AppTheme.accentColor, width: 3) : BorderSide.none,
            left: isLeft ? const BorderSide(color: AppTheme.accentColor, width: 3) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: AppTheme.accentColor, width: 3) : BorderSide.none,
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
            color: AppTheme.primaryDark.withValues(alpha: 0.6),
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

class _ScanningLine extends StatefulWidget {
  const _ScanningLine();

  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: 156 * _controller.value,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentColor.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
              color: AppTheme.accentColor,
            ),
          ),
        );
      },
    );
  }
}
