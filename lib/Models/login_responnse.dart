import 'auth_model.dart';

class LoginResult {
  final String accessToken;
  final String refreshToken;
  final String expiresOn;
  final String type;
  final bool requiresOnboarding;

  LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresOn,
    required this.type,
    required this.requiresOnboarding,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return LoginResult(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      expiresOn: json['expiresOn']?.toString() ?? '',
      type: user['type']?.toString() ?? '',
      requiresOnboarding: user['requriesOnboarding'] == true,
    );
  }
}

class LoginResponse {
  final bool isSuccess;
  final String? message;
  final LoginResult? result;
  final List<ApiErrorItem> errors;
  final int? statusCode;

  LoginResponse({
    required this.isSuccess,
    this.message,
    this.result,
    this.errors = const [],
    this.statusCode,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      isSuccess: json['isSuccess'] == true,
      message: json['message']?.toString(),
      result: json['result'] != null
          ? LoginResult.fromJson(json['result'])
          : null,
      errors: ((json['errors'] ?? []) as List)
          .whereType<Map<String, dynamic>>()
          .map(ApiErrorItem.fromJson)
          .toList(),
      statusCode: json['statusCode'] is int
          ? json['statusCode'] as int
          : int.tryParse('${json['statusCode'] ?? ''}'),
    );
  }
}
