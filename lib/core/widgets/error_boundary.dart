import 'package:flutter/material.dart';
import '../exceptions/backend_exception.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? offlineChild;

  const ErrorBoundary({required this.child, this.offlineChild, super.key});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  FlutterErrorDetails? _errorDetails;
  void Function(FlutterErrorDetails)? _previousOnError;

  @override
  void initState() {
    super.initState();
    _previousOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      _previousOnError?.call(details);
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorDetails = details;
        });
      }
    };
  }

  @override
  void dispose() {
    FlutterError.onError = _previousOnError;
    super.dispose();
  }

  void _resetError() {
    setState(() {
      _hasError = false;
      _errorDetails = null;
    });
  }

  bool get _isNetworkError {
    final exception = _errorDetails?.exception;
    if (exception is NetworkException) return true;
    
    final msg = exception.toString().toLowerCase();
    return msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('network') ||
        msg.contains('timeout') ||
        msg.contains('host lookup');
  }


  @override
  Widget build(BuildContext context) {
    if (!_hasError) return widget.child;

    if (_isNetworkError && widget.offlineChild != null) {
      return widget.offlineChild!;
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                  size: 64,
                  color: _isNetworkError ? Colors.orange : Colors.red[700],
                ),
                const SizedBox(height: 16),
                Text(
                  _isNetworkError
                      ? 'No Internet Connection'
                      : 'Something went wrong',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isNetworkError
                      ? 'Your local data is safe. Connect to internet and retry.'
                      : 'The app encountered an error. Your data is safe.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _resetError,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lightweight offline banner — wrap any screen's body with this.
class OfflineBanner extends StatelessWidget {
  final Widget child;
  final bool isOffline;

  const OfflineBanner({required this.child, required this.isOffline, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isOffline)
          Material(
            color: const Color(0xFF1A1F2E), // Deep Navy matching theme
            child: SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 14),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'OFFLINE MODE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• Working on local data',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}

