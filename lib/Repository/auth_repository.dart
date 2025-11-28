import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:taskoon/Blocs/auth_bloc/auth_event.dart';
import 'package:taskoon/Models/named_bytes.dart';
import 'package:taskoon/Models/service_document_model.dart';
import 'package:taskoon/Models/training_videos_model.dart';
import 'package:taskoon/Models/user_details_model.dart';
import '../Models/auth_model.dart';
import '../Models/login_responnse.dart';
import '../Models/services_model.dart';
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:mime/mime.dart';
// ---------- ApiConfig ----------
class ApiConfig {
  static const String baseUrl = 'http://192.3.3.187:83';
  static const String signupEndpoint = '/api/auth/signup';
  static const String signInEndpoint = '/api/Auth/SignIn';
  static const String sendOTPThroughEmailEndpoint = '/api/otp/send/email';
  static const String verifyOtpEmailEndpoint = '/api/otp/verify/email';
  static const String sendOTPThroughPhoneEndpoint = '/api/otp/send/phone';
  static const String verifyOtpPhoneEndpoint = '/api/otp/verify/phone';
  static const String forgotPasswordEndpoint = '/api/auth/forgetpassword';
  static const String changePasswordEndpoint = '/api/auth/changepassword';
  static const String servicesEndpoint = '/api/Services/services';
  static const String docsRequiredEndpoint = '/api/Services/Documents';
  static const String paymentSessionEndpoint = '/api/Payment/GetSessionUrl';
  static const String certificateSubmitEndpoint = '/api/services/CertificateSubmit';
  static const String userDetailsEndpoint = '/api/User/details';
  static const String onboardingUserEndpoint = '/api/User/onboardinguser';
  static const String trainingVideosEndpoint = '/api/Services/trainingvideos';
}

extension on String {
  String normMime() {
    final v = toLowerCase();
    if (v == 'image/jpg') return 'image/jpeg';
    if (v == 'application/x-pdf') return 'application/pdf';
    return v;
  }
}

// ---------- AuthRepository (abstract) ----------
abstract class AuthRepository {
  Future<Result<RegistrationResponse>> onboardUser({
    required String userId,
    List<int> servicesId,             // default = const []
    required NamedBytes profilePicture,
    NamedBytes? docCertification,     // null/empty => send tiny valid placeholder
    required NamedBytes docInsurance,
    required NamedBytes docAddressProof,
    required NamedBytes docIdVerification,
  });

    Future<Result<UserDetails>> fetchUserDetails({required String userId});
      Future<Result<List<TrainingVideo>>> fetchTrainingVideos();
  Future<Result<String>> createPaymentSession({
    required String userId,
    required num amount,
    String paymentMethod,
  });



  Future<Result<RegistrationResponse>> submitCertificate({
    required String userId,
    required int serviceId,
    required int documentId,
    required Uint8List bytes,
    String? fileName,
    String? mimeType,
  });
  Future<Result<List<ServiceDocument>>> fetchServiceDocuments();

  Future<Result<List<ServiceDto>>> fetchServices();

  Future<Result<RegistrationResponse>> forgotPassword({required String email});

  Future<Result<RegistrationResponse>> changePassword({
    required String password,
    required String userId,
  });

  Future<Result<RegistrationResponse>> verifyOtpThroughEmail({
    required String userId,
    required String email,
    required String code,
  });

  Future<Result<RegistrationResponse>> verifyOtpThroughPhone({
    required String userId,
    required String phone,
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
    String? abn,  
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

// ---------- AuthRepositoryHttp (implementation) ----------
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
  }) : _signupUri = Uri.parse(fullUrl); // Testing@123

  Map<String, String> _headers() => const {
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.contentTypeHeader: 'application/json',
        'X-Request-For': '::1',
      };

  Failure? _validateEmail(String email) {
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return ok ? null : Failure(code: 'validation', message: 'Invalid email format');
  }

  Failure? _validateRequired(String label, String value) {
    if (value.trim().isEmpty) {
      return Failure(code: 'validation', message: '$label is required');
    }
    return null;
  }

  @override
Future<Result<List<TrainingVideo>>> fetchTrainingVideos() async {
  final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.trainingVideosEndpoint}');
  try {
    // ignore: avoid_print
    print('>>> TRAINING VIDEOS GET $uri');
    final res = await http.get(uri, headers: _headers()).timeout(timeout);
    // ignore: avoid_print
    print('<<< TRAINING VIDEOS STATUS: ${res.statusCode}');
    // ignore: avoid_print
    print('<<< TRAINING VIDEOS BODY: ${res.body}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final raw = res.body.trim();
      if (raw.isEmpty) {
        return Result.ok(const <TrainingVideo>[]);
      }
      dynamic parsed;
      try {
        parsed = jsonDecode(raw);
      } catch (_) {
        return Result.fail(Failure(code: 'parse', message: 'Invalid JSON', statusCode: res.statusCode));
      }
      if (parsed is! List) {
        return Result.fail(Failure(code: 'parse', message: 'Expected array', statusCode: res.statusCode));
      }
      final list = parsed
          .map<TrainingVideo>((e) => TrainingVideo.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      return Result.ok(list);
    }

    String message = 'Server error (${res.statusCode})';
    try {
      final err = jsonDecode(res.body);
      if (err is Map && err['message'] != null) message = err['message'].toString();
    } catch (_) {}
    return Result.fail(Failure(code: 'server', message: message, statusCode: res.statusCode));
  } on SocketException {
    return Result.fail(Failure(code: 'network', message: 'No internet connection'));
  } on TimeoutException {
    return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
  } catch (e) {
    return Result.fail(Failure(code: 'unknown', message: e.toString()));
  }
}


  @override
  Future<Result<RegistrationResponse>> onboardUser({
    required String userId,
    List<int> servicesId = const [],        // empty allowed (we’ll send 0)
    required NamedBytes profilePicture,     // required
    NamedBytes? docCertification,           // null/empty => placeholder
    required NamedBytes docInsurance,       // required
    required NamedBytes docAddressProof,    // required
    required NamedBytes docIdVerification,  // required
  }) async {
    // basic validation
    if (userId.trim().isEmpty) {
      return Result.fail(Failure(code: 'validation', message: 'UserId is required'));
    }
    if (profilePicture.bytes.isEmpty ||
        docInsurance.bytes.isEmpty ||
        docAddressProof.bytes.isEmpty ||
        docIdVerification.bytes.isEmpty) {
      return Result.fail(Failure(code: 'validation', message: 'All required files must be provided'));
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.onboardingUserEndpoint}');
    try {
      // Debug
      // ignore: avoid_print
      print(
        '>>> ONBOARDING POST $uri (ServicesId=${servicesId.isEmpty ? 'EMPTY→0' : servicesId.join(',')}, '
        'Doc_Certification=${(docCertification == null || docCertification.bytes.isEmpty) ? 'PLACEHOLDER' : 'SET'})',
      );

      final req = http.MultipartRequest('POST', uri)
        ..headers[HttpHeaders.acceptHeader] = 'application/json'
        ..headers['X-Request-For'] = '::1'
        ..fields['UserId'] = userId;

      // ---- ServicesId ----
      // Backend requires the field; when "empty", send an index with 0.
      if (servicesId.isEmpty) {
        req.fields['ServicesId[0]'] = '0';
      } else {
        for (var i = 0; i < servicesId.length; i++) {
          req.fields['ServicesId[$i]'] = servicesId[i].toString();
        }
      }

      // Helper to add a file with proper (optional) contentType
      http.MultipartFile _part(String name, NamedBytes f) {
        final mime = (f.mimeType ?? '').trim();
        final ct = mime.isNotEmpty ? MediaType.parse(mime) : null; // let server infer if null
        return http.MultipartFile.fromBytes(
          name,
          f.bytes,
          filename: f.fileName.isEmpty ? 'upload.bin' : f.fileName,
          contentType: ct,
        );
      }

      // Required files
      req.files.add(_part('ProfilePicture', profilePicture));
      req.files.add(_part('Doc_Insurance', docInsurance));
      req.files.add(_part('Doc_Addressproof', docAddressProof));
      req.files.add(_part('Doc_Idverification', docIdVerification));

      // ---- Doc_Certification ----
      // Backend marks it required. When you want “empty”, attach a tiny valid file to pass validators.
      if (docCertification != null && docCertification.bytes.isNotEmpty) {
        req.files.add(_part('Doc_Certification', docCertification));
      } else {
        // 1×1 transparent PNG (67 bytes) – valid image/png
        final tinyPng = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII='
        );
        req.files.add(http.MultipartFile.fromBytes(
          'Doc_Certification',
          tinyPng,
          filename: 'blank.png',
          contentType: MediaType('image', 'png'),
        ));
      }

      final streamed = await req.send().timeout(timeout);
      final res = await http.Response.fromStream(streamed);

      // Reuse your existing handler
      return _handleSubmitResponse(res);
    } on SocketException {
      return Result.fail(Failure(code: 'network', message: 'No internet connection'));
    } on TimeoutException {
      return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
    } catch (e) {
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }


 @override
Future<Result<UserDetails>> fetchUserDetails({required String userId}) async {
  if (userId.trim().isEmpty) {
    return Result.fail(Failure(code: 'validation', message: 'UserId is required'));
  }

  final base = '${ApiConfig.baseUrl}${ApiConfig.userDetailsEndpoint}';
  // Only include UserId (Email/Phone are optional; don't send empty params)
  final uri = Uri.parse(base).replace(queryParameters: {
    'UserId': userId,
  });

  try {
    print('>>> USER DETAILS GET $uri');

    // it's fine to keep your existing _headers(); GET doesn't need Content-Type,
    // but leaving it won't break anything.
    final res = await http.get(uri, headers: _headers()).timeout(timeout);

    print('<<< USER DETAILS STATUS: ${res.statusCode}');
    print('<<< USER DETAILS BODY: ${res.body}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final parsed = jsonDecode(res.body);
      if (parsed is! Map<String, dynamic>) {
        return Result.fail(Failure(
          code: 'parse',
          message: 'Invalid response format',
          statusCode: res.statusCode,
        ));
      }

      if (parsed['isSuccess'] != true) {
        return Result.fail(Failure(
          code: 'validation',
          message: parsed['message']?.toString() ?? 'Failed to fetch user details',
          statusCode: res.statusCode,
        ));
      }

      final result = parsed['result'];
      if (result is! Map<String, dynamic>) {
        return Result.fail(Failure(
          code: 'parse',
          message: 'Invalid result format',
          statusCode: res.statusCode,
        ));
      }

      final details = UserDetails.fromJson(result);
      return Result.ok(details);
    }

    String message = 'Server error (${res.statusCode})';
    try {
      final err = jsonDecode(res.body);
      if (err is Map && err['message'] != null) {
        message = err['message'].toString();
      }
    } catch (_) {}
    return Result.fail(Failure(code: 'server', message: message, statusCode: res.statusCode));
  } on SocketException {
    return Result.fail(Failure(code: 'network', message: 'No internet connection'));
  } on TimeoutException {
    return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
  } catch (e) {
    return Result.fail(Failure(code: 'unknown', message: e.toString()));
  }
}



  @override
Future<Result<RegistrationResponse>> submitCertificate({
  required String userId,
  required int serviceId,
  required int documentId,
  required Uint8List bytes,
  String? fileName,
  String? mimeType,
}) async {
  // validations (same style)
  if (userId.trim().isEmpty) {
    return Result.fail(Failure(code: 'validation', message: 'UserId is required'));
  }
  if (serviceId <= 0 || documentId <= 0) {
    return Result.fail(Failure(code: 'validation', message: 'Invalid ServiceId/DocumentId'));
  }
  if (bytes.isEmpty) {
    return Result.fail(Failure(code: 'validation', message: 'File is empty'));
  }

  // ----- MIME detection & normalization -----
  String? detectedMime = (mimeType?.trim().isNotEmpty == true) ? mimeType!.trim() : null;

  // Prefer server-friendly/standard types
  String? _normalizeMime(String? s) {
    if (s == null) return null;
    final v = s.toLowerCase();
    if (v == 'image/jpg') return 'image/jpeg';
    if (v == 'application/x-pdf') return 'application/pdf';
    return v;
  }

  // If caller didn't pass mime, try to infer (uncomment if you add `mime` package)
  // detectedMime ??= lookupMimeType(fileName ?? 'file', headerBytes: bytes);

  detectedMime = _normalizeMime(detectedMime);

  // Allowed list — adjust to match your backend
  const allowed = {
    'image/jpeg',
    'image/png',
    'application/pdf',
  };

  if (detectedMime == null || !allowed.contains(detectedMime)) {
    // If you can’t add the `mime` package and detection is null, try a simple extension-based fallback:
    final name = (fileName ?? '').toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
      detectedMime = 'image/jpeg';
    } else if (name.endsWith('.png')) {
      detectedMime = 'image/png';
    } else if (name.endsWith('.pdf')) {
      detectedMime = 'application/pdf';
    }
  }

  // Final check after fallbacks
  if (detectedMime == null || !allowed.contains(detectedMime)) {
    return Result.fail(Failure(
      code: 'validation',
      message: 'Unsupported file type. Allowed: JPG, PNG, PDF',
    ));
  }

  // ----- Size guard (tune to your API limit) -----
  const maxBytes = 5 * 1024 * 1024; // 5 MB example – change if your API allows more
  if (bytes.length > maxBytes) {
    final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(2);
    return Result.fail(Failure(
      code: 'validation',
      message: 'File too large ($mb MB). Max ${maxBytes ~/ (1024 * 1024)} MB.',
    ));
  }

  final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.certificateSubmitEndpoint}');

  try {
    // log
    // ignore: avoid_print
    print('[submitCertificate] POST MULTIPART => $uri  bytes=${bytes.length} '
          'file=$fileName mime=$detectedMime');

    final req = http.MultipartRequest('POST', uri)
      ..headers[HttpHeaders.acceptHeader] = 'application/json'
      ..headers['X-Request-For'] = '::1'
      ..fields['UserId'] = userId
      ..fields['ServiceId'] = serviceId.toString()
      ..fields['DocumentId'] = documentId.toString();

    final uploadName = (fileName == null || fileName.isEmpty) ? 'upload.bin' : fileName;

    req.files.add(http.MultipartFile.fromBytes(
      'Document',                // MUST match backend param name
      bytes,
      filename: uploadName,
      contentType: MediaType.parse(detectedMime),   // <-- SET MIME TYPE
    ));

    final streamed = await req.send().timeout(timeout);
    final res = await http.Response.fromStream(streamed);
    return _handleSubmitResponse(res); // your existing handler (already enhanced)
  } on SocketException {
    return Result.fail(Failure(code: 'network', message: 'No internet connection'));
  } on TimeoutException {
    return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
  } catch (e) {
    return Result.fail(Failure(code: 'unknown', message: e.toString()));
  }
}


// @override
// Future<Result<RegistrationResponse>> submitCertificate({
//   required String userId,
//   required int serviceId,
//   required int documentId,
//   required Uint8List bytes,
//   String? fileName,
//   String? mimeType,
// }) async {
//   // client-side validation (same style)
//   if (userId.trim().isEmpty) {
//     return Result.fail(Failure(code: 'validation', message: 'UserId is required'));
//   }
//   if (serviceId <= 0 || documentId <= 0) {
//     return Result.fail(Failure(code: 'validation', message: 'Invalid ServiceId/DocumentId'));
//   }
//   if (bytes.isEmpty) {
//     return Result.fail(Failure(code: 'validation', message: 'File is empty'));
//   }

//   // Endpoint from ApiConfig (same style)
//   final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.certificateSubmitEndpoint}');

//   try {
//     // Log (same style)
//     // ignore: avoid_print
//     print('[submitCertificate] POST MULTIPART => $uri  bytes=${bytes.length} file=$fileName');

//     // Build multipart (do NOT set Content-Type yourself)
//     final req = http.MultipartRequest('POST', uri)
//       ..headers[HttpHeaders.acceptHeader] = 'application/json'
//       ..headers['X-Request-For'] = '::1'
//       ..fields['UserId'] = userId
//       ..fields['ServiceId'] = serviceId.toString()
//       ..fields['DocumentId'] = documentId.toString();

//     // File field name MUST be exactly what server expects -> "Document"
//     final uploadName = (fileName == null || fileName.isEmpty) ? 'upload.bin' : fileName;
//     final filePart = http.MultipartFile.fromBytes(
//       'Document',
//       bytes,
//       filename: uploadName,
//       // If you prefer to pass mimeType and you already depend on http_parser:
//       // contentType: (mimeType != null && mimeType.isNotEmpty) ? MediaType.parse(mimeType) : null,
//     );
//     req.files.add(filePart);

//     final streamed = await req.send().timeout(timeout);
//     final res = await http.Response.fromStream(streamed);

//     return _handleSubmitResponse(res);
//   } on SocketException {
//     return Result.fail(Failure(code: 'network', message: 'No internet connection'));
//   } on TimeoutException {
//     return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
//   } catch (e) {
//     return Result.fail(Failure(code: 'unknown', message: e.toString()));
//   }
// }

// ---------- helpers ----------

Future<Result<RegistrationResponse>> submitCertificateMultipart({
  required Uri uri,
  required String userId,
  required int serviceId,
  required int documentId,
  required Uint8List bytes,
  String? fileName,
  String? mimeType,
}) async {
  try {
    final req = http.MultipartRequest('POST', uri)
      ..headers[HttpHeaders.acceptHeader] = 'application/json'
      ..headers['X-Request-For'] = '::1'
      ..fields['UserId'] = userId
      ..fields['ServiceId'] = serviceId.toString()
      ..fields['DocumentId'] = documentId.toString();

    final mp = http.MultipartFile.fromBytes(
      'Document',
      bytes,
      filename: (fileName == null || fileName.isEmpty) ? 'document' : fileName,
      // Deliberately omit contentType to avoid http_parser dep; server can infer
    );
    req.files.add(mp);

    final streamed = await req.send().timeout(timeout);
    final res = await http.Response.fromStream(streamed);

    return _handleSubmitResponse(res);
  } on SocketException {
    return Result.fail(Failure(code: 'network', message: 'No internet connection'));
  } on TimeoutException {
    return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
  } catch (e) {
    return Result.fail(Failure(code: 'unknown', message: e.toString()));
  }
}

Result<RegistrationResponse> _handleSubmitResponse(http.Response res) {
  // ignore: avoid_print
  print('[submitCertificate] status=${res.statusCode} body=${res.body}');

  final raw = res.body.trim();

  // Success path
  if (res.statusCode >= 200 && res.statusCode < 300) {
    if (raw.isEmpty) {
      return Result.ok(RegistrationResponse(isSuccess: true, message: 'OK'));
    }
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic>) {
        final resp = RegistrationResponse.fromJson(parsed);
        if (resp.isSuccess) return Result.ok(resp);
        // fall through to failure with API message
        final msg = resp.message ?? 'Certificate submit failed';
        return Result.fail(Failure(code: 'validation', message: msg, statusCode: res.statusCode));
      }
      return Result.fail(Failure(code: 'parse', message: 'Invalid response format (expected object)', statusCode: res.statusCode));
    } catch (_) {
      // Non-JSON but 2xx → treat as OK
      return Result.ok(RegistrationResponse(isSuccess: true, message: 'OK'));
    }
  }

  // Failure path: try ProblemDetails with "errors"
  String message = 'Server error (${res.statusCode})';
  if (raw.isNotEmpty) {
    try {
      final err = jsonDecode(raw);
      if (err is Map) {
        if (err['errors'] is Map) {
          // ASP.NET Core validation: { errors: { Field: [ "msg1", "msg2" ] } }
          final m = (err['errors'] as Map).entries
              .map((e) => '${e.key}: ${(e.value as List).join(', ')}')
              .join(' • ');
          if (m.isNotEmpty) message = m;
        } else if (err['message'] != null) {
          message = err['message'].toString();
        } else if (err['title'] != null) {
          message = err['title'].toString();
        }
      }
    } catch (_) {
      // keep default message with raw fallback
      message = 'Server error (${res.statusCode}): $raw';
    }
  }

  return Result.fail(Failure(code: 'server', message: message, statusCode: res.statusCode));
}



  // @override
  // Future<Result<RegistrationResponse>> submitCertificate({
  //   required String userId,
  //   required int serviceId,
  //   required int documentId,
  //   required Uint8List bytes,
  //   String? fileName,
  //   String? mimeType,
  // }) async {
  //   // Optional client checks
  //   if (userId.trim().isEmpty) {
  //     return Result.fail(Failure(code: 'validation', message: 'UserId is required'));
  //   }
  //   if (serviceId <= 0 || documentId <= 0) {
  //     return Result.fail(Failure(code: 'validation', message: 'Invalid ServiceId/DocumentId'));
  //   }
  //   if (bytes.isEmpty) {
  //     return Result.fail(Failure(code: 'validation', message: 'File is empty'));
  //   }

  //   final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.certificateSubmitEndpoint}');

  //   // Swagger: string($binary) -> base64
  //   final body = <String, dynamic>{
  //     'UserId': userId,
  //     'ServiceId': serviceId,
  //     'DocumentId': documentId,
  //     'Document': base64Encode(bytes),
  //     if (fileName != null && fileName.isNotEmpty) 'FileName': fileName,
  //     if (mimeType != null && mimeType.isNotEmpty) 'ContentType': mimeType,
  //   };

  //   try {
  //     final res = await http.post(uri, headers: _headers(), body: jsonEncode(body)).timeout(timeout);

  //     if (res.statusCode >= 200 && res.statusCode < 300) {
  //       final raw = res.body.trim();
  //       if (raw.isEmpty) {
  //         // If your API returns 204 with no body on success, treat that as OK instead:
  //         // return Result.ok(RegistrationResponse(isSuccess: true, message: 'OK'));
  //         return Result.fail(Failure(
  //           code: 'parse',
  //           message: 'Empty response from server',
  //           statusCode: res.statusCode,
  //         ));
  //       }

  //       dynamic parsed;
  //       try {
  //         parsed = jsonDecode(raw);
  //       } on FormatException {
  //         return Result.fail(Failure(
  //           code: 'parse',
  //           message: 'Non-JSON response: $raw',
  //           statusCode: res.statusCode,
  //         ));
  //       }

  //       if (parsed is! Map<String, dynamic>) {
  //         return Result.fail(Failure(
  //           code: 'parse',
  //           message: 'Invalid response format (expected object)',
  //           statusCode: res.statusCode,
  //         ));
  //       }

  //       final resp = RegistrationResponse.fromJson(parsed);
  //       if (!resp.isSuccess) {
  //         return Result.fail(Failure(
  //           code: 'validation',
  //           message: resp.message ?? 'Certificate submit failed',
  //           statusCode: res.statusCode,
  //         ));
  //       }

  //       return Result.ok(resp);
  //     }

  //     // Non-2xx
  //     String message = 'Server error (${res.statusCode})';
  //     final raw = res.body;
  //     if (raw.isNotEmpty) {
  //       try {
  //         final err = jsonDecode(raw);
  //         if (err is Map && err['message'] != null) {
  //           message = err['message'].toString();
  //         }
  //       } catch (_) {}
  //     }

  //     return Result.fail(Failure(
  //       code: 'server',
  //       message: message,
  //       statusCode: res.statusCode,
  //     ));
  //   } on SocketException {
  //     return Result.fail(Failure(code: 'network', message: 'No internet connection'));
  //   } on TimeoutException {
  //     return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
  //   } catch (e) {
  //     return Result.fail(Failure(code: 'unknown', message: e.toString()));
  //   }
  // }

  @override
  Future<Result<String>> createPaymentSession({
    required String userId,
    required num amount,
    String paymentMethod = 'stripe',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.paymentSessionEndpoint}');
    final body = {"userId": userId, "amount": amount, "paymentMethod": paymentMethod};

    try {
      final res = await http.post(uri, headers: _headers(), body: jsonEncode(body)).timeout(timeout);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);
        if (parsed is Map<String, dynamic>) {
          if (parsed['isSuccess'] == true) {
            final url = parsed['result']?['sessionUrl']?.toString();
            if (url != null && url.isNotEmpty) return Result.ok(url);
            return Result.fail(Failure(code: 'validation', message: 'No sessionUrl returned'));
          }
          return Result.fail(Failure(
            code: 'validation',
            message: parsed['message']?.toString() ?? 'Payment session failed',
            statusCode: res.statusCode,
          ));
        }
        return Result.fail(Failure(code: 'parse', message: 'Invalid response format'));
      }

      return Result.fail(
          Failure(code: 'server', message: 'Server error ${res.statusCode}', statusCode: res.statusCode));
    } on SocketException {
      return Result.fail(Failure(code: 'network', message: 'No internet connection'));
    } on TimeoutException {
      return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
    } catch (e) {
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<List<ServiceDocument>>> fetchServiceDocuments() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.docsRequiredEndpoint}');
    try {
      print('>>> DOCS GET $uri');

      final res = await http.get(uri, headers: _headers()).timeout(timeout);

      print('<<< DOCS STATUS: ${res.statusCode}');
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);

        if (parsed is! List) {
          return Result.fail(
            Failure(code: 'parse', message: 'Invalid response format (expected array)', statusCode: res.statusCode),
          );
        }

        final list = parsed
            .map<ServiceDocument>((e) => ServiceDocument.fromJson(e as Map<String, dynamic>))
            .toList();

        return Result.ok(list);
      }

      String message = 'Server error (${res.statusCode})';
      try {
        final err = jsonDecode(res.body);
        if (err is Map && err['message'] != null) {
          message = err['message'].toString();
        }
      } catch (_) {}
      return Result.fail(Failure(code: 'server', message: message, statusCode: res.statusCode));
    } on SocketException {
      return Result.fail(Failure(code: 'network', message: 'No internet connection'));
    } on TimeoutException {
      return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
    } catch (e) {
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<List<ServiceDto>>> fetchServices() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.servicesEndpoint}');
    try {
      print('>>> SERVICES GET $uri');

      final res = await http.get(uri, headers: _headers()).timeout(timeout);

      print('<<< SERVICES STATUS: ${res.statusCode}');
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);

        if (parsed is! List) {
          return Result.fail(
            Failure(code: 'parse', message: 'Invalid response format (expected array)', statusCode: res.statusCode),
          );
        }

        final list =
            parsed.map<ServiceDto>((e) => ServiceDto.fromJson(e as Map<String, dynamic>)).toList();

        return Result.ok(list);
      }

      String message = 'Server error (${res.statusCode})';
      try {
        final err = jsonDecode(res.body);
        if (err is Map && err['message'] != null) {
          message = err['message'].toString();
        }
      } catch (_) {}
      return Result.fail(Failure(code: 'server', message: message, statusCode: res.statusCode));
    } on SocketException {
      return Result.fail(Failure(code: 'network', message: 'No internet connection'));
    } on TimeoutException {
      return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
    } catch (e) {
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<RegistrationResponse>> changePassword({
    required String password,
    required String userId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.changePasswordEndpoint}');
    final body = {
      "password": password,
      "userId": userId,
    };

    try {
      print('>>> VERIFY OTP POST $uri');
      print('>>> REQUEST: ${jsonEncode(body)}');

      final res = await http.post(uri, headers: _headers(), body: jsonEncode(body)).timeout(timeout);

      print('<<< VERIFY OTP STATUS: ${res.statusCode}');
      print('<<< VERIFY OTP BODY: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);
        if (parsed is! Map<String, dynamic>) {
          return Result.fail(Failure(code: 'parse', message: 'Invalid response format', statusCode: res.statusCode));
        }

        final resp = RegistrationResponse.fromJson(parsed);
        if (!resp.isSuccess) {
          return Result.fail(Failure(
            code: 'validation',
            message: resp.message ?? 'OTP verification failed',
            statusCode: res.statusCode,
          ));
        }

        return Result.ok(resp);
      }

      return Result.fail(
          Failure(code: 'server', message: 'Server error ${res.statusCode}', statusCode: res.statusCode));
    } on SocketException {
      return Result.fail(Failure(code: 'network', message: 'No internet connection'));
    } on TimeoutException {
      return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
    } catch (e) {
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<RegistrationResponse>> verifyOtpThroughEmail({
    required String userId,
    required String email,
    required String code,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.verifyOtpEmailEndpoint}');
    final body = {"userId": userId, "email": email, "code": code};

    try {
      print('>>> VERIFY OTP POST $uri');
      print('>>> REQUEST: ${jsonEncode(body)}');

      final res = await http.post(uri, headers: _headers(), body: jsonEncode(body)).timeout(timeout);

      print('<<< VERIFY OTP STATUS: ${res.statusCode}');
      print('<<< VERIFY OTP BODY: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);
        if (parsed is! Map<String, dynamic>) {
          return Result.fail(Failure(code: 'parse', message: 'Invalid response format', statusCode: res.statusCode));
        }

        final resp = RegistrationResponse.fromJson(parsed);
        if (!resp.isSuccess) {
          return Result.fail(Failure(
            code: 'validation',
            message: resp.message ?? 'OTP verification failed',
            statusCode: res.statusCode,
          ));
        }

        return Result.ok(resp);
      }

      return Result.fail(
          Failure(code: 'server', message: 'Server error ${res.statusCode}', statusCode: res.statusCode));
    } on SocketException {
      return Result.fail(Failure(code: 'network', message: 'No internet connection'));
    } on TimeoutException {
      return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
    } catch (e) {
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<RegistrationResponse>> forgotPassword({required String email}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.forgotPasswordEndpoint}');
    final body = {"identifier": email};

    try {
      print('>>> VERIFY OTP POST $uri');
      print('>>> REQUEST: ${jsonEncode(body)}');

      final res = await http.post(uri, headers: _headers(), body: jsonEncode(body)).timeout(timeout);

      print('<<< VERIFY OTP STATUS: ${res.statusCode}');
      print('<<< VERIFY OTP BODY: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);
        if (parsed is! Map<String, dynamic>) {
          return Result.fail(Failure(code: 'parse', message: 'Invalid response format', statusCode: res.statusCode));
        }

        final resp = RegistrationResponse.fromJson(parsed);
        if (!resp.isSuccess) {
          return Result.fail(Failure(
            code: 'validation',
            message: resp.message ?? 'OTP verification failed',
            statusCode: res.statusCode,
          ));
        }

        return Result.ok(resp);
      }

      return Result.fail(
          Failure(code: 'server', message: 'Server error ${res.statusCode}', statusCode: res.statusCode));
    } on SocketException {
      return Result.fail(Failure(code: 'network', message: 'No internet connection'));
    } on TimeoutException {
      return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
    } catch (e) {
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<RegistrationResponse>> verifyOtpThroughPhone({
    required String userId,
    required String phone,
    required String code,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.verifyOtpPhoneEndpoint}');
    final body = {"userId": userId, "phone": phone, "code": code};

    try {
      print('>>> VERIFY OTP POST $uri');
      print('>>> REQUEST: ${jsonEncode(body)}');

      final res = await http.post(uri, headers: _headers(), body: jsonEncode(body)).timeout(timeout);

      print('<<< VERIFY OTP STATUS: ${res.statusCode}');
      print('<<< VERIFY OTP BODY: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);
        if (parsed is! Map<String, dynamic>) {
          return Result.fail(Failure(code: 'parse', message: 'Invalid response format', statusCode: res.statusCode));
        }

        final resp = RegistrationResponse.fromJson(parsed);
        if (!resp.isSuccess) {
          return Result.fail(Failure(
            code: 'validation',
            message: resp.message ?? 'OTP verification failed',
            statusCode: res.statusCode,
          ));
        }

        return Result.ok(resp);
      }

      return Result.fail(
          Failure(code: 'server', message: 'Server error ${res.statusCode}', statusCode: res.statusCode));
    } on SocketException {
      return Result.fail(Failure(code: 'network', message: 'No internet connection'));
    } on TimeoutException {
      return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
    } catch (e) {
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  Future<Result<RegistrationResponse>> _postRegistration(Map<String, dynamic> body) async {
    try {
      print('>>> POST $_signupUri');
      print('>>> REQUEST: ${jsonEncode(body)}');

      final res = await http.post(_signupUri, headers: _headers(), body: jsonEncode(body)).timeout(timeout);

      print('<<< STATUS: ${res.statusCode}');
      print('<<< BODY: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);
        if (parsed is! Map<String, dynamic>) {
          return Result.fail(Failure(code: 'parse', message: 'Invalid response format', statusCode: res.statusCode));
        }

        final resp = RegistrationResponse.fromJson(parsed);
        if (!resp.isSuccess) {
          String msg = resp.message ?? 'Verification failed';
          if (resp.errors.isNotEmpty) {
            final first = resp.errors.first;
            msg = '${first.field.isEmpty ? '' : '${first.field}: '}${first.error}';
          }
          return Result.fail(Failure(code: 'validation', message: msg, statusCode: res.statusCode));
        }

        return Result.ok(resp);
      }

      String message = 'Server error (${res.statusCode})';
      try {
        final err = jsonDecode(res.body);
        if (err is Map && err['message'] != null) {
          message = err['message'].toString();
        }
      } catch (_) {}
      return Result.fail(Failure(code: 'server', message: message, statusCode: res.statusCode));
    } on SocketException {
      return Result.fail(Failure(code: 'network', message: 'No internet connection'));
    } on TimeoutException {
      return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
    } catch (e) {
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<RegistrationResponse>> register(RegistrationRequest request) async {
    final e1 = _validateRequired('Phone number', request.phoneNumber);
    if (e1 != null) return Result.fail(e1);
    final e2 = _validateRequired('Password', request.password);
    if (e2 != null) return Result.fail(e2);
    final e3 =
        _validateRequired('Email', request.emailAddress) ?? _validateEmail(request.emailAddress);
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
        String? abn,  
  }) {
    final req = RegistrationRequest.tasker(
      fullName: fullName,
      phoneNumber: phoneNumber,
      emailAddress: emailAddress,
      password: password,
      address: address,
      abn: abn,   
      // desiredService: desiredService ?? const [],
    ); // 
    return register(req);
  }

  // ---------------- Login ----------------
  @override
  Future<Result<LoginResponse>> signIn({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.signInEndpoint}');
    final body = {"email": email, "password": password, "phoneNumber": ""};

    try {
      print('>>> LOGIN POST $uri');
      print('>>> REQUEST: ${jsonEncode(body)}');

      final res = await http.post(uri, headers: _headers(), body: jsonEncode(body)).timeout(timeout);

      print('<<< LOGIN STATUS: ${res.statusCode}');
      print('<<< LOGIN BODY: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);
        if (parsed is! Map<String, dynamic>) {
          return Result.fail(Failure(code: 'parse', message: 'Invalid response format', statusCode: res.statusCode));
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

      return Result.fail(
          Failure(code: 'server', message: 'Server error ${res.statusCode}', statusCode: res.statusCode));
    } on SocketException {
      return Result.fail(Failure(code: 'network', message: 'No internet connection'));
    } on TimeoutException {
      return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
    } catch (e) {
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  // ---------------- Send OTP via Email ----------------
  @override
  Future<Result<RegistrationResponse>> sendOtpThroughEmail({
    required String userId,
    required String email,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sendOTPThroughEmailEndpoint}');
    final body = {"userId": userId, "email": email};

    try {
      print('>>> SEND OTP POST $uri');
      print('>>> REQUEST: ${jsonEncode(body)}');

      final res = await http.post(uri, headers: _headers(), body: jsonEncode(body)).timeout(timeout);

      print('<<< SEND OTP STATUS: ${res.statusCode}');
      print('<<< SEND OTP BODY: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);
        if (parsed is! Map<String, dynamic>) {
          return Result.fail(Failure(code: 'parse', message: 'Invalid response format', statusCode: res.statusCode));
        }

        final resp = RegistrationResponse.fromJson(parsed);
        if (!resp.isSuccess) {
          return Result.fail(Failure(
            code: 'validation',
            message: resp.message ?? 'OTP failed',
            statusCode: res.statusCode,
          ));
        }

        return Result.ok(resp);
      }

      return Result.fail(
          Failure(code: 'server', message: 'Server error ${res.statusCode}', statusCode: res.statusCode));
    } on SocketException {
      return Result.fail(Failure(code: 'network', message: 'No internet connection'));
    } on TimeoutException {
      return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
    } catch (e) {
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<RegistrationResponse>> sendOtpThroughPhone({
    required String userId, // Testing@123
    required String phoneNumber,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sendOTPThroughPhoneEndpoint}');
    final body = {"userId": userId, "phoneNumber": phoneNumber};

    try {
      print('>>> SEND OTP POST $uri');
      print('>>> REQUEST: ${jsonEncode(body)}');

      final res = await http.post(uri, headers: _headers(), body: jsonEncode(body)).timeout(timeout);

      print('<<< SEND OTP STATUS: ${res.statusCode}');
      print('<<< SEND OTP BODY: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);
        if (parsed is! Map<String, dynamic>) {
          return Result.fail(Failure(code: 'parse', message: 'Invalid response format', statusCode: res.statusCode));
        }

        final resp = RegistrationResponse.fromJson(parsed);
        if (!resp.isSuccess) {
          return Result.fail(Failure(
            code: 'validation',
            message: resp.message ?? 'OTP failed',
            statusCode: res.statusCode,
          ));
        }

        return Result.ok(resp);
      }

      return Result.fail(
          Failure(code: 'server', message: 'Server error ${res.statusCode}', statusCode: res.statusCode));
    } on SocketException {
      return Result.fail(Failure(code: 'network', message: 'No internet connection'));
    } on TimeoutException {
      return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
    } catch (e) {
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }
}


// class ApiConfig {
//   static const String baseUrl = 'http://192.3.3.187:83';
//   static const String signupEndpoint = '/api/auth/signup';
//   static const String signInEndpoint = '/api/Auth/SignIn';
//   static const String sendOTPThroughEmailEndpoint = '/api/otp/send/email';
//   static const String verifyOtpEmailEndpoint = '/api/otp/verify/email';
//   static const String sendOTPThroughPhoneEndpoint = '/api/otp/send/phone';
//   static const String verifyOtpPhoneEndpoint = '/api/otp/verify/phone';
//   static const String forgotPasswordEndpoint = '/api/auth/forgetpassword';
//   static const String changePasswordEndpoint = '/api/auth/changepassword';
//   static const String servicesEndpoint = '/api/Services/services';
//   static const String docsRequiredEndpoint = '/api/Services/Documents';
//   static const String paymentSessionEndpoint = '/api/Payment/GetSessionUrl';
//   static const String certificateSubmitEndpoint = '/api/Services/CertificateSubmit';
// }

// abstract class AuthRepository {
//   Future<Result<RegistrationResponse>> submitCertificate({
//     required String userId,
//     required int serviceId,
//     required int documentId,
//     required Uint8List bytes, // raw bytes; repo will base64-encode
//     String? fileName,         // optional
//     String? mimeType,         // optional
//   });
//     Future<Result<String>> createPaymentSession({  
//     required String userId,
//     required num amount,
//     String paymentMethod,
//   });

//     Future<Result<List<ServiceDocument>>> fetchServiceDocuments();

//   Future<Result<List<ServiceDto>>> fetchServices();
//   Future<Result<RegistrationResponse>> forgotPassword({required String email});

//   Future<Result<RegistrationResponse>> changePassword(
//       {required String password, required String userId});

//   Future<Result<RegistrationResponse>> verifyOtpThroughEmail({
//     required String userId,
//     required String email,
//     required String code,
//   });

//   Future<Result<RegistrationResponse>> verifyOtpThroughPhone({
//     required String userId,
//     required String phone,
//     required String code,
//   });
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
//   });

//   Future<Result<LoginResponse>> signIn({
//     required String email,
//     required String password,
//   });

//   Future<Result<RegistrationResponse>> sendOtpThroughEmail({
//     required String userId,
//     required String email,
//   });

//   Future<Result<RegistrationResponse>> sendOtpThroughPhone({
//     required String userId,
//     required String phoneNumber,
//   });
// }

// class AuthRepositoryHttp implements AuthRepository {
//   final Uri _signupUri;
//   final Duration timeout;

//   AuthRepositoryHttp({
//     String baseUrl = ApiConfig.baseUrl,
//     String endpoint = ApiConfig.signupEndpoint,
//     this.timeout = const Duration(seconds: 30),
//   }) : _signupUri = Uri.parse('$baseUrl$endpoint');

//   AuthRepositoryHttp.fullUrl(
//     String fullUrl, {
//     this.timeout = const Duration(seconds: 30),
//   }) : _signupUri = Uri.parse(fullUrl);//Testing@123

//   Map<String, String> _headers() => const {
//         HttpHeaders.acceptHeader: 'application/json',
//         HttpHeaders.contentTypeHeader: 'application/json',
//         'X-Request-For': '::1',
//       };

//   Failure? _validateEmail(String email) {
//     final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
//     return ok
//         ? null
//         : Failure(code: 'validation', message: 'Invalid email format');
//   }

//   Failure? _validateRequired(String label, String value) {
//     if (value.trim().isEmpty) {
//       return Failure(code: 'validation', message: '$label is required');
//     }
//     return null;
//   }


// @override
//   Future<Result<RegistrationResponse>> submitCertificate({
//     required String userId,
//     required int serviceId,
//     required int documentId,
//     required Uint8List bytes,
//     String? fileName,     // MUST stay optional (matches abstract)
//     String? mimeType,     // MUST stay optional (matches abstract)
//   }) async {
//     // basic client validation (optional but useful)
//     if (userId.trim().isEmpty) {
//       return Result.fail(Failure(code: 'validation', message: 'UserId is required'));
//     }
//     if (serviceId <= 0 || documentId <= 0) {
//       return Result.fail(Failure(code: 'validation', message: 'Invalid ServiceId/DocumentId'));
//     }
//     if (bytes.isEmpty) {
//       return Result.fail(Failure(code: 'validation', message: 'File is empty'));
//     }

//     final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.certificateSubmitEndpoint}');

//     // Swagger string($binary) => base64 inside JSON
//     final body = <String, dynamic>{
//       'UserId': userId,
//       'ServiceId': serviceId,
//       'DocumentId': documentId,
//       'Document': base64Encode(bytes),
//       if (fileName != null && fileName.isNotEmpty) 'FileName': fileName,
//       if (mimeType != null && mimeType.isNotEmpty) 'ContentType': mimeType,
//     };

//     try {
//       final res = await http
//           .post(uri, headers: _headers(), body: jsonEncode(body))
//           .timeout(timeout);

//       if (res.statusCode >= 200 && res.statusCode < 300) {
//         final raw = res.body.trim();
//         if (raw.isEmpty) {
//           return Result.fail(Failure(
//             code: 'parse',
//             message: 'Empty response from server',
//             statusCode: res.statusCode,
//           ));
//         }

//         dynamic parsed;
//         try {
//           parsed = jsonDecode(raw);
//         } on FormatException {
//           return Result.fail(Failure(
//             code: 'parse',
//             message: 'Non-JSON response: $raw',
//             statusCode: res.statusCode,
//           ));
//         }

//         if (parsed is! Map<String, dynamic>) {
//           return Result.fail(Failure(
//             code: 'parse',
//             message: 'Invalid response format (expected object)',
//             statusCode: res.statusCode,
//           ));
//         }

//         final resp = RegistrationResponse.fromJson(parsed);
//         if (!resp.isSuccess) {
//           return Result.fail(Failure(
//             code: 'validation',
//             message: resp.message ?? 'Certificate submit failed',
//             statusCode: res.statusCode,
//           ));
//         }
//         return Result.ok(resp);
//       }

//       // Non-2xx
//       String message = 'Server error (${res.statusCode})';
//       final raw = res.body;
//       if (raw.isNotEmpty) {
//         try {
//           final err = jsonDecode(raw);
//           if (err is Map && err['message'] != null) {
//             message = err['message'].toString();
//           }
//         } catch (_) {}
//       }
//       return Result.fail(Failure(
//         code: 'server',
//         message: message,
//         statusCode: res.statusCode,
//       ));
//     } on SocketException {
//       return Result.fail(Failure(code: 'network', message: 'No internet connection'));
//     } on TimeoutException {
//       return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
//     } catch (e) {
//       return Result.fail(Failure(code: 'unknown', message: e.toString()));
//     }
//   }

//   // Keep your createPaymentSession override; if you used default = 'stripe' there,
//   // also put that default in the abstract as shown above to avoid analyzer complaints.
// }
// // @override
// // Future<Result<RegistrationResponse>> submitCertificate({
// //   required String userId,
// //   required int serviceId,
// //   required int documentId,
// //   required Uint8List bytes,
// //   String? fileName,
// //   String? mimeType,
// // }) async {
// //   final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.certificateSubmitEndpoint}');
// //   final body = <String, dynamic>{
// //     'UserId': userId,
// //     'ServiceId': serviceId,
// //     'DocumentId': documentId,
// //     'Document': base64Encode(bytes), // << send bytes as base64
// //     if (fileName != null) 'FileName': fileName,
// //     if (mimeType != null) 'ContentType': mimeType,
// //   };

// //   try {
// //     final res = await http
// //         .post(uri, headers: _headers(), body: jsonEncode(body))
// //         .timeout(timeout);

// //     if (res.statusCode >= 200 && res.statusCode < 300) {
// //       final parsed = jsonDecode(res.body);
// //       if (parsed is! Map<String, dynamic>) {
// //         return Result.fail(Failure(
// //           code: 'parse',
// //           message: 'Invalid response format',
// //           statusCode: res.statusCode,
// //         ));
// //       }
// //       final resp = RegistrationResponse.fromJson(parsed);
// //       if (!resp.isSuccess) {
// //         return Result.fail(Failure(
// //           code: 'validation',
// //           message: resp.message ?? 'Certificate submit failed',
// //           statusCode: res.statusCode,
// //         ));
// //       }
// //       return Result.ok(resp);
// //     }

// //     String message = 'Server error (${res.statusCode})';
// //     try {
// //       final err = jsonDecode(res.body);
// //       if (err is Map && err['message'] != null) {
// //         message = err['message'].toString();
// //       }
// //     } catch (_) {}
// //     return Result.fail(Failure(
// //       code: 'server',
// //       message: message,
// //       statusCode: res.statusCode,
// //     ));
// //   } on SocketException {
// //     return Result.fail(Failure(code: 'network', message: 'No internet connection'));
// //   } on TimeoutException {
// //     return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
// //   } catch (e) {
// //     return Result.fail(Failure(code: 'unknown', message: e.toString()));
// //   }
// // }

//   @override
//   Future<Result<String>> createPaymentSession({
//     required String userId,
//     required num amount,
//     String paymentMethod = 'stripe',
//   }) async {
//     final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.paymentSessionEndpoint}');
//     final body = {"userId": userId, "amount": amount, "paymentMethod": paymentMethod};

//     try {
//       final res = await http
//           .post(uri, headers: _headers(), body: jsonEncode(body))
//           .timeout(timeout);

//       if (res.statusCode >= 200 && res.statusCode < 300) {
//         final parsed = jsonDecode(res.body);
//         if (parsed is Map<String, dynamic>) {
//           if (parsed['isSuccess'] == true) {
//             final url = parsed['result']?['sessionUrl']?.toString();
//             if (url != null && url.isNotEmpty) return Result.ok(url);
//             return Result.fail(Failure(code: 'validation', message: 'No sessionUrl returned'));
//           }
//           return Result.fail(Failure(
//             code: 'validation',
//             message: parsed['message']?.toString() ?? 'Payment session failed',
//             statusCode: res.statusCode,
//           ));
//         }
//         return Result.fail(Failure(code: 'parse', message: 'Invalid response format'));
//       }

//       return Result.fail(Failure(code: 'server', message: 'Server error ${res.statusCode}', statusCode: res.statusCode));
//     } on SocketException {
//       return Result.fail(Failure(code: 'network', message: 'No internet connection'));
//     } on TimeoutException {
//       return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
//     } catch (e) {
//       return Result.fail(Failure(code: 'unknown', message: e.toString()));
//     }
//   }

//   @override
// Future<Result<List<ServiceDocument>>> fetchServiceDocuments() async {
//   final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.docsRequiredEndpoint}');
//   try {
//     print('>>> DOCS GET $uri');

//     final res = await http.get(uri, headers: _headers()).timeout(timeout);

//     print('<<< DOCS STATUS: ${res.statusCode}');
//     if (res.statusCode >= 200 && res.statusCode < 300) {
//       final parsed = jsonDecode(res.body);

//       if (parsed is! List) {
//         return Result.fail(
//           Failure(
//             code: 'parse',
//             message: 'Invalid response format (expected array)',
//             statusCode: res.statusCode,
//           ),
//         );
//       }

//       final list = parsed
//           .map<ServiceDocument>((e) => ServiceDocument.fromJson(e as Map<String, dynamic>))
//           .toList();

//       return Result.ok(list);
//     }

//     // Non-2xx
//     String message = 'Server error (${res.statusCode})';
//     try {
//       final err = jsonDecode(res.body);
//       if (err is Map && err['message'] != null) {
//         message = err['message'].toString();
//       }
//     } catch (_) {}
//     return Result.fail(
//       Failure(code: 'server', message: message, statusCode: res.statusCode),
//     );
//   } on SocketException {
//     return Result.fail(Failure(code: 'network', message: 'No internet connection'));
//   } on TimeoutException {
//     return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
//   } catch (e) {
//     return Result.fail(Failure(code: 'unknown', message: e.toString()));
//   }
// }


 


//   @override
//   Future<Result<List<ServiceDto>>> fetchServices() async {
//     final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.servicesEndpoint}');
//     try {
//       print('>>> SERVICES GET $uri');

//       final res = await http.get(uri, headers: _headers()).timeout(timeout);

//       print('<<< SERVICES STATUS: ${res.statusCode}');
//       // The endpoint returns a JSON array
//       if (res.statusCode >= 200 && res.statusCode < 300) {
//         final parsed = jsonDecode(res.body);

//         if (parsed is! List) {
//           return Result.fail(
//             Failure(
//               code: 'parse',
//               message: 'Invalid response format (expected array)',
//               statusCode: res.statusCode,
//             ),
//           );
//         }

//         final list = parsed
//             .map<ServiceDto>(
//                 (e) => ServiceDto.fromJson(e as Map<String, dynamic>))
//             .toList();

//         return Result.ok(list);
//       }

//       // Non-2xx
//       String message = 'Server error (${res.statusCode})';
//       try {
//         final err = jsonDecode(res.body);
//         if (err is Map && err['message'] != null) {
//           message = err['message'].toString();
//         }
//       } catch (_) {}
//       return Result.fail(
//         Failure(
//           code: 'server',
//           message: message,
//           statusCode: res.statusCode,
//         ),
//       );
//     } on SocketException {
//       return Result.fail(
//         Failure(code: 'network', message: 'No internet connection'),
//       );
//     } on TimeoutException {
//       return Result.fail(
//         Failure(code: 'timeout', message: 'Request timed out'),
//       );
//     } catch (e) {
//       return Result.fail(
//         Failure(code: 'unknown', message: e.toString()),
//       );
//     }
//   }

//   @override
//   Future<Result<RegistrationResponse>> changePassword({
//     required String password,
//     required String userId,
//   }) async {
//     final uri =
//         Uri.parse('${ApiConfig.baseUrl}${ApiConfig.changePasswordEndpoint}');
//     final body = {
//       "password": password,
//       "userId": userId,
//     };

//     try {
//       print('>>> VERIFY OTP POST $uri');
//       print('>>> REQUEST: ${jsonEncode(body)}');

//       final res = await http
//           .post(uri, headers: _headers(), body: jsonEncode(body))
//           .timeout(timeout);

//       print('<<< VERIFY OTP STATUS: ${res.statusCode}');
//       print('<<< VERIFY OTP BODY: ${res.body}');

//       if (res.statusCode >= 200 && res.statusCode < 300) {
//         final parsed = jsonDecode(res.body);
//         if (parsed is! Map<String, dynamic>) {
//           return Result.fail(
//             Failure(
//               code: 'parse',
//               message: 'Invalid response format',
//               statusCode: res.statusCode,
//             ),
//           );
//         }

//         final resp = RegistrationResponse.fromJson(parsed);
//         if (!resp.isSuccess) {
//           return Result.fail(
//             Failure(
//               code: 'validation',
//               message: resp.message ?? 'OTP verification failed',
//               statusCode: res.statusCode,
//             ),
//           );
//         }

//         return Result.ok(resp);
//       }

//       return Result.fail(
//         Failure(
//           code: 'server',
//           message: 'Server error ${res.statusCode}',
//           statusCode: res.statusCode,
//         ),
//       );
//     } on SocketException {
//       return Result.fail(
//         Failure(code: 'network', message: 'No internet connection'),
//       );
//     } on TimeoutException {
//       return Result.fail(
//         Failure(code: 'timeout', message: 'Request timed out'),
//       );
//     } catch (e) {
//       return Result.fail(
//         Failure(code: 'unknown', message: e.toString()),
//       );
//     }
//   }

//   @override
//   Future<Result<RegistrationResponse>> verifyOtpThroughEmail({
//     required String userId,
//     required String email,
//     required String code,
//   }) async {
//     final uri =
//         Uri.parse('${ApiConfig.baseUrl}${ApiConfig.verifyOtpEmailEndpoint}');
//     final body = {
//       "userId": userId,
//       "email": email,
//       "code": code,
//     };

//     try {
//       print('>>> VERIFY OTP POST $uri');
//       print('>>> REQUEST: ${jsonEncode(body)}');

//       final res = await http
//           .post(uri, headers: _headers(), body: jsonEncode(body))
//           .timeout(timeout);

//       print('<<< VERIFY OTP STATUS: ${res.statusCode}');
//       print('<<< VERIFY OTP BODY: ${res.body}');

//       if (res.statusCode >= 200 && res.statusCode < 300) {
//         final parsed = jsonDecode(res.body);
//         if (parsed is! Map<String, dynamic>) {
//           return Result.fail(
//             Failure(
//               code: 'parse',
//               message: 'Invalid response format',
//               statusCode: res.statusCode,
//             ),
//           );
//         }

//         final resp = RegistrationResponse.fromJson(parsed);
//         if (!resp.isSuccess) {
//           return Result.fail(
//             Failure(
//               code: 'validation',
//               message: resp.message ?? 'OTP verification failed',
//               statusCode: res.statusCode,
//             ),
//           );
//         }

//         return Result.ok(resp);
//       }

//       return Result.fail(
//         Failure(
//           code: 'server',
//           message: 'Server error ${res.statusCode}',
//           statusCode: res.statusCode,
//         ),
//       );
//     } on SocketException {
//       return Result.fail(
//         Failure(code: 'network', message: 'No internet connection'),
//       );
//     } on TimeoutException {
//       return Result.fail(
//         Failure(code: 'timeout', message: 'Request timed out'),
//       );
//     } catch (e) {
//       return Result.fail(
//         Failure(code: 'unknown', message: e.toString()),
//       );
//     }
//   }

//   @override
//   Future<Result<RegistrationResponse>> forgotPassword({
//     required String email,
//   }) async {
//     final uri =
//         Uri.parse('${ApiConfig.baseUrl}${ApiConfig.forgotPasswordEndpoint}');
//     final body = {"identifier": email};

//     try {
//       print('>>> VERIFY OTP POST $uri');
//       print('>>> REQUEST: ${jsonEncode(body)}');

//       final res = await http
//           .post(uri, headers: _headers(), body: jsonEncode(body))
//           .timeout(timeout);

//       print('<<< VERIFY OTP STATUS: ${res.statusCode}');
//       print('<<< VERIFY OTP BODY: ${res.body}');

//       if (res.statusCode >= 200 && res.statusCode < 300) {
//         final parsed = jsonDecode(res.body);
//         if (parsed is! Map<String, dynamic>) {
//           return Result.fail(
//             Failure(
//               code: 'parse',
//               message: 'Invalid response format',
//               statusCode: res.statusCode,
//             ),
//           );
//         }

//         final resp = RegistrationResponse.fromJson(parsed);
//         if (!resp.isSuccess) {
//           return Result.fail(
//             Failure(
//               code: 'validation',
//               message: resp.message ?? 'OTP verification failed',
//               statusCode: res.statusCode,
//             ),
//           );
//         }

//         return Result.ok(resp);
//       }

//       return Result.fail(
//         Failure(
//           code: 'server',
//           message: 'Server error ${res.statusCode}',
//           statusCode: res.statusCode,
//         ),
//       );
//     } on SocketException {
//       return Result.fail(
//         Failure(code: 'network', message: 'No internet connection'),
//       );
//     } on TimeoutException {
//       return Result.fail(
//         Failure(code: 'timeout', message: 'Request timed out'),
//       );
//     } catch (e) {
//       return Result.fail(
//         Failure(code: 'unknown', message: e.toString()),
//       );
//     }
//   }

//   @override
//   Future<Result<RegistrationResponse>> verifyOtpThroughPhone({
//     required String userId,
//     required String phone,
//     required String code,
//   }) async {
//     final uri =
//         Uri.parse('${ApiConfig.baseUrl}${ApiConfig.verifyOtpPhoneEndpoint}');
//     final body = {
//       "userId": userId,
//       "phone": phone,
//       "code": code,
//     };

//     try {
//       print('>>> VERIFY OTP POST $uri');
//       print('>>> REQUEST: ${jsonEncode(body)}');

//       final res = await http
//           .post(uri, headers: _headers(), body: jsonEncode(body))
//           .timeout(timeout);

//       print('<<< VERIFY OTP STATUS: ${res.statusCode}');
//       print('<<< VERIFY OTP BODY: ${res.body}');

//       if (res.statusCode >= 200 && res.statusCode < 300) {
//         final parsed = jsonDecode(res.body);
//         if (parsed is! Map<String, dynamic>) {
//           return Result.fail(
//             Failure(
//               code: 'parse',
//               message: 'Invalid response format',
//               statusCode: res.statusCode,
//             ),
//           );
//         }

//         final resp = RegistrationResponse.fromJson(parsed);
//         if (!resp.isSuccess) {
//           return Result.fail(
//             Failure(
//               code: 'validation',
//               message: resp.message ?? 'OTP verification failed',
//               statusCode: res.statusCode,
//             ),
//           );
//         }

//         return Result.ok(resp);
//       }

//       return Result.fail(
//         Failure(
//           code: 'server',
//           message: 'Server error ${res.statusCode}',
//           statusCode: res.statusCode,
//         ),
//       );
//     } on SocketException {
//       return Result.fail(
//         Failure(code: 'network', message: 'No internet connection'),
//       );
//     } on TimeoutException {
//       return Result.fail(
//         Failure(code: 'timeout', message: 'Request timed out'),
//       );
//     } catch (e) {
//       return Result.fail(
//         Failure(code: 'unknown', message: e.toString()),
//       );
//     }
//   }

//   Future<Result<RegistrationResponse>> _postRegistration(
//       Map<String, dynamic> body) async {
//     try {
//       print('>>> POST $_signupUri');
//       print('>>> REQUEST: ${jsonEncode(body)}');

//       final res = await http
//           .post(_signupUri, headers: _headers(), body: jsonEncode(body))
//           .timeout(timeout);

//       print('<<< STATUS: ${res.statusCode}');
//       print('<<< BODY: ${res.body}');

//       if (res.statusCode >= 200 && res.statusCode < 300) {
//         final parsed = jsonDecode(res.body);
//         if (parsed is! Map<String, dynamic>) {
//           return Result.fail(
//             Failure(
//               code: 'parse',
//               message: 'Invalid response format',
//               statusCode: res.statusCode,
//             ),
//           );
//         }

//         final resp = RegistrationResponse.fromJson(parsed);
//         if (!resp.isSuccess) {
//           String msg = resp.message ?? 'Verification failed';
//           if (resp.errors.isNotEmpty) {
//             final first = resp.errors.first;
//             msg =
//                 '${first.field.isEmpty ? '' : '${first.field}: '}${first.error}';
//           }
//           return Result.fail(
//             Failure(
//               code: 'validation',
//               message: msg,
//               statusCode: res.statusCode,
//             ),
//           );
//         }

//         return Result.ok(resp);
//       }

//       // Non-2xx
//       String message = 'Server error (${res.statusCode})';
//       try {
//         final err = jsonDecode(res.body);
//         if (err is Map && err['message'] != null) {
//           message = err['message'].toString();
//         }
//       } catch (_) {}
//       return Result.fail(
//         Failure(
//           code: 'server',
//           message: message,
//           statusCode: res.statusCode,
//         ),
//       );
//     } on SocketException {
//       return Result.fail(
//         Failure(code: 'network', message: 'No internet connection'),
//       );
//     } on TimeoutException {
//       return Result.fail(
//         Failure(code: 'timeout', message: 'Request timed out'),
//       );
//     } catch (e) {
//       return Result.fail(
//         Failure(code: 'unknown', message: e.toString()),
//       );
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

//     return _postRegistration(request.toJson());
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
//       //desiredService: desiredService ?? const [],
//     ); 
//     return register(req);
//   }

//   // ---------------- Login ----------------
//   @override
//   Future<Result<LoginResponse>> signIn({
//     required String email,
//     required String password,
//   }) async {
//     final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.signInEndpoint}');
//     final body = {"email": email, "password": password, "phoneNumber": ""};

//     try {
//       print('>>> LOGIN POST $uri');
//       print('>>> REQUEST: ${jsonEncode(body)}');

//       final res = await http
//           .post(uri, headers: _headers(), body: jsonEncode(body))
//           .timeout(timeout);

//       print('<<< LOGIN STATUS: ${res.statusCode}');
//       print('<<< LOGIN BODY: ${res.body}');

//       if (res.statusCode >= 200 && res.statusCode < 300) {
//         final parsed = jsonDecode(res.body);
//         if (parsed is! Map<String, dynamic>) {
//           return Result.fail(
//             Failure(
//               code: 'parse',
//               message: 'Invalid response format',
//               statusCode: res.statusCode,
//             ),
//           );
//         }

//         final resp = LoginResponse.fromJson(parsed);
//         if (!resp.isSuccess) {
//           return Result.fail(
//             Failure(
//               code: 'validation',
//               message: resp.message ?? 'Login failed',
//               statusCode: res.statusCode,
//             ),
//           );
//         }

//         return Result.ok(resp);
//       }

//       return Result.fail(
//         Failure(
//           code: 'server',
//           message: 'Server error ${res.statusCode}',
//           statusCode: res.statusCode,
//         ),
//       );
//     } on SocketException {
//       return Result.fail(
//         Failure(code: 'network', message: 'No internet connection'),
//       );
//     } on TimeoutException {
//       return Result.fail(
//         Failure(code: 'timeout', message: 'Request timed out'),
//       );
//     } catch (e) {
//       return Result.fail(
//         Failure(code: 'unknown', message: e.toString()),
//       );
//     }
//   }

//   // ---------------- Send OTP via Email ----------------
//   @override
//   Future<Result<RegistrationResponse>> sendOtpThroughEmail({
//     required String userId,
//     required String email,
//   }) async {
//     final uri = Uri.parse(
//         '${ApiConfig.baseUrl}${ApiConfig.sendOTPThroughEmailEndpoint}');
//     final body = {
//       "userId": userId,
//       "email": email,
//     };

//     try {
//       print('>>> SEND OTP POST $uri');
//       print('>>> REQUEST: ${jsonEncode(body)}');

//       final res = await http
//           .post(uri, headers: _headers(), body: jsonEncode(body))
//           .timeout(timeout);

//       print('<<< SEND OTP STATUS: ${res.statusCode}');
//       print('<<< SEND OTP BODY: ${res.body}');

//       if (res.statusCode >= 200 && res.statusCode < 300) {
//         final parsed = jsonDecode(res.body);
//         if (parsed is! Map<String, dynamic>) {
//           return Result.fail(
//             Failure(
//               code: 'parse',
//               message: 'Invalid response format',
//               statusCode: res.statusCode,
//             ),
//           );
//         }

//         final resp = RegistrationResponse.fromJson(parsed);
//         if (!resp.isSuccess) {
//           return Result.fail(
//             Failure(
//               code: 'validation',
//               message: resp.message ?? 'OTP failed',
//               statusCode: res.statusCode,
//             ),
//           );
//         }

//         return Result.ok(resp);
//       }

//       return Result.fail(
//         Failure(
//           code: 'server',
//           message: 'Server error ${res.statusCode}',
//           statusCode: res.statusCode,
//         ),
//       );
//     } on SocketException {
//       return Result.fail(
//         Failure(code: 'network', message: 'No internet connection'),
//       );
//     } on TimeoutException {
//       return Result.fail(
//         Failure(code: 'timeout', message: 'Request timed out'),
//       );
//     } catch (e) {
//       return Result.fail(
//         Failure(code: 'unknown', message: e.toString()),
//       );
//     }
//   }

//   @override
//   Future<Result<RegistrationResponse>> sendOtpThroughPhone({
//     required String userId,
//     required String phoneNumber,
//   }) async {
//     final uri = Uri.parse(
//         '${ApiConfig.baseUrl}${ApiConfig.sendOTPThroughPhoneEndpoint}');
//     final body = {
//       "userId": userId,
//       "phoneNumber": phoneNumber,
//     };

//     try {
//       print('>>> SEND OTP POST $uri');
//       print('>>> REQUEST: ${jsonEncode(body)}');

//       final res = await http
//           .post(uri, headers: _headers(), body: jsonEncode(body))
//           .timeout(timeout);

//       print('<<< SEND OTP STATUS: ${res.statusCode}');
//       print('<<< SEND OTP BODY: ${res.body}');

//       if (res.statusCode >= 200 && res.statusCode < 300) {
//         final parsed = jsonDecode(res.body);
//         if (parsed is! Map<String, dynamic>) {
//           return Result.fail(
//             Failure(
//               code: 'parse',
//               message: 'Invalid response format',
//               statusCode: res.statusCode,
//             ),
//           );
//         }

//         final resp = RegistrationResponse.fromJson(parsed);
//         if (!resp.isSuccess) {
//           return Result.fail(
//             Failure(
//               code: 'validation',
//               message: resp.message ?? 'OTP failed',
//               statusCode: res.statusCode,
//             ),
//           );
//         }

//         return Result.ok(resp);
//       }

//       return Result.fail(
//         Failure(
//           code: 'server',
//           message: 'Server error ${res.statusCode}',
//           statusCode: res.statusCode,
//         ),
//       );
//     } on SocketException {
//       return Result.fail(
//         Failure(code: 'network', message: 'No internet connection'),
//       );
//     } on TimeoutException {
//       return Result.fail(
//         Failure(code: 'timeout', message: 'Request timed out'),
//       );
//     } catch (e) {
//       return Result.fail(
//         Failure(code: 'unknown', message: e.toString()),
//       );
//     }
//   }
// }



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
