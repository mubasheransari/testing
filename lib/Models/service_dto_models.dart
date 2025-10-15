import 'package:equatable/equatable.dart';

class ServiceDto extends Equatable {
  final int serviceId;
  final String serviceName;
  final int certificationId;
  final String certificationName;

  const ServiceDto({
    required this.serviceId,
    required this.serviceName,
    required this.certificationId,
    required this.certificationName,
  });

  factory ServiceDto.fromJson(Map<String, dynamic> j) => ServiceDto(
        serviceId: j['serviceId'] as int,
        serviceName: (j['serviceName'] as String).trim(),
        certificationId: j['certificationId'] as int,
        certificationName: (j['certificationName'] as String).trim(),
      );

  @override
  List<Object?> get props =>
      [serviceId, serviceName, certificationId, certificationName];
}
