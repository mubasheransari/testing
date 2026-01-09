class LoginUser {
  final String userId;
  final String phoneNumber;
  final String email;
  final String fullName;
  final String type; // "Tasker" / "Customer"
  final bool requriesOnboarding; // backend typo (keep exactly)
  final bool isActive;

  const LoginUser({
    required this.userId,
    required this.phoneNumber,
    required this.email,
    required this.fullName,
    required this.type,
    required this.requriesOnboarding,
    required this.isActive,
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    final onboardingRaw =
        json['requriesOnboarding'] ?? json['requiresOnboarding'];

    return LoginUser(
      userId: json['userId']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      requriesOnboarding: onboardingRaw == true,
      isActive: json['isActive'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'phoneNumber': phoneNumber,
        'email': email,
        'fullName': fullName,
        'type': type,
        // send back with backend’s current key
        'requriesOnboarding': requriesOnboarding,
        'isActive': isActive,
      };
}

class LoginResult {
  final String accessToken;
  final String refreshToken;
  final String expiresOn; // API gives string like "0001-01-01T00:00:00"
  final LoginUser? user;

  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresOn,
    required this.user,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      expiresOn: json['expiresOn']?.toString() ?? '',
      user: json['user'] is Map<String, dynamic>
          ? LoginUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresOn': expiresOn,
        'user': user?.toJson(),
      };
}

class LoginResponse {
  final bool isSuccess;
  final String? message;
  final LoginResult? result;
  final List<ApiErrorItem> errors; // API returns null OR list
  final int? statusCode; // not in your sample, keep optional

  const LoginResponse({
    required this.isSuccess,
    this.message,
    this.result,
    this.errors = const [],
    this.statusCode,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final rawErrors = json['errors'];

    // ✅ IMPORTANT: errors can be null
    List<ApiErrorItem> parsedErrors = const [];
    if (rawErrors is List) {
      parsedErrors = rawErrors
          .whereType<Map>()
          .map((e) => ApiErrorItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return LoginResponse(
      isSuccess: json['isSuccess'] == true,
      message: json['message']?.toString(),
      result: json['result'] is Map<String, dynamic>
          ? LoginResult.fromJson(json['result'] as Map<String, dynamic>)
          : null,
      errors: parsedErrors,
      statusCode: json['statusCode'] is int
          ? json['statusCode'] as int
          : int.tryParse('${json['statusCode'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() => {
        'isSuccess': isSuccess,
        'message': message,
        'result': result?.toJson(),
        // ✅ send null if empty to match backend style (optional)
        'errors': errors.isEmpty ? null : errors.map((e) => e.toJson()).toList(),
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
