import 'package:flutter/material.dart';
import 'package:orushops/core/theme/app_theme.dart';

class FullscreenOnboardingPage extends StatelessWidget {
  final Widget? icon;
  final Widget? illustration;
  final String title;
  final String? subtitle;
  final Widget content;
  final String primaryButtonText;
  final VoidCallback onPrimaryAction;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryAction;
  final bool isPrimaryButtonEnabled;
  final VoidCallback onBack;
  final bool showBackButton;
  final Widget? footer;

  const FullscreenOnboardingPage({
    super.key,
    this.icon,
    this.illustration,
    required this.title,
    this.subtitle,
    required this.content,
    required this.primaryButtonText,
    required this.onPrimaryAction,
    this.secondaryButtonText,
    this.onSecondaryAction,
    this.isPrimaryButtonEnabled = true,
    required this.onBack,
    this.showBackButton = true,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 4), // 4px nudge towards bottom
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Top Navigation
              if (showBackButton)
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 20.0),
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    onBack();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2F2F7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF007AFF),
                      size: 20,
                    ),
                  ),
                ),
              ),

              // SVG Illustration
              if (illustration != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: illustration,
                  ),
                ),

              // Header Icon
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: icon,
                  ),
                ),

              // Title & Subtitle
              Text(
                title,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      fontSize: 28,
                      letterSpacing: -0.5,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.3,
                        fontSize: 16,
                      ),
                ),
              ],

              const SizedBox(height: 28),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: content,
                ),
              ),

              // Bottom Actions
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 24, right: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isPrimaryButtonEnabled
                            ? () {
                                FocusScope.of(context).unfocus();
                                onPrimaryAction();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          primaryButtonText,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (secondaryButtonText != null && onSecondaryAction != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: onSecondaryAction == null
                              ? null
                              : () {
                                  FocusScope.of(context).unfocus();
                                  onSecondaryAction!();
                                },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF2F2F7),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            secondaryButtonText!,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (footer != null) ...[
                      const SizedBox(height: 16),
                      footer!,
                    ],
                  ],
                ),
              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
