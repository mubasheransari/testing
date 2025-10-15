// lib/Models/service_document.dart
class DocumentsModel {
  final int serviceId;
  final String serviceName;
  final int documentId;
  final String documentName;

  const DocumentsModel({
    required this.serviceId,
    required this.serviceName,
    required this.documentId,
    required this.documentName,
  });

  factory DocumentsModel.fromJson(Map<String, dynamic> j) => DocumentsModel(
        serviceId: (j['serviceId'] as num).toInt(),
        serviceName: (j['serviceName'] ?? '').toString().trim(),
        documentId: (j['documentId'] as num).toInt(),
        documentName: (j['documentName'] ?? '').toString().trim(),
      );
}
