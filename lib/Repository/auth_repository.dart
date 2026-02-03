import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:taskoon/Models/add_booking_request_model.dart';
import 'package:taskoon/Models/add_booking_request_wrapper.dart';
import 'package:taskoon/Models/booking_create_response.dart';
import 'package:taskoon/Models/booking_find_response.dart';
import 'package:taskoon/Models/named_bytes.dart';
import 'package:taskoon/Models/service_document_model.dart';
import 'package:taskoon/Models/training_videos_model.dart';
import 'package:taskoon/Models/user_details_model.dart';
import '../Models/auth_model.dart';
import '../Models/login_responnse.dart';
import '../Models/services_model.dart';
import 'package:http_parser/http_parser.dart' show MediaType;

class ApiConfig {
  static const String baseUrl ='https://dev-api.taskoon.com';//'http://76.13.20.161'; //'https://api.taskoon.com';//'http://192.3.3.187:85';
  static const String baseUrlLocation = 'https://dev-api.taskoon.com';//'http://76.13.20.161';//'https://api.taskoon.com';
  static const String userStatusEndpoint = '/api/User/status';
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
  static const String certificateSubmitEndpoint =
      '/api/services/CertificateSubmit';
  static const String userDetailsEndpoint = '/api/User/details';
  static const String onboardingUserEndpoint = '/api/user/onboardinguser';
  static const String trainingVideosEndpoint = '/api/Services/trainingvideos';
  //user booking
  static const String bookingEndpoint = '/api/booking/create';
  static const String bookingFindEndpoint = '/api/Tasker/Find';
  static const String bookingAcceptEndpoint = '/api/tasker/accept';
  static const String bookingCancelEndpoint = '/api/booking/cancel';
  static const String bookingGetEndpoint = '/api/Booking/booking';
  static const String updateLocationEndpoint = '/api/Address/update/location';
  static const String changeAvailabilityStatusEndpoint = '/api/user/available/status';

  //SOS
  static const String sosStartEndpoint = '/api/sos/start';
  static const String sosUpdateLocationEndpoint = '/api/sos/location';
}

extension on String {
  String normMime() {
    final v = toLowerCase();
    if (v == 'image/jpg') return 'image/jpeg';
    if (v == 'application/x-pdf') return 'application/pdf';
    return v;
  }
}

abstract class AuthRepository {
      //SOS
    Future<Result<RegistrationResponse>> startSos({
    required String taskerUserId,
    required String bookingDetailId,
    required double latitude,
    required double longitude,
  });
      //SOS
  Future<Result<RegistrationResponse>> updateSosLocation({
    required String sosId,
    required double latitude,
    required double longitude,
  });

    Future<Result<RegistrationResponse>> cancelBookingPut({
    required String bookingDetailId,
    required String userId,
    required String reason,
  });


  
  Future<Result<RegistrationResponse>> updateUserLocation({
    required String userId,
    required double latitude,
    required double longitude,
  });

    Future<Result<RegistrationResponse>> changeAvailbilityStatusTasker({
    required String userId
  });


  Future<Result<RegistrationResponse>> acceptBooking({
    required String userId,
    required String bookingId,
  });

  
Future<Result<BookingFindResponse>> findBooking({
  required String bookingDetailId
});

Future<Result<BookingCreateResponse>> createBooking({
required String userId,
  required int subCategoryId,
  required int bookingTypeId,
  required DateTime bookingDate,
  required DateTime startTime,
  required DateTime endTime,
  required String address,
  required int taskerLevelId,
  DateTime? endDate,
  int? recurrencePatternId,
  String? customDays,
  required double latitude,
  required double longitude,
});


  Future<Result<RegistrationResponse>> getUserStatus({
    String? userId,
    String? email,
    String? phone,
    bool? isActive,
  });

  Future<Result<RegistrationResponse>> onboardUser({
    required String userId,
    List<int> servicesId, // default = const []
    required NamedBytes profilePicture,
    NamedBytes? docCertification, // null/empty => send tiny valid placeholder
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
        int? taskerLevelId,
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
Future<Result<RegistrationResponse>> startSos({
  required String taskerUserId,
  required String bookingDetailId,
  required double latitude,
  required double longitude,
}) async {
  final uri = Uri.parse(
    '${ApiConfig.baseUrlLocation}${ApiConfig.sosStartEndpoint}',
  );

  final body = <String, dynamic>{
    "taskerUserId": taskerUserId,
    "bookingDetailId": bookingDetailId,
    "latitude": latitude,
    "longitude": longitude,
  };

  try {
    print('>>> SOS START POST $uri');
    print('>>> REQUEST: ${jsonEncode(body)}');

    final res = await http
        .post(uri, headers: _headers(), body: jsonEncode(body))
        .timeout(timeout);

    print('<<< SOS START STATUS: ${res.statusCode}');
    print('<<< SOS START BODY: ${res.body}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final raw = res.body.trim();
      if (raw.isEmpty) {
        return Result.ok(
          RegistrationResponse(isSuccess: true, message: 'SOS started'),
        );
      }

      final parsed = jsonDecode(raw);
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
            message: resp.message ?? 'SOS start failed',
            statusCode: res.statusCode,
          ),
        );
      }

      return Result.ok(resp);
    }

    // non-2xx: try parse message from backend
    String message = 'Server error (${res.statusCode})';
    final raw = res.body.trim();
    if (raw.isNotEmpty) {
      try {
        final err = jsonDecode(raw);
        if (err is Map && err['message'] != null) {
          message = err['message'].toString();
        } else if (err is Map && err['errors'] is List) {
          final errors = (err['errors'] as List)
              .map((e) => '${e['field']}: ${e['error']}')
              .join(' • ');
          if (errors.isNotEmpty) message = errors;
        }
      } catch (_) {}
    }

    return Result.fail(
      Failure(code: 'server', message: message, statusCode: res.statusCode),
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
Future<Result<RegistrationResponse>> updateSosLocation({
  required String sosId,
  required double latitude,
  required double longitude,
}) async {
  final uri = Uri.parse(
    '${ApiConfig.baseUrlLocation}${ApiConfig.sosUpdateLocationEndpoint}',
  );

  final body = <String, dynamic>{
    "sosId": sosId,
    "latitude": latitude,
    "longitude": longitude,
  };

  try {
    print('>>> SOS LOCATION PUT $uri');
    print('>>> REQUEST: ${jsonEncode(body)}');

    final res = await http
        .put(uri, headers: _headers(), body: jsonEncode(body))
        .timeout(timeout);

    print('<<< SOS LOCATION STATUS: ${res.statusCode}');
    print('<<< SOS LOCATION BODY: ${res.body}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final raw = res.body.trim();
      if (raw.isEmpty) {
        return Result.ok(
          RegistrationResponse(isSuccess: true, message: 'SOS location updated'),
        );
      }

      final parsed = jsonDecode(raw);
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
            message: resp.message ?? 'SOS location update failed',
            statusCode: res.statusCode,
          ),
        );
      }

      return Result.ok(resp);
    }

    // non-2xx
    String message = 'Server error (${res.statusCode})';
    final raw = res.body.trim();
    if (raw.isNotEmpty) {
      try {
        final err = jsonDecode(raw);
        if (err is Map && err['message'] != null) {
          message = err['message'].toString();
        } else if (err is Map && err['errors'] is List) {
          final errors = (err['errors'] as List)
              .map((e) => '${e['field']}: ${e['error']}')
              .join(' • ');
          if (errors.isNotEmpty) message = errors;
        }
      } catch (_) {}
    }

    return Result.fail(
      Failure(code: 'server', message: message, statusCode: res.statusCode),
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
Future<Result<RegistrationResponse>> cancelBookingPut({
  required String bookingDetailId,
  required String userId,
  required String reason,
}) async {
  final uri = Uri.parse(
    '${ApiConfig.baseUrlLocation}${ApiConfig.bookingCancelEndpoint}',
  );

  final body = <String, dynamic>{
    "bookingId": bookingDetailId,
    "userId": userId,
    "reason": reason,
  };

  try {
    print('>>> CANCEL BOOKING POST $uri');
    print('>>> REQUEST: ${jsonEncode(body)}');

    final res = await http
        .post(uri, headers: _headers(), body: jsonEncode(body))
        .timeout(timeout);

    print('<<< CANCEL BOOKING STATUS: ${res.statusCode}');
    print('<<< CANCEL BOOKING BODY: ${res.body}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final raw = res.body.trim();
      if (raw.isEmpty) {
        return Result.ok(
          RegistrationResponse(isSuccess: true, message: 'Booking cancelled'),
        );
      }

      final parsed = jsonDecode(raw);
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
            message: resp.message ?? 'Booking cancel failed',
            statusCode: res.statusCode,
          ),
        );
      }

      return Result.ok(resp);
    }

    // non-2xx
    String message = 'Server error (${res.statusCode})';
    final raw = res.body.trim();
    if (raw.isNotEmpty) {
      try {
        final err = jsonDecode(raw);

        // if backend returns { message: "...", errors:[...] }
        if (err is Map && err['message'] != null) {
          message = err['message'].toString();
        } else if (err is Map && err['errors'] is List) {
          final errors = (err['errors'] as List)
              .map((e) => '${e['field']}: ${e['error']}')
              .join(' • ');
          if (errors.isNotEmpty) message = errors;
        }
      } catch (_) {}
    }

    return Result.fail(
      Failure(code: 'server', message: message, statusCode: res.statusCode),
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
  Future<Result<RegistrationResponse>> getUserStatus({
    String? userId,
    String? email,
    String? phone,
    bool? isActive,
  }) async {
    // Base URI: http://.../api/User/status
    final base =
        '${ApiConfig.baseUrlLocation}${ApiConfig.userStatusEndpoint}';

    // Build query parameters only for non-empty values
    final query = <String, String>{};

    if (userId != null && userId.trim().isNotEmpty) {
      query['UserId'] = userId;
    }
    if (email != null && email.trim().isNotEmpty) {
      query['Email'] = email;
    }
    if (phone != null && phone.trim().isNotEmpty) {
      query['Phone'] = phone;
    }
    if (isActive != null) {
      // Swagger shows IsActive boolean – backend usually expects "true"/"false"
      query['IsActive'] = isActive.toString();
    }

    final uri = Uri.parse(base).replace(queryParameters: query.isEmpty ? null : query);

    try {
      print('>>> USER STATUS GET $uri');

      final res = await http.get(uri, headers: _headers()).timeout(timeout);

      print('<<< USER STATUS STATUS: ${res.statusCode}');
      print('<<< USER STATUS BODY: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final raw = res.body.trim();
        if (raw.isEmpty) {
          return Result.fail(
            Failure(
              code: 'empty',
              message: 'Empty response from server',
              statusCode: res.statusCode,
            ),
          );
        }

        final parsed = jsonDecode(raw);
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
              message: resp.message ?? 'Failed to get user status',
              statusCode: res.statusCode,
            ),
          );
        }

        return Result.ok(resp);
      }

      // non-2xx
      String message = 'Server error (${res.statusCode})';
      final raw = res.body.trim();
      if (raw.isNotEmpty) {
        try {
          final err = jsonDecode(raw);
          if (err is Map && err['message'] != null) {
            message = err['message'].toString();
          }
        } catch (_) {}
      }

      return Result.fail(
        Failure(code: 'server', message: message, statusCode: res.statusCode),
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
Future<Result<RegistrationResponse>> changeAvailbilityStatusTasker({
  required String userId,
}) async {
  final baseUri =
      '${ApiConfig.baseUrlLocation}${ApiConfig.changeAvailabilityStatusEndpoint}';

  // Pass userId and isOnline in query params
  final uri = Uri.parse(baseUri).replace(queryParameters: {
    'userId': userId,
    'isOnline': 'true',
  });

  try {
    //print('>>> CHANGE AVAILABILITY STATUS [GET] $uri');

    final res = await http.get(uri, headers: _headers()).timeout(timeout);

  //  print('<<< CHANGE AVAILABILITY STATUS: ${res.statusCode}');
 //   print('<<< CHANGE AVAILABILITY BODY: ${res.body}');

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
            message: resp.message ?? 'Availability update failed',
            statusCode: res.statusCode,
          ),
        );
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

    return Result.fail(
      Failure(code: 'server', message: message, statusCode: res.statusCode),
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
    return Result.fail(Failure(code: 'unknown', message: e.toString()));
  }
}



  @override
  Future<Result<RegistrationResponse>> updateUserLocation({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrlLocation}${ApiConfig.updateLocationEndpoint}',
    );

    final body = <String, dynamic>{
      "userId": userId,
      "latitude": latitude,
      "longitude": longitude,
    };

    try {
      // print('>>> UPDATE LOCATION POST $uri');
      // print('>>> REQUEST: ${jsonEncode(body)}');

      final res = await http
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(timeout);

      // print('<<< UPDATE LOCATION STATUS: ${res.statusCode}');
      // print('<<< UPDATE LOCATION BODY: ${res.body}');

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
              message: resp.message ?? 'Location update failed',
              statusCode: res.statusCode,
            ),
          );
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

      return Result.fail(
        Failure(code: 'server', message: message, statusCode: res.statusCode),
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
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  // @override
  // Future<Result<RegistrationResponse>> cancelBooking({
  //   required String bookingId,
  //   required String userId,
  //   required String reason,
  // }) async {
  //   final uri = Uri.parse(
  //     '${ApiConfig.baseUrlLocation}${ApiConfig.bookingCancelEndpoint}',
  //   );

  //   final body = <String, dynamic>{
  //     "bookingId": bookingId,
  //     "userId": userId,
  //     "reason": reason,
  //   };

  //   try {
  //     print('>>> BOOKING CANCEL PUT $uri');
  //     print('>>> REQUEST: ${jsonEncode(body)}');

  //     final res = await http
  //         .put(uri, headers: _headers(), body: jsonEncode(body))
  //         .timeout(timeout);

  //     print('<<< BOOKING CANCEL STATUS: ${res.statusCode}');
  //     print('<<< BOOKING CANCEL BODY: ${res.body}');

  //     if (res.statusCode >= 200 && res.statusCode < 300) {
  //       final parsed = jsonDecode(res.body);
  //       if (parsed is! Map<String, dynamic>) {
  //         return Result.fail(
  //           Failure(
  //             code: 'parse',
  //             message: 'Invalid response format',
  //             statusCode: res.statusCode,
  //           ),
  //         );
  //       }

  //       final resp = RegistrationResponse.fromJson(parsed);
  //       if (!resp.isSuccess) {
  //         return Result.fail(
  //           Failure(
  //             code: 'validation',
  //             message: resp.message ?? 'Booking cancel failed',
  //             statusCode: res.statusCode,
  //           ),
  //         );
  //       }

  //       return Result.ok(resp);
  //     }

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
  //     return Result.fail(
  //       Failure(code: 'network', message: 'No internet connection'),
  //     );
  //   } on TimeoutException {
  //     return Result.fail(
  //       Failure(code: 'timeout', message: 'Request timed out'),
  //     );
  //   } catch (e) {
  //     return Result.fail(Failure(code: 'unknown', message: e.toString()));
  //   }
  // }

  @override
  Future<Result<RegistrationResponse>> acceptBooking({
    required String userId,
    required String bookingId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrlLocation}${ApiConfig.bookingAcceptEndpoint}',
    );

    final body = <String, dynamic>{"userId": userId, "bookingDetailId": bookingId};

    try {
      print('>>> BOOKING ACCEPT POST $uri');
      print('>>> REQUEST: ${jsonEncode(body)}');

      final res = await http
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(timeout);

      print('<<< BOOKING ACCEPT STATUS: ${res.statusCode}');
      print('<<< BOOKING ACCEPT BODY: ${res.body}');

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
              message: resp.message ?? 'Booking accept failed',
              statusCode: res.statusCode,
            ),
          );
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

      return Result.fail(
        Failure(code: 'server', message: message, statusCode: res.statusCode),
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
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  @override
Future<Result<BookingFindResponse>> findBooking({
  required String bookingDetailId,
}) async {
  final uri = Uri.parse(
    '${ApiConfig.baseUrlLocation}${ApiConfig.bookingFindEndpoint}',
  );

  final body = <String, dynamic>{
    'bookingDetailId': bookingDetailId,
  };

  try {
    print('>>> BOOKING FIND POST $uri');
    print('>>> REQUEST: ${jsonEncode(body)}');

    final res = await http
        .post(uri, headers: _headers(), body: jsonEncode(body))
        .timeout(timeout);

    print('<<< BOOKING FIND STATUS: ${res.statusCode}');
    print('<<< BOOKING FIND BODY: ${res.body}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final raw = res.body.trim();
      if (raw.isEmpty) {
        return Result.fail(
          Failure(code: 'empty', message: 'Empty response from server'),
        );
      }

      final parsed = jsonDecode(raw);
      if (parsed is! Map<String, dynamic>) {
        return Result.fail(
          Failure(code: 'parse', message: 'Invalid response format'),
        );
      }

      final resp = BookingFindResponse.fromJson(parsed);

      if (!resp.isSuccess) {
        // if server returned errors list, flatten it
        final serverErrors = (resp.errors ?? [])
            .map((e) => '${e.field ?? ""}: ${e.error ?? ""}'.trim())
            .where((s) => s.isNotEmpty)
            .join(' • ');

        return Result.fail(
          Failure(
            code: 'validation',
            message: serverErrors.isNotEmpty
                ? serverErrors
                : (resp.message ?? 'Find booking failed'),
            statusCode: res.statusCode,
          ),
        );
      }

      return Result.ok(resp);
    }

    // non-2xx error flattening
    String message = 'Server error (${res.statusCode})';
    final raw = res.body.trim();
    if (raw.isNotEmpty) {
      try {
        final err = jsonDecode(raw);
        if (err is Map && err['errors'] is List) {
          final errors = (err['errors'] as List)
              .map((e) => '${e['field']}: ${e['error']}')
              .join(' • ');
          if (errors.isNotEmpty) message = errors;
        } else if (err is Map && err['message'] != null) {
          message = err['message'].toString();
        }
      } catch (_) {}
    }

    return Result.fail(
      Failure(code: 'server', message: message, statusCode: res.statusCode),
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
    return Result.fail(Failure(code: 'unknown', message: e.toString()));
  }
}

Future<Result<BookingCreateResponse>> createBooking({
  required String userId,
  required int subCategoryId,
  required int bookingTypeId,
  required DateTime bookingDate,
  DateTime? endDate,
  required DateTime startTime,
  required DateTime endTime,
  required String address,
  required int taskerLevelId,
  int? recurrencePatternId,
  String? customDays,
  required double latitude,
  required double longitude,
}) async {
  final uri = Uri.parse('${ApiConfig.baseUrl}/api/booking/create');

  final model = AddBookingRequestModel(
    userId: userId,
    subCategoryId: subCategoryId,
    bookingTypeId: bookingTypeId,
    bookingDate: bookingDate,
    startTime: startTime,
    endTime: endTime,
    address: address,
    taskerLevelId: taskerLevelId,
    endDate: endDate,
    recurrencePatternId: recurrencePatternId,
    customDays: customDays,
    latitude: latitude,
    longitude: longitude,
  );

  try {
    debugPrint('>>> BOOKING CREATE POST $uri');
    debugPrint('>>> REQUEST: ${jsonEncode(model.toJson())}'); // ✅ no wrapper

    final res = await http
        .post(
          uri,
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(model.toJson()), // ✅ no wrapper
        )
        .timeout(const Duration(seconds: 30));

    debugPrint('<<< BOOKING CREATE STATUS: ${res.statusCode}');
    debugPrint('<<< BOOKING CREATE BODY: ${res.body}');

    final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
    final parsed = BookingCreateResponse.fromJson(jsonMap);

    // ✅ success is controlled by isSuccess from API
    if (res.statusCode >= 200 && res.statusCode < 300 && parsed.isSuccess) {
      return Result.ok(parsed);
    }

    // ✅ build readable error from errors[]
    String errText = parsed.message.isNotEmpty ? parsed.message : "Validation failed";
    final errs = parsed.errors;
    if (errs != null && errs.isNotEmpty) {
      errText = errs
          .map((e) => "${e.field ?? ''}${(e.field ?? '').isEmpty ? '' : ': '}${e.error ?? ''}")
          .join(" | ");
    }

    return Result.fail(Failure(code: res.statusCode.toString(), message: errText));
  } catch (e) {
    return Result.fail(Failure(code: "-1", message: "Create booking failed: $e"));
  }
}



  @override
  Future<Result<List<TrainingVideo>>> fetchTrainingVideos() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.trainingVideosEndpoint}',
    );
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
          return Result.fail(
            Failure(
              code: 'parse',
              message: 'Invalid JSON',
              statusCode: res.statusCode,
            ),
          );
        }
        if (parsed is! List) {
          return Result.fail(
            Failure(
              code: 'parse',
              message: 'Expected array',
              statusCode: res.statusCode,
            ),
          );
        }
        final list = parsed
            .map<TrainingVideo>(
              (e) => TrainingVideo.fromJson(e as Map<String, dynamic>),
            )
            .toList(growable: false);
        return Result.ok(list);
      }

      String message = 'Server error (${res.statusCode})';
      try {
        final err = jsonDecode(res.body);
        if (err is Map && err['message'] != null)
          message = err['message'].toString();
      } catch (_) {}
      return Result.fail(
        Failure(code: 'server', message: message, statusCode: res.statusCode),
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
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  @override
Future<Result<RegistrationResponse>> onboardUser({
  required String userId,
  List<int> servicesId = const [], 
  required NamedBytes profilePicture,
  NamedBytes? docCertification,
  required NamedBytes docInsurance,
  required NamedBytes docAddressProof,
  required NamedBytes docIdVerification,
}) async {
  if (userId.trim().isEmpty) {
    return Result.fail(Failure(code: 'validation', message: 'UserId is required'));
  }
  if (profilePicture.bytes.isEmpty ||
      docInsurance.bytes.isEmpty ||
      docAddressProof.bytes.isEmpty ||
      docIdVerification.bytes.isEmpty) {
    return Result.fail(
      Failure(code: 'validation', message: 'All required files must be provided'),
    );
  }

  final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.onboardingUserEndpoint}');

  // ✅ HARDCODE service exactly like Postman success
  const int hardcodedServiceId = 1;

  try {
    // ignore: avoid_print
    print('>>> [ONBOARD] URL: $uri');
    // ignore: avoid_print
    print('>>> [ONBOARD] userId=$userId');
    // ignore: avoid_print
    print('>>> [ONBOARD] ServicesId[0]=$hardcodedServiceId (HARDCODED)');
    // ignore: avoid_print
    print(
      '>>> [ONBOARD] Doc_Certification=${(docCertification == null || docCertification.bytes.isEmpty) ? 'PLACEHOLDER' : 'SET'}',
    );

    final req = http.MultipartRequest('POST', uri)
      ..headers[HttpHeaders.acceptHeader] = 'application/json'
      ..fields['UserId'] = userId;

    // ✅ multipart list binding (ASP.NET Core)
    req.fields['ServicesId[0]'] = hardcodedServiceId.toString();

    http.MultipartFile part(String name, NamedBytes f) {
      final mime = (f.mimeType ?? '').trim();
      return http.MultipartFile.fromBytes(
        name,
        f.bytes,
        filename: f.fileName.isEmpty ? 'upload.bin' : f.fileName,
        contentType: mime.isNotEmpty ? MediaType.parse(mime) : null,
      );
    }

    // required files
    req.files.add(part('ProfilePicture', profilePicture));
    req.files.add(part('Doc_Insurance', docInsurance));
    req.files.add(part('Doc_Addressproof', docAddressProof));
    req.files.add(part('Doc_Idverification', docIdVerification));

    // certification mandatory => placeholder if missing
    if (docCertification != null && docCertification.bytes.isNotEmpty) {
      req.files.add(part('Doc_Certification', docCertification));
    } else {
      final tinyPng = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=',
      );
      req.files.add(
        http.MultipartFile.fromBytes(
          'Doc_Certification',
          tinyPng,
          filename: 'blank.png',
          contentType: MediaType('image', 'png'),
        ),
      );
    }

    // ✅ Request summary logs
    // ignore: avoid_print
    print('--- [ONBOARD] FIELDS: ${req.fields}');
    for (final f in req.files) {
      // ignore: avoid_print
      print('--- [ONBOARD] FILE ${f.field} | ${f.filename} | bytes=${f.length} | ct=${f.contentType}');
    }

    // ✅ Increase timeout for mobile uploads
    // ignore: avoid_print
    print('>>> [ONBOARD] sending multipart...');
    final streamed = await req.send().timeout(const Duration(minutes: 3));
    // ignore: avoid_print
    print('>>> [ONBOARD] got response stream, reading...');
    final res = await http.Response.fromStream(streamed);
    // ignore: avoid_print
    print('<<< [ONBOARD] STATUS ${res.statusCode}');
    // ignore: avoid_print
    print('<<< [ONBOARD] BODY ${res.body}');

    return _handleSubmitResponse(res);
  } on SocketException {
    return Result.fail(Failure(code: 'network', message: 'No internet connection'));
  } on TimeoutException {
    return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
  } catch (e) {
    return Result.fail(Failure(code: 'unknown', message: e.toString()));
  }
}
/*
  @override
Future<Result<RegistrationResponse>> onboardUser({
  required String userId,
  List<int> servicesId = const [], // will be ignored (hardcoded)
  required NamedBytes profilePicture,
  NamedBytes? docCertification,
  required NamedBytes docInsurance,
  required NamedBytes docAddressProof,
  required NamedBytes docIdVerification,
}) async {
  if (userId.trim().isEmpty) {
    return Result.fail(
      Failure(code: 'validation', message: 'UserId is required'),
    );
  }
  if (profilePicture.bytes.isEmpty ||
      docInsurance.bytes.isEmpty ||
      docAddressProof.bytes.isEmpty ||
      docIdVerification.bytes.isEmpty) {
    return Result.fail(
      Failure(code: 'validation', message: 'All required files must be provided'),
    );
  }

  final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.onboardingUserEndpoint}');

  // ✅ HARD-CODE HERE (service not dynamic)
  const int _hardcodedServiceId = 1; // <-- change to whatever you want

  try {
    // ignore: avoid_print
    print('>>> ONBOARDING POST $uri');
    // ignore: avoid_print
    print('>>> UserId=$userId');
    // ignore: avoid_print
    print('>>> ServicesId (HARDCODED) = $_hardcodedServiceId');
    // ignore: avoid_print
    print(
      '>>> Doc_Certification=${(docCertification == null || docCertification.bytes.isEmpty) ? 'PLACEHOLDER' : 'SET'}',
    );

    final req = http.MultipartRequest('POST', uri)
      ..headers[HttpHeaders.acceptHeader] = 'application/json'
      ..fields['UserId'] = userId;

    // ✅ Send exactly like Postman (but correct index 0)
    req.fields['ServicesId[0]'] = _hardcodedServiceId.toString();

    // Helper
    http.MultipartFile part(String name, NamedBytes f) {
      final mime = (f.mimeType ?? '').trim();
      return http.MultipartFile.fromBytes(
        name,
        f.bytes,
        filename: f.fileName.isEmpty ? 'upload.bin' : f.fileName,
        contentType: mime.isNotEmpty ? MediaType.parse(mime) : null,
      );
    }

    // Required
    req.files.add(part('ProfilePicture', profilePicture));
    req.files.add(part('Doc_Insurance', docInsurance));
    req.files.add(part('Doc_Addressproof', docAddressProof));
    req.files.add(part('Doc_Idverification', docIdVerification));

    // Certification (MANDATORY → placeholder if missing)
    if (docCertification != null && docCertification.bytes.isNotEmpty) {
      req.files.add(part('Doc_Certification', docCertification));
    } else {
      final tinyPng = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=',
      );
      req.files.add(
        http.MultipartFile.fromBytes(
          'Doc_Certification',
          tinyPng,
          filename: 'blank.png',
          contentType: MediaType('image', 'png'),
        ),
      );
    }

    // ✅ Debug summary
    // ignore: avoid_print
    print('--- REQUEST FIELDS --- ${req.fields}');
    for (final f in req.files) {
      // ignore: avoid_print
      print('--- FILE: ${f.field} | ${f.filename} | bytes=${f.length} | ct=${f.contentType}');
    }

    final streamed = await req.send().timeout(timeout);
    final res = await http.Response.fromStream(streamed);

    // ignore: avoid_print
    print('<<< STATUS ${res.statusCode}');
    // ignore: avoid_print
    print('<<< BODY ${res.body}');

    return _handleSubmitResponse(res);
  } on SocketException {
    return Result.fail(Failure(code: 'network', message: 'No internet connection'));
  } on TimeoutException {
    return Result.fail(Failure(code: 'timeout', message: 'Request timed out'));
  } catch (e) {
    return Result.fail(Failure(code: 'unknown', message: e.toString()));
  }
}*/

/*
  @override
  Future<Result<RegistrationResponse>> onboardUser({
    required String userId,
    List<int> servicesId = const [], // empty allowed (we’ll send 0)
    required NamedBytes profilePicture, // required
    NamedBytes? docCertification, // null/empty => placeholder
    required NamedBytes docInsurance, // required
    required NamedBytes docAddressProof, // required
    required NamedBytes docIdVerification, // required
  }) async {
    // basic validation
    if (userId.trim().isEmpty) {
      return Result.fail(
        Failure(code: 'validation', message: 'UserId is required'),
      );
    }
    if (profilePicture.bytes.isEmpty ||
        docInsurance.bytes.isEmpty ||
        docAddressProof.bytes.isEmpty ||
        docIdVerification.bytes.isEmpty) {
      return Result.fail(
        Failure(
          code: 'validation',
          message: 'All required files must be provided',
        ),
      );
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.onboardingUserEndpoint}',
    );
    try {
      // Debug
      // ignore: avoid_print
      print(
        '>>> ONBOARDING POST $uri (ServicesId=${servicesId.isEmpty ? 'EMPTY→0' : servicesId.join(',')}, '
        'Doc_Certification=${(docCertification == null || docCertification.bytes.isEmpty) ? 'PLACEHOLDER' : 'SET'})',
      );

      final req = http.MultipartRequest('POST', uri)
  ..headers[HttpHeaders.acceptHeader] = 'application/json'
  ..fields['UserId'] = userId;

// ServicesId (MANDATORY)
if (servicesId.isEmpty) {
  req.fields['ServicesId[0]'] = '0';
} else {
  for (int i = 0; i < servicesId.length; i++) {
    req.fields['ServicesId[$i]'] = servicesId[i].toString();
  }
}

// Helper
http.MultipartFile part(String name, NamedBytes f) {
  final mime = (f.mimeType ?? '').trim();
  return http.MultipartFile.fromBytes(
    name,
    f.bytes,
    filename: f.fileName.isEmpty ? 'upload.bin' : f.fileName,
    contentType: mime.isNotEmpty ? MediaType.parse(mime) : null,
  );
}

// Required
req.files.add(part('ProfilePicture', profilePicture));
req.files.add(part('Doc_Insurance', docInsurance));
req.files.add(part('Doc_Addressproof', docAddressProof));
req.files.add(part('Doc_Idverification', docIdVerification));

// Certification (MANDATORY → placeholder if missing)
if (docCertification != null && docCertification.bytes.isNotEmpty) {
  req.files.add(part('Doc_Certification', docCertification));
} else {
  final tinyPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=',
  );
  req.files.add(
    http.MultipartFile.fromBytes(
      'Doc_Certification',
      tinyPng,
      filename: 'blank.png',
      contentType: MediaType('image', 'png'),
    ),
  );
}



  /*    final req = http.MultipartRequest('POST', uri)
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
        final ct = mime.isNotEmpty
            ? MediaType.parse(mime)
            : null; // let server infer if null
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

      if (docCertification != null && docCertification.bytes.isNotEmpty) {
        req.files.add(_part('Doc_Certification', docCertification));
      } else {
        // 1×1 transparent PNG (67 bytes) – valid image/png
        final tinyPng = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=',
        );
        req.files.add(
          http.MultipartFile.fromBytes(
            'Doc_Certification',
            tinyPng,
            filename: 'blank.png',
            contentType: MediaType('image', 'png'),
          ),
        );
      }
*/
      final streamed = await req.send().timeout(timeout);
      final res = await http.Response.fromStream(streamed);

      // Reuse your existing handler
      return _handleSubmitResponse(res);
    } on SocketException {
      return Result.fail(
        Failure(code: 'network', message: 'No internet connection'),
      );
    } on TimeoutException {
      return Result.fail(
        Failure(code: 'timeout', message: 'Request timed out'),
      );
    } catch (e) {
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }*/

  @override
  Future<Result<UserDetails>> fetchUserDetails({required String userId}) async {
    if (userId.trim().isEmpty) {
      return Result.fail(
        Failure(code: 'validation', message: 'UserId is required'),
      );
    }

    final base = '${ApiConfig.baseUrlLocation}${ApiConfig.userDetailsEndpoint}';
    // Only include UserId (Email/Phone are optional; don't send empty params) Testing@123
    final uri = Uri.parse(base).replace(queryParameters: {'UserId': userId});

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
          return Result.fail(
            Failure(
              code: 'parse',
              message: 'Invalid response format',
              statusCode: res.statusCode,
            ),
          );
        }

        if (parsed['isSuccess'] != true) {
          return Result.fail(
            Failure(
              code: 'validation',
              message:
                  parsed['message']?.toString() ??
                  'Failed to fetch user details',
              statusCode: res.statusCode,
            ),
          );
        }

        final result = parsed['result'];
        if (result is! Map<String, dynamic>) {
          return Result.fail(
            Failure(
              code: 'parse',
              message: 'Invalid result format',
              statusCode: res.statusCode,
            ),
          );
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
      return Result.fail(
        Failure(code: 'server', message: message, statusCode: res.statusCode),
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
      return Result.fail(
        Failure(code: 'validation', message: 'UserId is required'),
      );
    }
    if (serviceId <= 0 || documentId <= 0) {
      return Result.fail(
        Failure(code: 'validation', message: 'Invalid ServiceId/DocumentId'),
      );
    }
    if (bytes.isEmpty) {
      return Result.fail(Failure(code: 'validation', message: 'File is empty'));
    }

    // ----- MIME detection & normalization -----
    String? detectedMime = (mimeType?.trim().isNotEmpty == true)
        ? mimeType!.trim()
        : null;

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
    const allowed = {'image/jpeg', 'image/png', 'application/pdf'};

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
      return Result.fail(
        Failure(
          code: 'validation',
          message: 'Unsupported file type. Allowed: JPG, PNG, PDF',
        ),
      );
    }

    // ----- Size guard (tune to your API limit) -----
    const maxBytes =
        5 * 1024 * 1024; // 5 MB example – change if your API allows more
    if (bytes.length > maxBytes) {
      final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(2);
      return Result.fail(
        Failure(
          code: 'validation',
          message:
              'File too large ($mb MB). Max ${maxBytes ~/ (1024 * 1024)} MB.',
        ),
      );
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.certificateSubmitEndpoint}',
    );

    try {
      // log
      // ignore: avoid_print
      print(
        '[submitCertificate] POST MULTIPART => $uri  bytes=${bytes.length} '
        'file=$fileName mime=$detectedMime',
      );

      final req = http.MultipartRequest('POST', uri)
        ..headers[HttpHeaders.acceptHeader] = 'application/json'
        ..headers['X-Request-For'] = '::1'
        ..fields['UserId'] = userId
        ..fields['ServiceId'] = serviceId.toString()
        ..fields['DocumentId'] = documentId.toString();

      final uploadName = (fileName == null || fileName.isEmpty)
          ? 'upload.bin'
          : fileName;

      req.files.add(
        http.MultipartFile.fromBytes(
          'Document', // MUST match backend param name
          bytes,
          filename: uploadName,
          contentType: MediaType.parse(detectedMime), // <-- SET MIME TYPE
        ),
      );

      final streamed = await req.send().timeout(timeout);
      final res = await http.Response.fromStream(streamed);
      return _handleSubmitResponse(
        res,
      ); // your existing handler (already enhanced)
    } on SocketException {
      return Result.fail(
        Failure(code: 'network', message: 'No internet connection'),
      );
    } on TimeoutException {
      return Result.fail(
        Failure(code: 'timeout', message: 'Request timed out'),
      );
    } catch (e) {
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

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
        filename: (fileName == null || fileName.isEmpty)
            ? 'document'
            : fileName,
        // Deliberately omit contentType to avoid http_parser dep; server can infer
      );
      req.files.add(mp);

      final streamed = await req.send().timeout(timeout);
      final res = await http.Response.fromStream(streamed);

      return _handleSubmitResponse(res);
    } on SocketException {
      return Result.fail(
        Failure(code: 'network', message: 'No internet connection'),
      );
    } on TimeoutException {
      return Result.fail(
        Failure(code: 'timeout', message: 'Request timed out'),
      );
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
          return Result.fail(
            Failure(
              code: 'validation',
              message: msg,
              statusCode: res.statusCode,
            ),
          );
        }
        return Result.fail(
          Failure(
            code: 'parse',
            message: 'Invalid response format (expected object)',
            statusCode: res.statusCode,
          ),
        );
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

    return Result.fail(
      Failure(code: 'server', message: message, statusCode: res.statusCode),
    );
  }

  @override
  Future<Result<String>> createPaymentSession({
    required String userId,
    required num amount,
    String paymentMethod = 'stripe',
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.paymentSessionEndpoint}',
    );
    final body = {
      "userId": userId,
      "amount": amount,
      "paymentMethod": paymentMethod,
    };

    try {
      final res = await http
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(timeout);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);
        if (parsed is Map<String, dynamic>) {
          if (parsed['isSuccess'] == true) {
            final url = parsed['result']?['sessionUrl']?.toString();
            if (url != null && url.isNotEmpty) return Result.ok(url);
            return Result.fail(
              Failure(code: 'validation', message: 'No sessionUrl returned'),
            );
          }
          return Result.fail(
            Failure(
              code: 'validation',
              message:
                  parsed['message']?.toString() ?? 'Payment session failed',
              statusCode: res.statusCode,
            ),
          );
        }
        return Result.fail(
          Failure(code: 'parse', message: 'Invalid response format'),
        );
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
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<List<ServiceDocument>>> fetchServiceDocuments() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.docsRequiredEndpoint}',
    );
    try {
      print('>>> DOCS GET $uri');

      final res = await http.get(uri, headers: _headers()).timeout(timeout);

      print('<<< DOCS STATUS: ${res.statusCode}');
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);

        if (parsed is! List) {
          return Result.fail(
            Failure(
              code: 'parse',
              message: 'Invalid response format (expected array)',
              statusCode: res.statusCode,
            ),
          );
        }

        final list = parsed
            .map<ServiceDocument>(
              (e) => ServiceDocument.fromJson(e as Map<String, dynamic>),
            )
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
      return Result.fail(
        Failure(code: 'server', message: message, statusCode: res.statusCode),
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
            Failure(
              code: 'parse',
              message: 'Invalid response format (expected array)',
              statusCode: res.statusCode,
            ),
          );
        }

        final list = parsed
            .map<ServiceDto>(
              (e) => ServiceDto.fromJson(e as Map<String, dynamic>),
            )
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
      return Result.fail(
        Failure(code: 'server', message: message, statusCode: res.statusCode),
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
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<RegistrationResponse>> changePassword({
    required String password,
    required String userId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.changePasswordEndpoint}',
    );
    final body = {"password": password, "userId": userId};

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
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<RegistrationResponse>> verifyOtpThroughEmail({
    required String userId,
    required String email,
    required String code,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.verifyOtpEmailEndpoint}',
    );
    final body = {"userId": userId, "email": email, "code": code};

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
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<RegistrationResponse>> forgotPassword({
    required String email,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.forgotPasswordEndpoint}',
    );
    final body = {"identifier": email};

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
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<RegistrationResponse>> verifyOtpThroughPhone({
    required String userId,
    required String phone,
    required String code,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.verifyOtpPhoneEndpoint}',
    );
    final body = {"userId": userId, "phone": phone, "code": code};

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
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  Future<Result<RegistrationResponse>> _postRegistration(
    Map<String, dynamic> body,
  ) async {
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

      String message = 'Server error (${res.statusCode})';
      try {
        final err = jsonDecode(res.body);
        if (err is Map && err['message'] != null) {
          message = err['message'].toString();
        }
      } catch (_) {}
      return Result.fail(
        Failure(code: 'server', message: message, statusCode: res.statusCode),
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
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }
@override
 Future<Result<RegistrationResponse>> register(//Testing@123
      RegistrationRequest request) async {
    try {
      final body = jsonEncode(request.toJson());
      debugPrint('>>> SIGNUP BODY: $body');

      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrlLocation}/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      debugPrint('<<< SIGNUP STATUS: ${res.statusCode}');
      debugPrint('<<< SIGNUP BODY: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return Result.ok(RegistrationResponse.fromJson(json));
      }

      // parse error message if any
      try {
        if (res.body.isNotEmpty) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          final msg = json['message']?.toString() ?? 'Server error';
          return Result.fail(Failure(
            code: 'server',
            message: msg,
            statusCode: res.statusCode,
          ));
        }
      } catch (_) {}

      return Result.fail(Failure(
        code: 'server',
        message: 'Server error (${res.statusCode}) while signing up',
        statusCode: res.statusCode,
      ));
    } catch (e) {
      return Result.fail(Failure(code: 'network', message: e.toString()));
    }
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
      desiredService: desiredService,
      companyCategory: companyCategory,
      companySubCategory: companySubCategory,
      abn: abn,
    );
    return register(req);
  }
@override //Testing@123
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
      desiredService: desiredService,
      companyCategory: companyCategory,
      companySubCategory: companySubCategory,
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
    String? abn,
    int? taskerLevelId,
  }) {


    final req = RegistrationRequest.tasker(
      fullName: fullName,
      phoneNumber: phoneNumber,//Testing@123
      emailAddress: emailAddress,
      password: password,
      address: address,
      abn: abn,
      taskerLevelId: taskerLevelId ?? 0, // try 0 if 1 breaks
      desiredService: [],
      companyCategory: [],
      companySubCategory: [],
      representativeName: '',
      representativeNumber: '',
    );
    return register(req);
  }

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
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  // ---------------- Send OTP via Email ----------------
  @override
  Future<Result<RegistrationResponse>> sendOtpThroughEmail({
    required String userId,
    required String email,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.sendOTPThroughEmailEndpoint}',
    );
    final body = {"userId": userId, "email": email};

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
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<RegistrationResponse>> sendOtpThroughPhone({
    required String userId, // Testing@123
    required String phoneNumber,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.sendOTPThroughPhoneEndpoint}',
    );
    final body = {"userId": userId, "phoneNumber": phoneNumber};

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
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }
}
