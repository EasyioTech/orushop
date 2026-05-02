import 'package:flutter/material.dart';
import 'package:orushops/core/theme/app_theme.dart';

class OnboardingScreen13 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingScreen13({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingScreen13> createState() => _OnboardingScreen13State();
}

class _OnboardingScreen13State extends State<OnboardingScreen13> {
  String _passcode = "";

  void _onDigitPress(String digit) {
    if (_passcode.length < 4) {
      setState(() {
        _passcode += digit;
      });
      if (_passcode.length == 4) {
        Future.delayed(const Duration(milliseconds: 300), widget.onNext);
      }
    }
  }

  void _onDelete() {
    if (_passcode.isNotEmpty) {
      setState(() {
        _passcode = _passcode.substring(0, _passcode.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.accentColor),
          onPressed: widget.onBack,
        ),
        title: const Text("Back", style: TextStyle(color: AppTheme.accentColor)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            "Create passcode",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            "This will be used to login securely",
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFilled = index < _passcode.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? AppTheme.accentColor : Colors.grey[300],
                ),
              );
            }),
          ),
          const Spacer(),
          _buildKeypad(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(["1", "2", "3"]),
        _buildKeypadRow(["4", "5", "6"]),
        _buildKeypadRow(["7", "8", "9"]),
        _buildKeypadRow(["", "0", "delete"]),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key == "") return const SizedBox(width: 80);
        if (key == "delete") {
          return IconButton(
            iconSize: 32,
            icon: const Icon(Icons.backspace_outlined, color: AppTheme.accentColor),
            onPressed: _onDelete,
          );
        }
        return InkWell(
          onTap: () => _onDigitPress(key),
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
