import 'auth_model.dart';


class LoginUser {
  final String userId;
  final String phoneNumber;
  final String email;
  final String fullName;
  final String type;
  final bool requiresOnboarding;

  const LoginUser({
    required this.userId,
    required this.phoneNumber,
    required this.email,
    required this.fullName,
    required this.type,
    required this.requiresOnboarding,
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
      userId: json['userId']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      requiresOnboarding: json['requriesOnboarding'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'phoneNumber': phoneNumber,
        'email': email,
        'fullName': fullName,
        'type': type,
        'requriesOnboarding': requiresOnboarding,
      };
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

  Map<String, dynamic> toJson() => {
        'isSuccess': isSuccess,
        'message': message,
        'result': result?.toJson(),
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



// class LoginUser {
//   final String userId;
//   final String type;              
//   final bool requiresOnboarding;     

//   const LoginUser({
//     required this.userId,
//     required this.type,
//     required this.requiresOnboarding,
//   });

//   factory LoginUser.fromJson(Map<String, dynamic> json) {
//     return LoginUser(
//       userId: json['userId']?.toString() ?? '',
//       type: json['type']?.toString() ?? '',
//       requiresOnboarding: json['requriesOnboarding'] == true,
//     );
//   }
// }

// class LoginResult {
//   final String accessToken;
//   final String refreshToken;
//   final String expiresOn;
//   final LoginUser? user;

//   const LoginResult({
//     required this.accessToken,
//     required this.refreshToken,
//     required this.expiresOn,
//     required this.user,
//   });

//   factory LoginResult.fromJson(Map<String, dynamic> json) {
//     return LoginResult(
//       accessToken: json['accessToken']?.toString() ?? '',
//       refreshToken: json['refreshToken']?.toString() ?? '',
//       expiresOn: json['expiresOn']?.toString() ?? '',
//       user: json['user'] is Map<String, dynamic>
//           ? LoginUser.fromJson(json['user'] as Map<String, dynamic>)
//           : null,
//     );
//   }
// }

// class LoginResponse {
//   final bool isSuccess;
//   final String? message;
//   final LoginResult? result;
//   final List<ApiErrorItem> errors;
//   final int? statusCode;

//   const LoginResponse({
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
//       result: json['result'] is Map<String, dynamic>
//           ? LoginResult.fromJson(json['result'] as Map<String, dynamic>)
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
