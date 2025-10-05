import 'package:equatable/equatable.dart';

class ServiceOption extends Equatable {
  final int id;
  final String name;
  final bool isSelected;
  const ServiceOption({required this.id, required this.name, this.isSelected = false});
  ServiceOption copyWith({bool? isSelected}) =>
      ServiceOption(id: id, name: name, isSelected: isSelected ?? this.isSelected);
  @override
  List<Object?> get props => [id, name, isSelected];
}

class CertificationGroup extends Equatable {
  final int id;
  final String name;
  final List<ServiceOption> services;
  const CertificationGroup({required this.id, required this.name, required this.services});
  bool get allSelected => services.isNotEmpty && services.every((s) => s.isSelected);
  int get selectedCount => services.where((s) => s.isSelected).length;
  CertificationGroup copyWith({List<ServiceOption>? services}) =>
      CertificationGroup(id: id, name: name, services: services ?? this.services);
  @override
  List<Object?> get props => [id, name, services];
}
