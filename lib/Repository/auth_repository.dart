// lib/auth_repository_http.dart
import 'dart:async'; // TimeoutException
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// ------------------------------------------------------------
/// OPTIONAL DEFAULTS (set real IDs from your DB if needed)
/// ------------------------------------------------------------
/// If your backend requires a valid desiredService id for TASKER
/// and/or a valid companyCategory id for COMPANY, set these.
/// Leave as null to send empty arrays (you'll then see the API's
/// exact validation error in the snackbar).
const String? kDefaultServiceId = null;          // e.g. '1'
const String? kDefaultCompanyCategoryId = null;  // e.g. '2'

/// ===============================
/// Helpers: Result / Failure
/// ===============================
class Result<T> {
  final T? data;
  final Failure? failure;
  const Result._({this.data, this.failure});
  bool get isSuccess => failure == null;
  bool get isFailure => !isSuccess;
  static Result<T> ok<T>(T data) => Result._(data: data);
  static Result<T> fail<T>(Failure failure) => Result._(failure: failure);
}

class Failure {
  final String code; // 'network' | 'timeout' | 'server' | 'parse' | 'validation' | 'unknown'
  final String message;
  final int? statusCode;
  const Failure({required this.code, required this.message, this.statusCode});
  @override
  String toString() => 'Failure($code, $statusCode): $message';
}

/// ===============================
/// Models
/// ===============================
enum AccountType { USER, COMPANY, TASKER }
String accountTypeToApi(AccountType t) => t.name; // USER | COMPANY | TASKER

class SelectableItem {
  final String id;
  final String name;
  final bool isSelected;
  const SelectableItem({required this.id, required this.name, this.isSelected = false});

  factory SelectableItem.fromJson(Map<String, dynamic> json) => SelectableItem(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        isSelected: (json['isSelected'] ?? false) == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isSelected': isSelected,
      };
}

class RegistrationRequest {
  final AccountType type;

  // Common
  final String fullName;
  final String phoneNumber;
  final String emailAddress;
  final String password;

  // Collections
  final List<SelectableItem>? desiredService;
  final List<SelectableItem>? companyCategory;
  final List<SelectableItem>? companySubCategory;

  // Company-only
  final String? abn;
  final String? representativeName;
  final String? representativeNumber;

  // Tasker-only
  final String? address;

  RegistrationRequest._({
    required this.type,
    required this.fullName,
    required this.phoneNumber,
    required this.emailAddress,
    required this.password,
    this.desiredService,
    this.companyCategory,
    this.companySubCategory,
    this.abn,
    this.representativeName,
    this.representativeNumber,
    this.address,
  });

  // USER
  factory RegistrationRequest.user({
    required String fullName,
    required String phoneNumber,
    required String emailAddress,
    required String password,
    List<SelectableItem>? desiredService,
    List<SelectableItem>? companyCategory,
    List<SelectableItem>? companySubCategory,
    String? abn,
  }) {
    return RegistrationRequest._(
      type: AccountType.USER,
      fullName: fullName,
      phoneNumber: phoneNumber,
      emailAddress: emailAddress,
      password: password,
      desiredService: desiredService ?? const [], // UI has no picker yet
      companyCategory: companyCategory ?? const [],
      companySubCategory: companySubCategory ?? const [],
      abn: abn,
    );
  }

  // COMPANY
  factory RegistrationRequest.company({
    required String fullName,
    required String phoneNumber,
    required String emailAddress,
    required String password,
    List<SelectableItem>? companyCategory,
    List<SelectableItem>? companySubCategory,
    String? abn,
    String? representativeName,
    String? representativeNumber,
  }) {
    return RegistrationRequest._(
      type: AccountType.COMPANY,
      fullName: fullName, // company name
      phoneNumber: phoneNumber,
      emailAddress: emailAddress,
      password: password,
      desiredService: const [],
      companyCategory: companyCategory ?? const [],
      companySubCategory: companySubCategory ?? const [],
      abn: abn,
      representativeName: representativeName,
      representativeNumber: representativeNumber,
    );
  }

  // TASKER
  factory RegistrationRequest.tasker({
    required String fullName,
    required String phoneNumber,
    required String emailAddress,
    required String password,
    String? address,
    List<SelectableItem>? desiredService,
  }) {
    return RegistrationRequest._(
      type: AccountType.TASKER,
      fullName: fullName,
      phoneNumber: phoneNumber,
      emailAddress: emailAddress,
      password: password,
      address: address,
      desiredService: desiredService ?? const [],
      companyCategory: const [],
      companySubCategory: const [],
    );
  }

  Map<String, dynamic> toJson() {
    final base = <String, dynamic>{
      'type': accountTypeToApi(type),
      'fullname': fullName,
      'phoneNumber': phoneNumber,
      'emailAddress': emailAddress,
      'password': password,
    };

    List<Map<String, dynamic>>? mapList(List<SelectableItem>? l) =>
        l?.map((e) => e.toJson()).toList();

    switch (type) {
      case AccountType.USER:
        base['desiredService'] = mapList(desiredService ?? []);
        base['companyCategory'] = mapList(companyCategory ?? []);
        base['companySubCategory'] = mapList(companySubCategory ?? []);
        base['abn'] = (abn ?? '');
        break;

      case AccountType.COMPANY:
        base['desiredService'] = mapList(desiredService ?? [
          const SelectableItem(id: '', name: '', isSelected: false)
        ]);
        base['companyCategory'] = mapList(companyCategory ?? []);
        base['companySubCategory'] = mapList(companySubCategory ?? [
          const SelectableItem(id: '', name: '', isSelected: false)
        ]);
        base['abn'] = (abn ?? '');
        base['representativeName'] = representativeName ?? '';
        base['representativeNumber'] = representativeNumber ?? '';
        break;

      case AccountType.TASKER:
        base['address'] = address ?? '';
        base['desiredService'] = mapList(desiredService ?? [
          const SelectableItem(id: '', name: '', isSelected: false)
        ]);
        base['companyCategory'] = mapList(companyCategory ?? [
          const SelectableItem(id: '', name: '', isSelected: false)
        ]);
        base['companySubCategory'] = mapList(companySubCategory ?? [
          const SelectableItem(id: '', name: '', isSelected: false)
        ]);
        base['abn'] = '';
        base['representativeName'] = '';
        base['representativeNumber'] = '';
        break;
    }
    return base;
  }
}

class ApiErrorItem {
  final String field;
  final String error;
  ApiErrorItem({required this.field, required this.error});
  factory ApiErrorItem.fromJson(Map<String, dynamic> json) => ApiErrorItem(
        field: (json['field'] ?? '').toString(),
        error: (json['error'] ?? '').toString(),
      );
}

class RegistrationResult {
  final String? userId;
  final String? token;
  RegistrationResult({this.userId, this.token});
  factory RegistrationResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) return RegistrationResult();
    return RegistrationResult(
      userId: json['userId']?.toString(),
      token: json['token']?.toString(),
    );
  }
}

class RegistrationResponse {
  final bool isSuccess;
  final String? message;
  final RegistrationResult? result;
  final List<ApiErrorItem> errors;
  final int? statusCode;

  RegistrationResponse({
    required this.isSuccess,
    this.message,
    this.result,
    this.errors = const [],
    this.statusCode,
  });

  factory RegistrationResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationResponse(
      isSuccess: json['isSuccess'] == true,
      message: json['message']?.toString(),
      result: RegistrationResult.fromJson(json['result'] as Map<String, dynamic>?),
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

/// ===============================
/// Repository (http) — points to /api/auth/signup
/// ===============================
abstract class AuthRepository {
  Future<Result<RegistrationResponse>> register(RegistrationRequest request);

  Future<Result<RegistrationResponse>> registerUser({
    required String fullName,
    required String phoneNumber,
    required String emailAddress,
    required String password,
    List<SelectableItem>? desiredService,
    List<SelectableItem>? companyCategory,
    List<SelectableItem>? companySubCategory,
    String? abn,
  });

  Future<Result<RegistrationResponse>> registerCompany({
    required String fullName,
    required String phoneNumber,
    required String emailAddress,
    required String password,
    List<SelectableItem>? companyCategory,
    List<SelectableItem>? companySubCategory,
    String? abn,
    String? representativeName,
    String? representativeNumber,
  });

  Future<Result<RegistrationResponse>> registerTasker({
    required String fullName,
    required String phoneNumber,
    required String emailAddress,
    required String password,
    String? address,
    List<SelectableItem>? desiredService,
  });
}

class AuthRepositoryHttp implements AuthRepository {
  final Uri _endpointUri;
  final Duration timeout;

  /// Pass full absolute URL if you like:
  /// AuthRepositoryHttp.fullUrl('https://<host>/api/auth/signup')
  AuthRepositoryHttp.fullUrl(String fullUrl, {this.timeout = const Duration(seconds: 30)})
      : _endpointUri = Uri.parse(fullUrl);

  /// Or base + endpoint (defaults below)
  AuthRepositoryHttp({
    String baseUrl = 'http://192.3.3.187:83',
    String endpoint = '/api/auth/signup',
    this.timeout = const Duration(seconds: 30),
  }) : _endpointUri = Uri.parse('$baseUrl$endpoint');

  Map<String, String> _headers() => {
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.contentTypeHeader: 'application/json',
      };

  Failure? _validateEmail(String email) {
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return ok ? null : Failure(code: 'validation', message: 'Invalid email format');
  }

  Failure? _validateRequired(String label, String value) {
    if (value.trim().isEmpty) return Failure(code: 'validation', message: '$label is required');
    return null;
  }

  Future<Result<RegistrationResponse>> _postJson(Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(_endpointUri, headers: _headers(), body: jsonEncode(body))
          .timeout(timeout);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          final resp = RegistrationResponse.fromJson(data);

          // If API returns isSuccess=false, bubble up a validation failure
          if (resp.isSuccess == false) {
            String msg = resp.message ?? 'Validation failed';
            if (resp.errors.isNotEmpty) {
              final first = resp.errors.first;
              final field = (first.field.isEmpty ? '' : '${first.field}: ');
              msg = '$field${first.error}'.trim();
            } else {
              // Try common server shapes (e.g., .NET ModelState)
              final errors = data['errors'];
              if (errors is Map && errors.isNotEmpty) {
                final kv = errors.entries.first;
                final v = kv.value;
                if (v is List && v.isNotEmpty) {
                  msg = '${kv.key}: ${v.first}';
                } else {
                  msg = '$errors';
                }
              }
            }
            return Result.fail(Failure(code: 'validation', message: msg, statusCode: res.statusCode));
          }

          return Result.ok(resp);
        }
        return Result.fail(Failure(code: 'parse', message: 'Invalid response format', statusCode: res.statusCode));
      } else {
        String message = 'Server error';
        try {
          final err = jsonDecode(res.body);
          if (err is Map && err['message'] != null) message = err['message'].toString();
        } catch (_) {}
        return Result.fail(Failure(code: 'server', message: message, statusCode: res.statusCode));
      }
    } on SocketException {
      return Result.fail(Failure(code: 'network', message: 'No internet connection'));
    } on HttpException {
      return Result.fail(Failure(code: 'network', message: 'HTTP error'));
    } on FormatException {
      return Result.fail(Failure(code: 'parse', message: 'Bad response format'));
    } on TimeoutException {
      return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
    } catch (e) {
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  /// Generic register (minimal checks aligned with your current form)
  @override
  Future<Result<RegistrationResponse>> register(RegistrationRequest request) async {
    final e1 = _validateRequired('Phone number', request.phoneNumber);
    if (e1 != null) return Result.fail(e1);
    final e2 = _validateRequired('Password', request.password);
    if (e2 != null) return Result.fail(e2);
    final e3 = _validateRequired('Email', request.emailAddress) ?? _validateEmail(request.emailAddress);
    if (e3 != null) return Result.fail(e3);

    return _postJson(request.toJson());
  }

  @override
  Future<Result<RegistrationResponse>> registerUser({
    required String fullName,
    required String phoneNumber,
    required String emailAddress,
    required String password,
    List<SelectableItem>? desiredService,
    List<SelectableItem>? companyCategory,
    List<SelectableItem>? companySubCategory,
    String? abn,
  }) {
    final req = RegistrationRequest.user(
      fullName: fullName,
      phoneNumber: phoneNumber,
      emailAddress: emailAddress,
      password: password,
      desiredService: desiredService ?? const [],
      companyCategory: companyCategory ?? const [],
      companySubCategory: companySubCategory ?? const [],
      abn: abn,
    );
    return register(req);
  }

  @override
  Future<Result<RegistrationResponse>> registerCompany({
    required String fullName,
    required String phoneNumber,
    required String emailAddress,
    required String password,
    List<SelectableItem>? companyCategory,
    List<SelectableItem>? companySubCategory,
    String? abn,
    String? representativeName,
    String? representativeNumber,
  }) {
    // If backend requires at least one companyCategory with valid ID
    final cc = <SelectableItem>[];
    if (companyCategory != null && companyCategory.isNotEmpty) {
      cc.addAll(companyCategory);
    } else if (kDefaultCompanyCategoryId != null) {
      cc.add(SelectableItem(id: kDefaultCompanyCategoryId!, name: 'Default', isSelected: true));
    }

    final req = RegistrationRequest.company(
      fullName: fullName, // company name as 'fullname'
      phoneNumber: phoneNumber,
      emailAddress: emailAddress,
      password: password,
      companyCategory: cc,
      companySubCategory: companySubCategory ?? const [],
      abn: abn,
      representativeName: representativeName,
      representativeNumber: representativeNumber,
    );
    return register(req);
  }

  @override
  Future<Result<RegistrationResponse>> registerTasker({
    required String fullName,
    required String phoneNumber,
    required String emailAddress,
    required String password,
    String? address,
    List<SelectableItem>? desiredService,
  }) {
    // If backend requires at least one desiredService with valid ID
    final ds = <SelectableItem>[];
    if (desiredService != null && desiredService.isNotEmpty) {
      ds.addAll(desiredService);
    } else if (kDefaultServiceId != null) {
      ds.add(SelectableItem(id: kDefaultServiceId!, name: 'Default', isSelected: true));
    }

    final req = RegistrationRequest.tasker(
      fullName: fullName,
      phoneNumber: phoneNumber,
      emailAddress: emailAddress,
      password: password,
      address: address,
      desiredService: ds,
    );
    return register(req);
  }
}




// // lib/auth_repository_http.dart
// import 'dart:async'; // TimeoutException
// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;

// /// ===============================
// /// Helpers: Result / Failure
// /// ===============================
// class Result<T> {
//   final T? data;
//   final Failure? failure;
//   const Result._({this.data, this.failure});
//   bool get isSuccess => failure == null;
//   bool get isFailure => !isSuccess;
//   static Result<T> ok<T>(T data) => Result._(data: data);
//   static Result<T> fail<T>(Failure failure) => Result._(failure: failure);
// }

// class Failure {
//   final String code; // 'network' | 'timeout' | 'server' | 'parse' | 'validation' | 'unknown'
//   final String message;
//   final int? statusCode;
//   const Failure({required this.code, required this.message, this.statusCode});
//   @override
//   String toString() => 'Failure($code, $statusCode): $message';
// }

// /// ===============================
// /// Models
// /// ===============================
// enum AccountType { USER, COMPANY, TASKER }
// String accountTypeToApi(AccountType t) => t.name; // USER | COMPANY | TASKER

// class SelectableItem {
//   final String id;
//   final String name;
//   final bool isSelected;
//   const SelectableItem({required this.id, required this.name, this.isSelected = false});

//   factory SelectableItem.fromJson(Map<String, dynamic> json) => SelectableItem(
//         id: (json['id'] ?? '').toString(),
//         name: (json['name'] ?? '').toString(),
//         isSelected: (json['isSelected'] ?? false) == true,
//       );

//   Map<String, dynamic> toJson() => {
//         'id': id,
//         'name': name,
//         'isSelected': isSelected,
//       };
// }

// class RegistrationRequest {
//   final AccountType type;

//   // Common
//   final String fullName;
//   final String phoneNumber;
//   final String emailAddress;
//   final String password;

//   // Collections
//   final List<SelectableItem>? desiredService;
//   final List<SelectableItem>? companyCategory;
//   final List<SelectableItem>? companySubCategory;

//   // Company-only
//   final String? abn;
//   final String? representativeName;
//   final String? representativeNumber;

//   // Tasker-only
//   final String? address;

//   RegistrationRequest._({
//     required this.type,
//     required this.fullName,
//     required this.phoneNumber,
//     required this.emailAddress,
//     required this.password,
//     this.desiredService,
//     this.companyCategory,
//     this.companySubCategory,
//     this.abn,
//     this.representativeName,
//     this.representativeNumber,
//     this.address,
//   });

//   // USER
//   factory RegistrationRequest.user({
//     required String fullName,
//     required String phoneNumber,
//     required String emailAddress,
//     required String password,
//     List<SelectableItem>? desiredService,
//     List<SelectableItem>? companyCategory,
//     List<SelectableItem>? companySubCategory,
//     String? abn,
//   }) {
//     return RegistrationRequest._(
//       type: AccountType.USER,
//       fullName: fullName,
//       phoneNumber: phoneNumber,
//       emailAddress: emailAddress,
//       password: password,
//       desiredService: desiredService ?? const [], // UI has no picker yet
//       companyCategory: companyCategory ?? const [],
//       companySubCategory: companySubCategory ?? const [],
//       abn: abn,
//     );
//   }

//   // COMPANY
//   factory RegistrationRequest.company({
//     required String fullName,
//     required String phoneNumber,
//     required String emailAddress,
//     required String password,
//     List<SelectableItem>? companyCategory,
//     List<SelectableItem>? companySubCategory,
//     String? abn,
//     String? representativeName,
//     String? representativeNumber,
//   }) {
//     return RegistrationRequest._(
//       type: AccountType.COMPANY,
//       fullName: fullName, // company name
//       phoneNumber: phoneNumber,
//       emailAddress: emailAddress,
//       password: password,
//       desiredService: const [],
//       companyCategory: companyCategory ?? const [],
//       companySubCategory: companySubCategory ?? const [],
//       abn: abn,
//       representativeName: representativeName,
//       representativeNumber: representativeNumber,
//     );
//   }

//   // TASKER
//   factory RegistrationRequest.tasker({
//     required String fullName,
//     required String phoneNumber,
//     required String emailAddress,
//     required String password,
//     String? address,
//     List<SelectableItem>? desiredService,
//   }) {
//     return RegistrationRequest._(
//       type: AccountType.TASKER,
//       fullName: fullName,
//       phoneNumber: phoneNumber,
//       emailAddress: emailAddress,
//       password: password,
//       address: address,
//       desiredService: desiredService ?? const [],
//       companyCategory: const [],
//       companySubCategory: const [],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     final base = <String, dynamic>{
//       'type': accountTypeToApi(type),
//       'fullname': fullName,
//       'phoneNumber': phoneNumber,
//       'emailAddress': emailAddress,
//       'password': password,
//     };

//     List<Map<String, dynamic>>? mapList(List<SelectableItem>? l) =>
//         l?.map((e) => e.toJson()).toList();

//     switch (type) {
//       case AccountType.USER:
//         base['desiredService'] = mapList(desiredService ?? []);
//         base['companyCategory'] = mapList(companyCategory ?? []);
//         base['companySubCategory'] = mapList(companySubCategory ?? []);
//         base['abn'] = abn ?? '';
//         break;

//       case AccountType.COMPANY:
//         base['desiredService'] = mapList(desiredService ?? [
//           const SelectableItem(id: '', name: '', isSelected: false)
//         ]);
//         base['companyCategory'] = mapList(companyCategory ?? []);
//         base['companySubCategory'] = mapList(companySubCategory ?? [
//           const SelectableItem(id: '', name: '', isSelected: false)
//         ]);
//         base['abn'] = abn ?? '';
//         base['representativeName'] = representativeName ?? '';
//         base['representativeNumber'] = representativeNumber ?? '';
//         break;

//       case AccountType.TASKER:
//         base['address'] = address ?? '';
//         base['desiredService'] = mapList(desiredService ?? [
//           const SelectableItem(id: '', name: '', isSelected: false)
//         ]);
//         base['companyCategory'] = mapList(companyCategory ?? [
//           const SelectableItem(id: '', name: '', isSelected: false)
//         ]);
//         base['companySubCategory'] = mapList(companySubCategory ?? [
//           const SelectableItem(id: '', name: '', isSelected: false)
//         ]);
//         base['abn'] = '';
//         base['representativeName'] = '';
//         base['representativeNumber'] = '';
//         break;
//     }
//     return base;
//   }
// }

// class ApiErrorItem {
//   final String field;
//   final String error;
//   ApiErrorItem({required this.field, required this.error});
//   factory ApiErrorItem.fromJson(Map<String, dynamic> json) => ApiErrorItem(
//         field: (json['field'] ?? '').toString(),
//         error: (json['error'] ?? '').toString(),
//       );
// }

// class RegistrationResult {
//   final String? userId;
//   final String? token;
//   RegistrationResult({this.userId, this.token});
//   factory RegistrationResult.fromJson(Map<String, dynamic>? json) {
//     if (json == null) return RegistrationResult();
//     return RegistrationResult(
//       userId: json['userId']?.toString(),
//       token: json['token']?.toString(),
//     );
//   }
// }

// class RegistrationResponse {
//   final bool isSuccess;
//   final String? message;
//   final RegistrationResult? result;
//   final List<ApiErrorItem> errors;
//   final int? statusCode;

//   RegistrationResponse({
//     required this.isSuccess,
//     this.message,
//     this.result,
//     this.errors = const [],
//     this.statusCode,
//   });

//   factory RegistrationResponse.fromJson(Map<String, dynamic> json) {
//     return RegistrationResponse(
//       isSuccess: json['isSuccess'] == true,
//       message: json['message']?.toString(),
//       result: RegistrationResult.fromJson(json['result'] as Map<String, dynamic>?),
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

// /// ===============================
// /// Repository (http) — points to /api/auth/signup
// /// ===============================
// abstract class AuthRepository {
//   Future<Result<RegistrationResponse>> register(RegistrationRequest request);

//   Future<Result<RegistrationResponse>> registerUser({
//     required String fullName,
//     required String phoneNumber,
//     required String emailAddress,
//     required String password,
//     List<SelectableItem>? desiredService,
//     List<SelectableItem>? companyCategory,
//     List<SelectableItem>? companySubCategory,
//     String? abn,
//   });

//   Future<Result<RegistrationResponse>> registerCompany({
//     required String fullName,
//     required String phoneNumber,
//     required String emailAddress,
//     required String password,
//     List<SelectableItem>? companyCategory,
//     List<SelectableItem>? companySubCategory,
//     String? abn,
//     String? representativeName,
//     String? representativeNumber,
//   });

//   Future<Result<RegistrationResponse>> registerTasker({
//     required String fullName,
//     required String phoneNumber,
//     required String emailAddress,
//     required String password,
//     String? address,
//     List<SelectableItem>? desiredService,
//   });
// }

// class AuthRepositoryHttp implements AuthRepository {
//   final Uri _endpointUri;
//   final Duration timeout;

//   /// Use this to pass a full absolute URL directly:
//   /// e.g. AuthRepositoryHttp.fullUrl('https://<host>/api/auth/signup')
//   AuthRepositoryHttp.fullUrl(String fullUrl, {this.timeout = const Duration(seconds: 30)})
//       : _endpointUri = Uri.parse(fullUrl);

//   /// Or use base + endpoint (defaults below)
//   AuthRepositoryHttp({
//     String baseUrl = 'https://staging-api.taskoon.com',
//     String endpoint = '/api/auth/signup',
//     this.timeout = const Duration(seconds: 30),
//   }) : _endpointUri = Uri.parse('$baseUrl$endpoint');

//   Map<String, String> _headers() => {
//         HttpHeaders.acceptHeader: 'application/json',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       };

//   // Minimal common validations to match your current UI
//   Failure? _validateEmail(String email) {
//     final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
//     return ok ? null : Failure(code: 'validation', message: 'Invalid email format');
//   }

//   Failure? _validateRequired(String label, String value) {
//     if (value.trim().isEmpty) return Failure(code: 'validation', message: '$label is required');
//     return null;
//   }

//   Future<Result<RegistrationResponse>> _postJson(Map<String, dynamic> body) async {
//     try {
//       final res = await http
//           .post(_endpointUri, headers: _headers(), body: jsonEncode(body))
//           .timeout(timeout);

//       if (res.statusCode >= 200 && res.statusCode < 300) {
//         final data = jsonDecode(res.body);
//         if (data is Map<String, dynamic>) {
//           return Result.ok(RegistrationResponse.fromJson(data));
//         }
//         return Result.fail(Failure(code: 'parse', message: 'Invalid response format', statusCode: res.statusCode));
//       } else {
//         String message = 'Server error';
//         try {
//           final err = jsonDecode(res.body);
//           if (err is Map && err['message'] != null) message = err['message'].toString();
//         } catch (_) {}
//         return Result.fail(Failure(code: 'server', message: message, statusCode: res.statusCode));
//       }
//     } on SocketException {
//       return Result.fail(Failure(code: 'network', message: 'No internet connection'));
//     } on HttpException {
//       return Result.fail(Failure(code: 'network', message: 'HTTP error'));
//     } on FormatException {
//       return Result.fail(Failure(code: 'parse', message: 'Bad response format'));
//     } on TimeoutException {
//       return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
//     } catch (e) {
//       return Result.fail(Failure(code: 'unknown', message: e.toString()));
//     }
//   }

//   /// Generic register (UI already enforces required fields)
//   @override
//   Future<Result<RegistrationResponse>> register(RegistrationRequest request) async {
//     // minimal checks aligned with your current form
//     final e1 = _validateRequired('Phone number', request.phoneNumber);
//     if (e1 != null) return Result.fail(e1);
//     final e2 = _validateRequired('Password', request.password);
//     if (e2 != null) return Result.fail(e2);
//     final e3 = _validateRequired('Email', request.emailAddress) ?? _validateEmail(request.emailAddress);
//     if (e3 != null) return Result.fail(e3);

//     return _postJson(request.toJson());
//   }

//   @override
//   Future<Result<RegistrationResponse>> registerUser({
//     required String fullName,
//     required String phoneNumber,
//     required String emailAddress,
//     required String password,
//     List<SelectableItem>? desiredService,
//     List<SelectableItem>? companyCategory,
//     List<SelectableItem>? companySubCategory,
//     String? abn,
//   }) {
//     final req = RegistrationRequest.user(
//       fullName: fullName,
//       phoneNumber: phoneNumber,
//       emailAddress: emailAddress,
//       password: password,
//       desiredService: desiredService ?? const [],
//       companyCategory: companyCategory ?? const [],
//       companySubCategory: companySubCategory ?? const [],
//       abn: abn,
//     );
//     return register(req);
//   }

//   @override
//   Future<Result<RegistrationResponse>> registerCompany({
//     required String fullName,
//     required String phoneNumber,
//     required String emailAddress,
//     required String password,
//     List<SelectableItem>? companyCategory,
//     List<SelectableItem>? companySubCategory,
//     String? abn,
//     String? representativeName,
//     String? representativeNumber,
//   }) {
//     final req = RegistrationRequest.company(
//       fullName: fullName, // company name
//       phoneNumber: phoneNumber,
//       emailAddress: emailAddress,
//       password: password,
//       companyCategory: companyCategory ?? const [],
//       companySubCategory: companySubCategory ?? const [],
//       abn: abn,
//       representativeName: representativeName,
//       representativeNumber: representativeNumber,
//     );
//     return register(req);
//   }

//   @override
//   Future<Result<RegistrationResponse>> registerTasker({
//     required String fullName,
//     required String phoneNumber,
//     required String emailAddress,
//     required String password,
//     String? address,
//     List<SelectableItem>? desiredService,
//   }) {
//     final req = RegistrationRequest.tasker(
//       fullName: fullName,
//       phoneNumber: phoneNumber,
//       emailAddress: emailAddress,
//       password: password,
//       address: address,
//       desiredService: desiredService ?? const [],
//     );
//     return register(req);
//   }
// }
