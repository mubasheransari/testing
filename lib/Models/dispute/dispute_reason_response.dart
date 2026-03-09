class DisputeReasonResponse {
  final bool isSuccess;
  final String? message;
  final List<DisputeReasonItem> result;
  final List<String>? errors;

  const DisputeReasonResponse({
    required this.isSuccess,
    required this.result,
    this.message,
    this.errors,
  });

  factory DisputeReasonResponse.fromJson(Map<String, dynamic> json) {
    return DisputeReasonResponse(
      isSuccess: json['isSuccess'] == true,
      message: json['message']?.toString(),
      result: json['result'] is List
          ? (json['result'] as List)
              .whereType<Map>()
              .map(
                (e) => DisputeReasonItem.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList()
          : const [],
      errors: json['errors'] == null
          ? null
          : (json['errors'] is List
              ? (json['errors'] as List).map((e) => e.toString()).toList()
              : [json['errors'].toString()]),
    );
  }
}

class DisputeReasonItem {
  final int id;
  final String name;

  const DisputeReasonItem({
    required this.id,
    required this.name,
  });

  factory DisputeReasonItem.fromJson(Map<String, dynamic> json) {
    return DisputeReasonItem(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}