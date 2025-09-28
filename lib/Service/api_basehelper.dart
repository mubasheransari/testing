// api_base_helper.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import '../Models/auth_model.dart';
import 'api_exception.dart';

// lib/Service/api_basehelper.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

/// Configure once and reuse.
// lib/Service/api_basehelper.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

/// Configure once and reuse.
/// - baseDomain: host:port without scheme (e.g., "192.3.3.187:83")
/// - apiPrefix: prefix added when you pass a path that does NOT already start with "/api/"
class ApiConstants {
  static const String baseDomain = '192.3.3.187:83';
  static const String apiPrefix = '/api';
}

/// Strongly-typed exceptions (optional, but handy)
class ApiException implements Exception {
  final String message;
  final String prefix;
  final int? statusCode;
  ApiException(this.message, {this.prefix = '', this.statusCode});
  @override
  String toString() => '$prefix$message';
}

class FetchDataException extends ApiException {
  FetchDataException(String message, {int? statusCode})
      : super(message, prefix: 'Error During Communication: ', statusCode: statusCode);
}

class BadRequestException extends ApiException {
  BadRequestException(String message, {int? statusCode})
      : super(message, prefix: 'Invalid Request: ', statusCode: statusCode);
}

class UnauthorisedException extends ApiException {
  UnauthorisedException(String message, {int? statusCode})
      : super(message, prefix: 'Unauthorised: ', statusCode: statusCode);
}

class InternalServerException extends ApiException {
  InternalServerException(String message, {int? statusCode})
      : super(message, prefix: 'Internal Server Error: ', statusCode: statusCode);
}

class ApiBaseHelper {
  bool _wasConnected = true;

  // ---------------------------
  // PUBLIC RELATIVE-URL METHODS
  // ---------------------------

  /// POST using host + relative `path`.
  /// - `baseUrl`: host:port (no scheme). If null, uses ApiConstants.baseDomain.
  /// - `path`: "/auth/..." or "/api/auth/..."; "/api" will be auto-prefixed if missing.
  Future<http.Response> post({
    String? baseUrl,
    required String path,
    Map<String, dynamic>? body,
    String? token,
    Map<String, dynamic>? queryParam,
    Map<String, String>? extraHeaders,
  }) async {
    await _guardConnectivity();

    final effectivePath = _effectivePath(path);
    final host = baseUrl ?? ApiConstants.baseDomain;
    final uri = Uri.http(host, effectivePath, queryParam);

    _debugLog('POST URI -> $uri');
    _debugLog('POST BODY -> ${json.encode(body ?? const {})}');

    return http.post(
      uri,
      headers: _headers(token: token, extra: extraHeaders),
      body: json.encode(body ?? const {}),
    );
  }

  /// GET using host + relative `path`.
  Future<http.Response> get({
    String? baseUrl,
    required String path,
    String? token,
    Map<String, dynamic>? queryParam,
    Map<String, String>? extraHeaders,
  }) async {
    await _guardConnectivity();

    final effectivePath = _effectivePath(path);
    final host = baseUrl ?? ApiConstants.baseDomain;
    final uri = Uri.http(host, effectivePath, queryParam);

    _debugLog('GET URI -> $uri');

    return http.get(
      uri,
      headers: _headers(token: token, extra: extraHeaders),
    );
  }

  /// DELETE using host + relative `path`.
  Future<http.Response> delete({
    String? baseUrl,
    required String path,
    Map<String, dynamic>? body,
    String? token,
    Map<String, dynamic>? queryParam,
    Map<String, String>? extraHeaders,
  }) async {
    await _guardConnectivity();

    final effectivePath = _effectivePath(path);
    final host = baseUrl ?? ApiConstants.baseDomain;
    final uri = Uri.http(host, effectivePath, queryParam);

    _debugLog('DELETE URI -> $uri');
    if (body != null) _debugLog('DELETE BODY -> ${json.encode(body)}');

    final request = http.Request('DELETE', uri)
      ..headers.addAll(_headers(token: token, extra: extraHeaders))
      ..body = json.encode(body ?? const {});
    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  // ---------------------------
  // PUBLIC ABSOLUTE-URL METHODS
  // ---------------------------

  /// Use when you already have the FULL URL (scheme + host + path).
  Future<http.Response> postAbsolute({
    required String url,
    Map<String, dynamic>? body,
    String? token,
    Map<String, String>? extraHeaders,
  }) async {
    await _guardConnectivity();

    final uri = Uri.parse(url);
    _debugLog('POST ABS -> $uri');
    _debugLog('POST BODY -> ${json.encode(body ?? const {})}');

    return http.post(
      uri,
      headers: _headers(token: token, extra: extraHeaders),
      body: json.encode(body ?? const {}),
    );
  }

  Future<http.Response> getAbsolute({
    required String url,
    String? token,
    Map<String, String>? extraHeaders,
  }) async {
    await _guardConnectivity();

    final uri = Uri.parse(url);
    _debugLog('GET ABS -> $uri');

    return http.get(
      uri,
      headers: _headers(token: token, extra: extraHeaders),
    );
  }

  Future<http.Response> deleteAbsolute({
    required String url,
    Map<String, dynamic>? body,
    String? token,
    Map<String, String>? extraHeaders,
  }) async {
    await _guardConnectivity();

    final uri = Uri.parse(url);
    _debugLog('DELETE ABS -> $uri');
    if (body != null) _debugLog('DELETE BODY -> ${json.encode(body)}');

    final request = http.Request('DELETE', uri)
      ..headers.addAll(_headers(token: token, extra: extraHeaders))
      ..body = json.encode(body ?? const {});
    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  // ---------------------------
  // RESPONSE NORMALIZER (optional)
  // ---------------------------

  /// Turn a raw http.Response into a decoded JSON or throw typed errors.
  /// Use if you want helper to centralize error handling.
  dynamic normalize(http.Response response) {
    final sc = response.statusCode;

    if (sc >= 200 && sc < 300) {
      if (response.body.isEmpty) return null;
      try {
        return json.decode(response.body);
      } catch (_) {
        throw FetchDataException('Invalid response format', statusCode: sc);
      }
    }

    // Non-2xx → try to extract message
    String message = 'Server error';
    try {
      final obj = json.decode(response.body);
      if (obj is Map && obj['message'] != null) {
        message = obj['message'].toString();
      }
    } catch (_) {}

    if (sc == 400) throw BadRequestException(message, statusCode: sc);
    if (sc == 401 || sc == 403) throw UnauthorisedException(message, statusCode: sc);
    if (sc >= 500) throw InternalServerException(message, statusCode: sc);
    throw FetchDataException('HTTP $sc: $message', statusCode: sc);
  }

  // ---------------------------
  // INTERNAL HELPERS
  // ---------------------------

  /// Adds `/api` only when needed.
  String _effectivePath(String path) {
    if (path.startsWith('/api/')) return path;
    final suffix = path.startsWith('/') ? path : '/$path';
    return '${ApiConstants.apiPrefix}$suffix';
  }

  Map<String, String> _headers({String? token, Map<String, String>? extra}) {
    // Add/keep any custom headers your server expects (e.g., X-Request-For)
    final base = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Request-For': '::1',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    if (extra != null && extra.isNotEmpty) base.addAll(extra);
    return base;
  }

  Future<void> _guardConnectivity() async {
    final online = await _hasInternet();
    if (!online) {
      if (_wasConnected) {
        Fluttertoast.showToast(
          msg: "No internet connection available",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
        );
      }
      _wasConnected = false;
      throw const SocketException('No Internet connection');
    }

    if (!_wasConnected) {
      Fluttertoast.showToast(
        msg: "Internet connection restored",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    }

    _wasConnected = true;
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _debugLog(Object? msg) {
    // ignore: avoid_print
    print(msg);
  }
}



// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'api_exception.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:flutter/material.dart';



// class ApiBaseHelper {
//   ApiBaseHelper({
//     http.Client? client,
//     this.baseUrl,
//     this.defaultHeaders,
//     this.requestTimeout = const Duration(seconds: 20),
//   }) : _client = client ?? http.Client();

//   final http.Client _client;
//   final String? baseUrl;
//   final Map<String, String>? defaultHeaders;
//   final Duration requestTimeout;

//   Future<dynamic> get({
//     required String path,
//     String? token,
//     Map<String, dynamic>? query,
//     String? overrideBaseUrl,
//   }) {
//     return _send(
//       method: 'GET',
//       path: path,
//       token: token,
//       query: query,
//       overrideBaseUrl: overrideBaseUrl,
//     );
//   }

//   Future<dynamic> post({
//     required String path,
//     Map<String, dynamic>? body,
//     String? token,
//     Map<String, dynamic>? query,
//     String? overrideBaseUrl,
//   }) {
//     return _send(
//       method: 'POST',
//       path: path,
//       token: token,
//       query: query,
//       body: body,
//       overrideBaseUrl: overrideBaseUrl,
//     );
//   }

//   Future<dynamic> delete({
//     required String path,
//     Map<String, dynamic>? body,
//     String? token,
//     Map<String, dynamic>? query,
//     String? overrideBaseUrl,
//   }) {
//     return _send(
//       method: 'DELETE',
//       path: path,
//       token: token,
//       query: query,
//       body: body,
//       overrideBaseUrl: overrideBaseUrl,
//     );
//   }

//   Future<dynamic> _send({
//     required String method,
//     required String path,
//     String? token,
//     Map<String, dynamic>? query,
//     Map<String, dynamic>? body,
//     String? overrideBaseUrl,
//   }) async {
//     final resolvedBase = overrideBaseUrl ?? baseUrl;
//     if (resolvedBase == null) {
//       throw ArgumentError('Base URL is not provided.');
//     }

//     final base = Uri.parse(resolvedBase.endsWith('/') ? resolvedBase : '$resolvedBase/');
//     final uri = base.resolve(path.startsWith('/') ? path.substring(1) : path).replace(
//       queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
//     );

//     final headers = <String, String>{
//       'Content-Type': 'application/json',
//       if (defaultHeaders != null) ...defaultHeaders!,
//       if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
//     };

//     if (kDebugMode) {
//       debugPrint('HTTP $method $uri');
//       if (query != null) debugPrint('↳ query: $query');
//       if (body != null) debugPrint('↳ body: ${jsonEncode(body)}');
//     }

//     try {
//       http.Response res;
//       switch (method) {
//         case 'GET':
//           res = await _client.get(uri, headers: headers).timeout(requestTimeout);
//           break;
//         case 'POST':
//           res = await _client
//               .post(uri, headers: headers, body: body == null ? null : jsonEncode(body))
//               .timeout(requestTimeout);
//           break;
//         case 'DELETE':
//           if (body == null) {
//             res = await _client.delete(uri, headers: headers).timeout(requestTimeout);
//           } else {
//             final req = http.Request('DELETE', uri)..headers.addAll(headers)..body = jsonEncode(body);
//             final streamed = await _client.send(req).timeout(requestTimeout);
//             res = await http.Response.fromStream(streamed);
//           }
//           break;
//         default:
//           throw ArgumentError('Unsupported method: $method');
//       }

//       if (kDebugMode) {
//         debugPrint('↳ status: ${res.statusCode}');
//         debugPrint('↳ body: ${res.body}');
//       }

//       return _mapResponse(res);
//     } on SocketException {
//       _showToast('No internet connection', Colors.redAccent);
//       throw FetchDataException('No Internet connection');
//     } on HttpException catch (e) {
//       throw FetchDataException('HTTP error: ${e.message}');
//     } on FormatException {
//       throw FetchDataException('Bad response format');
//     } on TimeoutException {
//       throw FetchDataException('Request timeout');
//     }
//   }

//   dynamic _mapResponse(http.Response response) {
//     final code = response.statusCode;
//     final bodyText = response.body;
//     final contentType = response.headers['content-type'] ?? '';
//     final isJson = contentType.contains('application/json');

//     dynamic parsed;
//     if (bodyText.isEmpty) {
//       parsed = null;
//     } else if (isJson) {
//       parsed = jsonDecode(bodyText);
//     } else {
//       parsed = bodyText;
//     }

//     if (code >= 200 && code < 300) {
//       return parsed;
//     }

//     switch (code) {
//       case 400:
//         throw BadRequestException(bodyText);
//       case 401:
//       case 403:
//         throw UnauthorisedException(bodyText);
//       case 500:
//         throw InternalServerException('Internal server error');
//       default:
//         throw FetchDataException('Error communicating with server: $code');
//     }
//   }

//   void _showToast(String msg, Color bg) {
//     Fluttertoast.showToast(
//       msg: msg,
//       toastLength: Toast.LENGTH_SHORT,
//       gravity: ToastGravity.BOTTOM,
//       backgroundColor: bg,
//       textColor: Colors.white,
//       fontSize: 14.0,
//     );
//   }
// }
