class DisputeReasonOutcomesResponse {
  final bool isSuccess;
  final String? message;
  final List<DisputeReasonOutcomeItem> result;
  final List<String>? errors;

  const DisputeReasonOutcomesResponse({
    required this.isSuccess,
    required this.result,
    this.message,
    this.errors,
  });

  factory DisputeReasonOutcomesResponse.fromJson(Map<String, dynamic> json) {
    return DisputeReasonOutcomesResponse(
      isSuccess: json['isSuccess'] == true,
      message: json['message']?.toString(),
      result: json['result'] is List
          ? (json['result'] as List)
              .whereType<Map>()
              .map(
                (e) => DisputeReasonOutcomeItem.fromJson(
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

class DisputeReasonOutcomeItem {
  final int id;
  final String name;

  const DisputeReasonOutcomeItem({
    required this.id,
    required this.name,
  });

  factory DisputeReasonOutcomeItem.fromJson(Map<String, dynamic> json) {
    return DisputeReasonOutcomeItem(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}