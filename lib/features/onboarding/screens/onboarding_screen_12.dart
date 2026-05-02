import 'package:flutter/material.dart';
import 'package:orushops/core/theme/app_theme.dart';
import '../widgets/fullscreen_onboarding_page.dart';

class OnboardingScreen12 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingScreen12({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingScreen12> createState() => _OnboardingScreen12State();
}

class _OnboardingScreen12State extends State<OnboardingScreen12> {
  String? _selectedCountry;

  final List<Map<String, String>> _popularCountries = [
    {'name': 'United States', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'flag': '🇬🇧'},
  ];

  final List<Map<String, String>> _allCountries = [
    {'name': 'Afghanistan', 'flag': '🇦🇫'},
    {'name': 'Albania', 'flag': '🇦🇱'},
    {'name': 'Algeria', 'flag': '🇩🇿'},
    {'name': 'American Samoa', 'flag': '🇦🇸'},
    {'name': 'Andorra', 'flag': '🇦🇩'},
    {'name': 'Anguilla', 'flag': '🇦🇮'},
  ];

  @override
  Widget build(BuildContext context) {
    return FullscreenOnboardingPage(
      onBack: widget.onBack,
      title: "Select country of residence",
      subtitle: "You can change the language in your profile settings after signing in.",
      primaryButtonText: 'Continue',
      isPrimaryButtonEnabled: _selectedCountry != null,
      onPrimaryAction: widget.onNext,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: const Icon(Icons.search),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text("Popular", style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._popularCountries.map((c) => _buildCountryTile(c)),
          const SizedBox(height: 24),
          const Text("A-Z", style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._allCountries.map((c) => _buildCountryTile(c)),
        ],
      ),
    );
  }

  Widget _buildCountryTile(Map<String, String> country) {
    final isSelected = _selectedCountry == country['name'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedCountry = country['name']),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.accentColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Text(country['flag']!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  country['name']!,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTheme.accentColor : Colors.grey.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppTheme.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
