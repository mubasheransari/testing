class ServiceDocument {
  final int serviceId;
  final String serviceName;
  final int documentId;
  final String documentName;

  const ServiceDocument({
    required this.serviceId,
    required this.serviceName,
    required this.documentId,
    required this.documentName,
  });

  factory ServiceDocument.fromJson(Map<String, dynamic> json) {
    return ServiceDocument(
      serviceId: json['serviceId'] is int
          ? json['serviceId'] as int
          : int.tryParse('${json['serviceId']}') ?? 0,
      serviceName: json['serviceName']?.toString().trim() ?? '',
      documentId: json['documentId'] is int
          ? json['documentId'] as int
          : int.tryParse('${json['documentId']}') ?? 0,
      documentName: json['documentName']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'serviceId': serviceId,
        'serviceName': serviceName,
        'documentId': documentId,
        'documentName': documentName,
      };
}

class ServiceDocumentResponse {
  final bool isSuccess;
  final String? message;
  final List<ServiceDocument> result;
  final List<ApiErrorItem> errors;
  final int? statusCode;

  const ServiceDocumentResponse({
    required this.isSuccess,
    this.message,
    this.result = const [],
    this.errors = const [],
    this.statusCode,
  });

  factory ServiceDocumentResponse.fromJson(Map<String, dynamic> json) {
    return ServiceDocumentResponse(
      isSuccess: json['isSuccess'] == true,
      message: json['message']?.toString(),
      result: ((json['result'] ?? []) as List)
          .whereType<Map<String, dynamic>>()
          .map(ServiceDocument.fromJson)
          .toList(),
      errors: ((json['errors'] ?? []) as List)
          .whereType<Map<String, dynamic>>()
          .map(ApiErrorItem.fromJson)
          .toList(),
      statusCode: json['statusCode'] is int
          ? json['statusCode'] as int
          : int.tryParse('${json['statusCode'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() => {
        'isSuccess': isSuccess,
        'message': message,
        'result': result.map((e) => e.toJson()).toList(),
        'errors': errors.map((e) => e.toJson()).toList(),
        'statusCode': statusCode,
      };
}

class ApiErrorItem {
  final String field;
  final String error;

  const ApiErrorItem({
    required this.field,
    required this.error,
  });

  factory ApiErrorItem.fromJson(Map<String, dynamic> json) {
    return ApiErrorItem(
      field: json['field']?.toString() ?? '',
      error: json['error']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'field': field,
        'error': error,
      };
}
