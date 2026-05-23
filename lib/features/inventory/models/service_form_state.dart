import 'dart:io';

class ServiceFormState {
  final int currentStep;
  final String name;
  final String serviceCategory;
  final double price;
  final double? taxRate;
  final int? durationMinutes;
  final String durationUnit; // 'Minutes', 'Hours', 'Session', 'Visit', 'Job'
  final String? description;
  final String? availabilityNotes;
  final List<int> assignedStaffIds; // staff member IDs
  final File? serviceImage;
  final String? externalImageUrl;
  final bool isLoading;
  final String? errorMessage;

  const ServiceFormState({
    this.currentStep = 0,
    this.name = '',
    this.serviceCategory = '',
    this.price = 0.0,
    this.taxRate = 0.0,
    this.durationMinutes = 60,
    this.durationUnit = 'Minutes',
    this.description = '',
    this.availabilityNotes = '',
    this.assignedStaffIds = const [],
    this.serviceImage,
    this.externalImageUrl,
    this.isLoading = false,
    this.errorMessage,
  });

  ServiceFormState copyWith({
    int? currentStep,
    String? name,
    String? serviceCategory,
    double? price,
    double? taxRate,
    int? durationMinutes,
    String? durationUnit,
    String? description,
    String? availabilityNotes,
    List<int>? assignedStaffIds,
    File? serviceImage,
    String? externalImageUrl,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ServiceFormState(
      currentStep: currentStep ?? this.currentStep,
      name: name ?? this.name,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      price: price ?? this.price,
      taxRate: taxRate ?? this.taxRate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      durationUnit: durationUnit ?? this.durationUnit,
      description: description ?? this.description,
      availabilityNotes: availabilityNotes ?? this.availabilityNotes,
      assignedStaffIds: assignedStaffIds ?? this.assignedStaffIds,
      serviceImage: serviceImage ?? this.serviceImage,
      externalImageUrl: externalImageUrl ?? this.externalImageUrl,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
