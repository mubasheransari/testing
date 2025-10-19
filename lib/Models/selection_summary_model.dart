import 'package:equatable/equatable.dart';

class SelectionSummary extends Equatable {
  final int certificationsSelected;   // e.g., 2
  final int servicesSelected;         // e.g., 1
  final int totalEligibleServices;    // e.g., 13

  const SelectionSummary({
    required this.certificationsSelected,
    required this.servicesSelected,
    required this.totalEligibleServices,
  });

  @override
  List<Object?> get props => [certificationsSelected, servicesSelected, totalEligibleServices];
}
