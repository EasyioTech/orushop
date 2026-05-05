import 'package:flutter/material.dart';

/// Prevents rendering a child before layout constraints are resolved.
/// Eliminates "Width is zero 0,0" logs from BackdropFilter / Canvas widgets.
class SafeRender extends StatelessWidget {
  final Widget child;
  final Widget placeholder;

  const SafeRender({
    super.key,
    required this.child,
    this.placeholder = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
          return placeholder;
        }
        return child;
      },
    );
  }
}
