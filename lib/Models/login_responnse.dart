import 'auth_model.dart';


class LoginUser {
  final String userId;
  final String type;              
  final bool requiresOnboarding;     

  const LoginUser({
    required this.userId,
    required this.type,
    required this.requiresOnboarding,
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
      userId: json['userId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      requiresOnboarding: json['requriesOnboarding'] == true,
    );
  }
}

class LoginResult {
  final String accessToken;
  final String refreshToken;
  final String expiresOn;
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
}

class LoginResponse {
  final bool isSuccess;
  final String? message;
  final LoginResult? result;
  final List<ApiErrorItem> errors;
  final int? statusCode;

  const LoginResponse({
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
      result: json['result'] is Map<String, dynamic>
          ? LoginResult.fromJson(json['result'] as Map<String, dynamic>)
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


// class LoginResult {
//   final String accessToken;
//   final String refreshToken;
//   final String expiresOn;
//   final String type;
//   final bool requiresOnboarding;

//   LoginResult({
//     required this.accessToken,
//     required this.refreshToken,
//     required this.expiresOn,
//     required this.type,
//     required this.requiresOnboarding,
//   });

//   factory LoginResult.fromJson(Map<String, dynamic> json) {
//     final user = json['user'] as Map<String, dynamic>? ?? {};
//     return LoginResult(
//       accessToken: json['accessToken']?.toString() ?? '',
//       refreshToken: json['refreshToken']?.toString() ?? '',
//       expiresOn: json['expiresOn']?.toString() ?? '',
//       type: user['type']?.toString() ?? '',
//       requiresOnboarding: user['requriesOnboarding'] == true,
//     );
//   }
// }

// class LoginResponse {
//   final bool isSuccess;
//   final String? message;
//   final LoginResult? result;
//   final List<ApiErrorItem> errors;
//   final int? statusCode;

//   LoginResponse({
//     required this.isSuccess,
//     this.message,
//     this.result,
//     this.errors = const [],
//     this.statusCode,
//   });

//   factory LoginResponse.fromJson(Map<String, dynamic> json) {
//     return LoginResponse(
//       isSuccess: json['isSuccess'] == true,
//       message: json['message']?.toString(),
//       result: json['result'] != null
//           ? LoginResult.fromJson(json['result'])
//           : null,
//       errors: ((json['errors'] ?? []) as List)
//           .whereType<Map<String, dynamic>>()
//           .map(ApiErrorItem.fromJson)
//           .toList(),
//       statusCode: json['statusCode'] is int
//           ? json['statusCode'] as int
//           : int.tryParse('${json['statusCode'] ?? ''}'),
//     );
//   }
// }
