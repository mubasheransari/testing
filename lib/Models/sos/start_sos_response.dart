class StartSosResult {
  final String sosId;

  const StartSosResult({required this.sosId});

  factory StartSosResult.fromJson(Map<String, dynamic> json) {
    return StartSosResult(
      sosId: (json['sosId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'sosId': sosId,
      };
}

class StartSosResponse {
  final bool isSuccess;
  final String message;
  final StartSosResult? result;

  const StartSosResponse({
    required this.isSuccess,
    required this.message,
    required this.result,
  });

  factory StartSosResponse.fromJson(Map<String, dynamic> json) {
    final res = json['result'];
    return StartSosResponse(
      isSuccess: json['isSuccess'] == true,
      message: (json['message'] ?? '').toString(),
      result: res is Map<String, dynamic> ? StartSosResult.fromJson(res) : null,
    );
  }
}

class UpdateSosLocationResponse {
  final bool isSuccess;
  final String message;

  const UpdateSosLocationResponse({
    required this.isSuccess,
    required this.message,
  });

  factory UpdateSosLocationResponse.fromJson(Map<String, dynamic> json) {
    return UpdateSosLocationResponse(
      isSuccess: json['isSuccess'] == true,
      message: (json['message'] ?? '').toString(),
    );
  }
}