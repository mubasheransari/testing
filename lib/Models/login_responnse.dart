import 'auth_model.dart';

class LoginUser {
  final String userId;
  final String phoneNumber;
  final String email;
  final String fullName;
  final String type;
  final bool requiresOnboarding;
  final bool isActive;

  const LoginUser({
    required this.userId,
    required this.phoneNumber,
    required this.email,
    required this.fullName,
    required this.type,
    required this.requiresOnboarding,
    required this.isActive,
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    // Backend currently sends "requriesOnboarding" (typo),
    // but we also support "requiresOnboarding" just in case.
    final onboardingRaw =
        json['requriesOnboarding'] ?? json['requiresOnboarding'];

    return LoginUser(
      userId: json['userId']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      requiresOnboarding: onboardingRaw == true,
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
        'requriesOnboarding': requiresOnboarding,
        'isActive': isActive,
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
    final rawErrors = json['errors'];

    List<ApiErrorItem> parsedErrors = const [];
    if (rawErrors is List) {
      parsedErrors = rawErrors
          .whereType<Map<String, dynamic>>()
          .map(ApiErrorItem.fromJson)
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

// ------------------------------------
// ApiErrorItem
// ------------------------------------
// class ApiErrorItem {
//   final String field;
//   final String error;

//   const ApiErrorItem({
//     required this.field,
//     required this.error,
//   });

//   factory ApiErrorItem.fromJson(Map<String, dynamic> json) {
//     return ApiErrorItem(
//       field: json['field']?.toString() ?? '',
//       error: json['error']?.toString() ?? '',
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         'field': field,
//         'error': error,
//       };
// }

// // ------------------------------------
// // LoginUser
// // ------------------------------------
// class LoginUser {
//   final String userId;
//   final String phoneNumber;
//   final String email;
//   final String fullName;
//   final String type;
//   final bool requiresOnboarding;

//   const LoginUser({
//     required this.userId,
//     required this.phoneNumber,
//     required this.email,
//     required this.fullName,
//     required this.type,
//     required this.requiresOnboarding,
//   });

//   factory LoginUser.fromJson(Map<String, dynamic> json) {
//     // backend typo guard: "requriesOnboarding" OR correct "requiresOnboarding"
//     final rawReqOnboarding =
//         json['requriesOnboarding'] ?? json['requiresOnboarding'] ?? false;

//     bool _parseBool(dynamic v) {
//       if (v is bool) return v;
//       if (v is num) return v != 0;
//       if (v is String) {
//         final s = v.toLowerCase().trim();
//         return s == 'true' || s == '1' || s == 'yes';
//       }
//       return false;
//     }

//     return LoginUser(
//       userId: json['userId']?.toString() ?? '',
//       phoneNumber: json['phoneNumber']?.toString() ?? '',
//       email: json['email']?.toString() ?? '',
//       fullName: json['fullName']?.toString() ?? '',
//       type: json['type']?.toString() ?? '',
//       requiresOnboarding: _parseBool(rawReqOnboarding),
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         'userId': userId,
//         'phoneNumber': phoneNumber,
//         'email': email,
//         'fullName': fullName,
//         'type': type,
//         // keep the backend’s original typo so it reads it correctly
//         'requriesOnboarding': requiresOnboarding,
//       };
// }

// // ------------------------------------
// // LoginResult
// // ------------------------------------
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
//     final dynamic userJson = json['user'];
//     return LoginResult(
//       accessToken: json['accessToken']?.toString() ?? '',
//       refreshToken: json['refreshToken']?.toString() ?? '',
//       expiresOn: json['expiresOn']?.toString() ?? '',
//       user: userJson is Map<String, dynamic>
//           ? LoginUser.fromJson(userJson)
//           : null,
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         'accessToken': accessToken,
//         'refreshToken': refreshToken,
//         'expiresOn': expiresOn,
//         'user': user?.toJson(),
//       };
// }

// // ------------------------------------
// // LoginResponse
// // ------------------------------------
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
//     final dynamic resultJson = json['result'];

//     List<ApiErrorItem> _parseErrors(dynamic v) {
//       if (v is List) {
//         return v
//             .whereType<Map<String, dynamic>>()
//             .map(ApiErrorItem.fromJson)
//             .toList();
//       }
//       return const <ApiErrorItem>[];
//     }

//     int? _parseInt(dynamic v) {
//       if (v is int) return v;
//       if (v is String) return int.tryParse(v);
//       return null;
//     }

//     return LoginResponse(
//       isSuccess: json['isSuccess'] == true,
//       message: json['message']?.toString(),
//       result: resultJson is Map<String, dynamic>
//           ? LoginResult.fromJson(resultJson)
//           : null,
//       errors: _parseErrors(json['errors']),
//       statusCode: _parseInt(json['statusCode']),
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         'isSuccess': isSuccess,
//         'message': message,
//         'result': result?.toJson(),
//         'errors': errors.map((e) => e.toJson()).toList(),
//         'statusCode': statusCode,
//       };
// }

/*
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

*/

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
