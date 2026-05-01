import 'package:flutter/material.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({required this.child, super.key});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      setState(() => _hasError = true);
    };
  }

  void _resetError() {
    setState(() => _hasError = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[700]),
              const SizedBox(height: 16),
              const Text('Something went wrong'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _resetError,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return widget.child;
  }
}
