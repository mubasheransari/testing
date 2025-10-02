import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../Models/auth_model.dart';
import '../Models/login_responnse.dart';



class ApiConfig {
  static const String baseUrl = 'http://192.3.3.187:83';
  static const String signupEndpoint = '/api/auth/signup';
  static const String signInEndpoint = '/api/Auth/SignIn';
  static const String sendOTPThroughEmailEndpoint = '/api/otp/send/email';
  static const String verifyOtpEmailEndpoint = '/api/otp/verify/email';
  static const String sendOTPThroughPhoneEndpoint = '/api/otp/send/phone';
}



abstract class AuthRepository {
   Future<Result<RegistrationResponse>> verifyOtpThroughEmail({
    required String userId,
    required String email,
    required String code,
  });
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
    List<SelectableItem>? desiredService,
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

  Future<Result<LoginResponse>> signIn({
    required String email,
    required String password,
  });

  Future<Result<RegistrationResponse>> sendOtpThroughEmail({
    required String userId,
    required String email,
  });

   Future<Result<RegistrationResponse>> sendOtpThroughPhone({
    required String userId,
    required String phoneNumber,
  });
}

/// HTTP implementation
class AuthRepositoryHttp implements AuthRepository {
  final Uri _signupUri;
  final Duration timeout;

  AuthRepositoryHttp({
    String baseUrl = ApiConfig.baseUrl,
    String endpoint = ApiConfig.signupEndpoint,
    this.timeout = const Duration(seconds: 30),
  }) : _signupUri = Uri.parse('$baseUrl$endpoint');

  AuthRepositoryHttp.fullUrl(
    String fullUrl, {
    this.timeout = const Duration(seconds: 30),
  }) : _signupUri = Uri.parse(fullUrl);

  Map<String, String> _headers() => const {
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.contentTypeHeader: 'application/json',
        'X-Request-For': '::1',
      };

  Failure? _validateEmail(String email) {
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return ok
        ? null
        : Failure(code: 'validation', message: 'Invalid email format');
  }

  Failure? _validateRequired(String label, String value) {
    if (value.trim().isEmpty) {
      return Failure(code: 'validation', message: '$label is required');
    }
    return null;
  }


  @override
Future<Result<RegistrationResponse>> verifyOtpThroughEmail({
  required String userId,
  required String email,
  required String code,
}) async {
  final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.verifyOtpEmailEndpoint}');
  final body = {
    "userId": userId,
    "email": email,
    "code": code,
  };

  try {
    print('>>> VERIFY OTP POST $uri');
    print('>>> REQUEST: ${jsonEncode(body)}');

    final res = await http
        .post(uri, headers: _headers(), body: jsonEncode(body))
        .timeout(timeout);

    print('<<< VERIFY OTP STATUS: ${res.statusCode}');
    print('<<< VERIFY OTP BODY: ${res.body}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final parsed = jsonDecode(res.body);
      if (parsed is! Map<String, dynamic>) {
        return Result.fail(
          Failure(
            code: 'parse',
            message: 'Invalid response format',
            statusCode: res.statusCode,
          ),
        );
      }

      final resp = RegistrationResponse.fromJson(parsed);
      if (!resp.isSuccess) {
        return Result.fail(
          Failure(
            code: 'validation',
            message: resp.message ?? 'OTP verification failed',
            statusCode: res.statusCode,
          ),
        );
      }

      return Result.ok(resp);
    }

    return Result.fail(
      Failure(
        code: 'server',
        message: 'Server error ${res.statusCode}',
        statusCode: res.statusCode,
      ),
    );
  } on SocketException {
    return Result.fail(
      Failure(code: 'network', message: 'No internet connection'),
    );
  } on TimeoutException {
    return Result.fail(
      Failure(code: 'timeout', message: 'Request timed out'),
    );
  } catch (e) {
    return Result.fail(
      Failure(code: 'unknown', message: e.toString()),
    );
  }
}


  Future<Result<RegistrationResponse>> _postRegistration(
      Map<String, dynamic> body) async {
    try {
      print('>>> POST $_signupUri');
      print('>>> REQUEST: ${jsonEncode(body)}');

      final res = await http
          .post(_signupUri, headers: _headers(), body: jsonEncode(body))
          .timeout(timeout);

      print('<<< STATUS: ${res.statusCode}');
      print('<<< BODY: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);
        if (parsed is! Map<String, dynamic>) {
          return Result.fail(
            Failure(
              code: 'parse',
              message: 'Invalid response format',
              statusCode: res.statusCode,
            ),
          );
        }

        final resp = RegistrationResponse.fromJson(parsed);
        if (!resp.isSuccess) {
          String msg = resp.message ?? 'Verification failed';
          if (resp.errors.isNotEmpty) {
            final first = resp.errors.first;
            msg =
                '${first.field.isEmpty ? '' : '${first.field}: '}${first.error}';
          }
          return Result.fail(
            Failure(
              code: 'validation',
              message: msg,
              statusCode: res.statusCode,
            ),
          );
        }

        return Result.ok(resp);
      }

      // Non-2xx
      String message = 'Server error (${res.statusCode})';
      try {
        final err = jsonDecode(res.body);
        if (err is Map && err['message'] != null) {
          message = err['message'].toString();
        }
      } catch (_) {}
      return Result.fail(
        Failure(
          code: 'server',
          message: message,
          statusCode: res.statusCode,
        ),
      );
    } on SocketException {
      return Result.fail(
        Failure(code: 'network', message: 'No internet connection'),
      );
    } on TimeoutException {
      return Result.fail(
        Failure(code: 'timeout', message: 'Request timed out'),
      );
    } catch (e) {
      return Result.fail(
        Failure(code: 'unknown', message: e.toString()),
      );
    }
  }

  @override
  Future<Result<RegistrationResponse>> register(
      RegistrationRequest request) async {
    final e1 = _validateRequired('Phone number', request.phoneNumber);
    if (e1 != null) return Result.fail(e1);
    final e2 = _validateRequired('Password', request.password);
    if (e2 != null) return Result.fail(e2);
    final e3 = _validateRequired('Email', request.emailAddress) ??
        _validateEmail(request.emailAddress);
    if (e3 != null) return Result.fail(e3);

    return _postRegistration(request.toJson());
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
    List<SelectableItem>? desiredService,
    List<SelectableItem>? companyCategory,
    List<SelectableItem>? companySubCategory,
    String? abn,
    String? representativeName,
    String? representativeNumber,
  }) {
    final req = RegistrationRequest.company(
      fullName: fullName,
      phoneNumber: phoneNumber,
      emailAddress: emailAddress,
      password: password,
      desiredService: desiredService ?? const [],
      companyCategory: companyCategory ?? const [],
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
    final req = RegistrationRequest.tasker(
      fullName: fullName,
      phoneNumber: phoneNumber,
      emailAddress: emailAddress,
      password: password,
      address: address,
      desiredService: desiredService ?? const [],
    );
    return register(req);
  }

  // ---------------- Login ----------------
  @override
  Future<Result<LoginResponse>> signIn({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.signInEndpoint}');
    final body = {
      "email": email,
      "password": password,
      "phoneNumber": ""
    };

    try {
      print('>>> LOGIN POST $uri');
      print('>>> REQUEST: ${jsonEncode(body)}');

      final res = await http
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(timeout);

      print('<<< LOGIN STATUS: ${res.statusCode}');
      print('<<< LOGIN BODY: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);
        if (parsed is! Map<String, dynamic>) {
          return Result.fail(
            Failure(
              code: 'parse',
              message: 'Invalid response format',
              statusCode: res.statusCode,
            ),
          );
        }

        final resp = LoginResponse.fromJson(parsed);
        if (!resp.isSuccess) {
          return Result.fail(
            Failure(
              code: 'validation',
              message: resp.message ?? 'Login failed',
              statusCode: res.statusCode,
            ),
          );
        }

        return Result.ok(resp);
      }

      return Result.fail(
        Failure(
          code: 'server',
          message: 'Server error ${res.statusCode}',
          statusCode: res.statusCode,
        ),
      );
    } on SocketException {
      return Result.fail(
        Failure(code: 'network', message: 'No internet connection'),
      );
    } on TimeoutException {
      return Result.fail(
        Failure(code: 'timeout', message: 'Request timed out'),
      );
    } catch (e) {
      return Result.fail(
        Failure(code: 'unknown', message: e.toString()),
      );
    }
  }

  // ---------------- Send OTP via Email ----------------
  @override
  Future<Result<RegistrationResponse>> sendOtpThroughEmail({
    required String userId,
    required String email,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sendOTPThroughEmailEndpoint}');
    final body = {
      "userId": userId,
      "email": email,
    };

    try {
      print('>>> SEND OTP POST $uri');
      print('>>> REQUEST: ${jsonEncode(body)}');

      final res = await http
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(timeout);

      print('<<< SEND OTP STATUS: ${res.statusCode}');
      print('<<< SEND OTP BODY: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);
        if (parsed is! Map<String, dynamic>) {
          return Result.fail(
            Failure(
              code: 'parse',
              message: 'Invalid response format',
              statusCode: res.statusCode,
            ),
          );
        }

        final resp = RegistrationResponse.fromJson(parsed);
        if (!resp.isSuccess) {
          return Result.fail(
            Failure(
              code: 'validation',
              message: resp.message ?? 'OTP failed',
              statusCode: res.statusCode,
            ),
          );
        }

        return Result.ok(resp);
      }

      return Result.fail(
        Failure(
          code: 'server',
          message: 'Server error ${res.statusCode}',
          statusCode: res.statusCode,
        ),
      );
    } on SocketException {
      return Result.fail(
        Failure(code: 'network', message: 'No internet connection'),
      );
    } on TimeoutException {
      return Result.fail(
        Failure(code: 'timeout', message: 'Request timed out'),
      );
    } catch (e) {
      return Result.fail(
        Failure(code: 'unknown', message: e.toString()),
      );
    }
  }




    @override
  Future<Result<RegistrationResponse>> sendOtpThroughPhone({
    required String userId,
    required String phoneNumber,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sendOTPThroughPhoneEndpoint}');
    final body = {
      "userId": userId,
      "phoneNumber": phoneNumber,
    };

    try {
      print('>>> SEND OTP POST $uri');
      print('>>> REQUEST: ${jsonEncode(body)}');

      final res = await http
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(timeout);

      print('<<< SEND OTP STATUS: ${res.statusCode}');
      print('<<< SEND OTP BODY: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);
        if (parsed is! Map<String, dynamic>) {
          return Result.fail(
            Failure(
              code: 'parse',
              message: 'Invalid response format',
              statusCode: res.statusCode,
            ),
          );
        }

        final resp = RegistrationResponse.fromJson(parsed);
        if (!resp.isSuccess) {
          return Result.fail(
            Failure(
              code: 'validation',
              message: resp.message ?? 'OTP failed',
              statusCode: res.statusCode,
            ),
          );
        }

        return Result.ok(resp);
      }

      return Result.fail(
        Failure(
          code: 'server',
          message: 'Server error ${res.statusCode}',
          statusCode: res.statusCode,
        ),
      );
    } on SocketException {
      return Result.fail(
        Failure(code: 'network', message: 'No internet connection'),
      );
    } on TimeoutException {
      return Result.fail(
        Failure(code: 'timeout', message: 'Request timed out'),
      );
    } catch (e) {
      return Result.fail(
        Failure(code: 'unknown', message: e.toString()),
      );
    }
  }
}



/*class ApiConfig {
  static const String baseUrl = 'http://192.3.3.187:83';
  static const String signupEndpoint = '/api/auth/signup';
  static const String signInEndpoint = '/api/Auth/SignIn';
  static const String sendOTPThroughEmailEndpoint = '/api/otp/send/email';
}

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
    List<SelectableItem>? desiredService,
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

  Future<Result<LoginResponse>> signIn({
    required String email,
    required String password,
  });

  sendOtpThroughEmail({
    required String userId,
    required String email,
  });
}

class AuthRepositoryHttp implements AuthRepository {
  final Uri _signupUri;
  final Duration timeout;

  AuthRepositoryHttp({
    String baseUrl = ApiConfig.baseUrl,
    String endpoint = ApiConfig.signupEndpoint,
    this.timeout = const Duration(seconds: 30),
  }) : _signupUri = Uri.parse('$baseUrl$endpoint');

  AuthRepositoryHttp.fullUrl(String fullUrl,
      {this.timeout = const Duration(seconds: 30)})
      : _signupUri = Uri.parse(fullUrl);

  Map<String, String> _headers() => const {
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.contentTypeHeader: 'application/json',
        'X-Request-For': '::1',
      };

  Failure? _validateEmail(String email) {
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return ok
        ? null
        : Failure(code: 'validation', message: 'Invalid email format');
  }

  Failure? _validateRequired(String label, String value) {
    if (value.trim().isEmpty)
      return Failure(code: 'validation', message: '$label is required');
    return null;
  }

  

  Future<Result<RegistrationResponse>> _postRegistration(
      Map<String, dynamic> body) async {
    try {
      print('>>> POST $_signupUri');
      print('>>> REQUEST: ${jsonEncode(body)}');

      final res = await http
          .post(_signupUri, headers: _headers(), body: jsonEncode(body))
          .timeout(timeout);

      print('<<< STATUS: ${res.statusCode}');
      print('<<< BODY: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);
        if (parsed is! Map<String, dynamic>) {
          return Result.fail(Failure(
              code: 'parse',
              message: 'Invalid response format',
              statusCode: res.statusCode));
        }

        final resp = RegistrationResponse.fromJson(parsed);

        if (!resp.isSuccess) {
          // prefer server message / first field error
          String msg = resp.message ?? 'Verification failed';
          if (resp.errors.isNotEmpty) {
            final first = resp.errors.first;
            msg =
                '${first.field.isEmpty ? '' : '${first.field}: '}${first.error}';
          }
          return Result.fail(Failure(
              code: 'validation', message: msg, statusCode: res.statusCode));
        }

        return Result.ok(resp);
      }

      // Non-2xx
      String message = 'Server error (${res.statusCode})';
      try {
        final err = jsonDecode(res.body);
        if (err is Map && err['message'] != null)
          message = err['message'].toString();
      } catch (_) {}
      return Result.fail(Failure(
          code: 'server', message: message, statusCode: res.statusCode));
    } on SocketException {
      return Result.fail(
          Failure(code: 'network', message: 'No internet connection'));
    } on TimeoutException {
      return Result.fail(
          Failure(code: 'timeout', message: 'Request timed out'));
    } catch (e) {
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  // ---------------- Registration API ----------------
  @override
  Future<Result<RegistrationResponse>> register(
      RegistrationRequest request) async {
    final e1 = _validateRequired('Phone number', request.phoneNumber);
    if (e1 != null) return Result.fail(e1);
    final e2 = _validateRequired('Password', request.password);
    if (e2 != null) return Result.fail(e2);
    final e3 = _validateRequired('Email', request.emailAddress) ??
        _validateEmail(request.emailAddress);
    if (e3 != null) return Result.fail(e3);

    return _postRegistration(request.toJson());
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
    List<SelectableItem>? desiredService,
    List<SelectableItem>? companyCategory,
    List<SelectableItem>? companySubCategory,
    String? abn,
    String? representativeName,
    String? representativeNumber,
  }) {
    final req = RegistrationRequest.company(
      fullName: fullName,
      phoneNumber: phoneNumber,
      emailAddress: emailAddress,
      password: password,
      desiredService: desiredService ?? const [],
      companyCategory: companyCategory ?? const [],
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
    final req = RegistrationRequest.tasker(
      fullName: fullName,
      phoneNumber: phoneNumber,
      emailAddress: emailAddress,
      password: password,
      address: address,
      desiredService: desiredService ?? const [],
    );
    return register(req);
  }

  // ---------------- Login API ----------------
  @override
  Future<Result<LoginResponse>> signIn({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.signInEndpoint}');
    // ✅ Your working request used these keys (email + password + phoneNumber:'')
    final body = {
      "email": email, // If backend expects "emailAddress", change to that key
      "password": password,
      "phoneNumber": ""
    };

    try {
      print('>>> LOGIN POST $uri');
      print('>>> REQUEST: ${jsonEncode(body)}');

      final res = await http
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(timeout);

      print('<<< LOGIN STATUS: ${res.statusCode}');
      print('<<< LOGIN BODY: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);
        if (parsed is! Map<String, dynamic>) {
          return Result.fail(Failure(
              code: 'parse',
              message: 'Invalid response format',
              statusCode: res.statusCode));
        }

        final resp = LoginResponse.fromJson(parsed);

        if (!resp.isSuccess) {
          return Result.fail(Failure(
            code: 'validation',
            message: resp.message ?? 'Login failed',
            statusCode: res.statusCode,
          ));
        }

        return Result.ok(resp);
      }

      return Result.fail(Failure(
        code: 'server',
        message: 'Server error ${res.statusCode}',
        statusCode: res.statusCode,
      ));
    } on SocketException {
      return Result.fail(
          Failure(code: 'network', message: 'No internet connection'));
    } on TimeoutException {
      return Result.fail(
          Failure(code: 'timeout', message: 'Request timed out'));
    } catch (e) {
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }
}*/



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
//     List<SelectableItem>? desiredService,
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

//   Future<Result<LoginResponse>> signIn({
//     required String email,
//     required String password,
//   }) async {
//     final body = {"email": email, "password": password, 'phoneNumber': ''};

//     final uri = Uri.parse('http://192.3.3.187:83/api/Auth/SignIn');

//     try {
//       final res = await http
//           .post(uri,
//               headers: {
//                 'Accept': 'application/json',
//                 'Content-Type': 'application/json',
//                 'X-Request-For': '::1',
//               },
//               body: jsonEncode(body));

//       print('<<< LOGIN (${res.statusCode}): ${res.body}');

//       if (res.statusCode >= 200 && res.statusCode < 300) {
//         final data = jsonDecode(res.body);
//         final resp = LoginResponse.fromJson(data);
//         if (!resp.isSuccess) {
//           return Result.fail(Failure(
//               code: 'validation',
//               message: resp.message ?? 'Login failed',
//               statusCode: res.statusCode));
//         }
//         return Result.ok(resp);
//       } else {
//         return Result.fail(Failure(
//             code: 'server',
//             message: 'Server error ${res.statusCode}',
//             statusCode: res.statusCode));
//       }
//     } on SocketException {
//       return Result.fail(
//           Failure(code: 'network', message: 'No internet connection'));
//     } on TimeoutException {
//       return Result.fail(
//           Failure(code: 'timeout', message: 'Request timed out'));
//     } catch (e) {
//       return Result.fail(Failure(code: 'unknown', message: e.toString()));
//     }
//   }
// }

//  class AuthRepositoryHttp implements AuthRepository {
//   final Uri _endpointUri;
//   final Duration timeout;
//   final ApiBaseHelper _api = ApiBaseHelper();

//   AuthRepositoryHttp.fullUrl(String fullUrl,
//       {this.timeout = const Duration(seconds: 30)})
//       : _endpointUri = Uri.parse(fullUrl);

//   AuthRepositoryHttp({
//     String baseUrl = 'http://192.3.3.187:83',
//     String endpoint = '/api/auth/signup',
//      this.timeout = const Duration(seconds: 30),
//   }) : _endpointUri = Uri.parse('$baseUrl$endpoint');

//   Failure? _validateEmail(String email) {
//     final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
//     return ok
//         ? null
//         : Failure(code: 'validation', message: 'Invalid email format');
//   }

//   Failure? _validateRequired(String label, String value) {
//     if (value.trim().isEmpty)
//       return Failure(code: 'validation', message: '$label is required');
//     return null;
//   }

//   Future<Result<RegistrationResponse>> _postJson(
//       Map<String, dynamic> body) async {
//     try {
//       // Use the exact full URL (matches your previous working code)
//       final headers = <String, String>{
//         'Accept': 'application/json',
//         'Content-Type': 'application/json',
//         'X-Request-For': '::1',
//       };

//       print('>>> POST ${_endpointUri.toString()}');
//       print('>>> REQUEST: ${jsonEncode(body)}');

//       final http.Response res = await http
//           .post(_endpointUri, headers: headers, body: jsonEncode(body))
//           .timeout(timeout);

//       print('<<< STATUS: ${res.statusCode}');
//       print('<<< BODY: ${res.body}');

//       if (res.statusCode >= 200 && res.statusCode < 300) {
//         final data = jsonDecode(res.body);
//         if (data is Map<String, dynamic>) {
//           final resp = RegistrationResponse.fromJson(data);

//           if (!resp.isSuccess) {
//             // Build best-possible error message (bubbles to UI)
//             String msg = resp.message ?? 'Verification failed';
//             if (resp.errors.isNotEmpty) {
//               final first = resp.errors.first;
//               msg =
//                   '${first.field.isEmpty ? '' : '${first.field}: '}${first.error}';
//             } else {
//               final sc = res.statusCode;
//               String message = 'Server error ($sc)';
//               String bodyText = res.body;
//               // Try to extract a useful message
//               try {
//                 final obj = jsonDecode(res.body);
//                 if (obj is Map && obj['message'] != null) {
//                   message = obj['message'].toString();
//                 } else if (obj is Map && obj['error'] != null) {
//                   message = obj['error'].toString();
//                 }
//               } catch (_) {
//                 // keep bodyText for visibility below
//               }

//               // Log everything for debugging and surface a short tail to the UI
//               print('<<< SERVER ERROR $sc');
//               print('<<< HEADERS: ${res.headers}');
//               print('<<< BODY: ${res.body}');

//               final tail = (bodyText.length > 500)
//                   ? bodyText.substring(0, 500) + '…'
//                   : bodyText;
//               return Result.fail(
//                 Failure(
//                     code: 'server', message: '$message\n$tail', statusCode: sc),
//               );
//             }
//             print('<<< VERIFICATION FAILED: $msg');
//             return Result.fail(Failure(
//                 code: 'validation', message: msg, statusCode: res.statusCode));
//           }

//           return Result.ok(resp);
//         }
//         return Result.fail(Failure(
//             code: 'parse',
//             message: 'Invalid response format',
//             statusCode: res.statusCode));
//       }

//       String message = 'Server error';
//       try {
//         final err = jsonDecode(res.body);
//         if (err is Map && err['message'] != null)
//           message = err['message'].toString();
//       } catch (_) {}
//       return Result.fail(Failure(
//           code: 'server', message: message, statusCode: res.statusCode));
//     } on SocketException {
//       return Result.fail(
//           Failure(code: 'network', message: 'No internet connection'));
//     } on TimeoutException {
//       return Result.fail(
//           Failure(code: 'timeout', message: 'Request timed out'));
//     } catch (e) {
//       return Result.fail(Failure(code: 'unknown', message: e.toString()));
//     }
//   }

//   @override
//   Future<Result<RegistrationResponse>> register(
//       RegistrationRequest request) async {
//     final e1 = _validateRequired('Phone number', request.phoneNumber);
//     if (e1 != null) return Result.fail(e1);
//     final e2 = _validateRequired('Password', request.password);
//     if (e2 != null) return Result.fail(e2);
//     final e3 = _validateRequired('Email', request.emailAddress) ??
//         _validateEmail(request.emailAddress);
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
//     List<SelectableItem>? desiredService,
//     List<SelectableItem>? companyCategory,
//     List<SelectableItem>? companySubCategory,
//     String? abn,
//     String? representativeName,
//     String? representativeNumber,
//   }) {
//     final req = RegistrationRequest.company(
//       fullName: fullName,
//       phoneNumber: phoneNumber,
//       emailAddress: emailAddress,
//       password: password,
//       desiredService: desiredService ?? const [],
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
