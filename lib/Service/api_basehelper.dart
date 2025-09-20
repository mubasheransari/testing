import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_exception.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';



class ApiBaseHelper {
  ApiBaseHelper({
    http.Client? client,
    this.baseUrl,
    this.defaultHeaders,
    this.requestTimeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String? baseUrl;
  final Map<String, String>? defaultHeaders;
  final Duration requestTimeout;

  Future<dynamic> get({
    required String path,
    String? token,
    Map<String, dynamic>? query,
    String? overrideBaseUrl,
  }) {
    return _send(
      method: 'GET',
      path: path,
      token: token,
      query: query,
      overrideBaseUrl: overrideBaseUrl,
    );
  }

  Future<dynamic> post({
    required String path,
    Map<String, dynamic>? body,
    String? token,
    Map<String, dynamic>? query,
    String? overrideBaseUrl,
  }) {
    return _send(
      method: 'POST',
      path: path,
      token: token,
      query: query,
      body: body,
      overrideBaseUrl: overrideBaseUrl,
    );
  }

  Future<dynamic> delete({
    required String path,
    Map<String, dynamic>? body,
    String? token,
    Map<String, dynamic>? query,
    String? overrideBaseUrl,
  }) {
    return _send(
      method: 'DELETE',
      path: path,
      token: token,
      query: query,
      body: body,
      overrideBaseUrl: overrideBaseUrl,
    );
  }

  Future<dynamic> _send({
    required String method,
    required String path,
    String? token,
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    String? overrideBaseUrl,
  }) async {
    final resolvedBase = overrideBaseUrl ?? baseUrl;
    if (resolvedBase == null) {
      throw ArgumentError('Base URL is not provided.');
    }

    final base = Uri.parse(resolvedBase.endsWith('/') ? resolvedBase : '$resolvedBase/');
    final uri = base.resolve(path.startsWith('/') ? path.substring(1) : path).replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (defaultHeaders != null) ...defaultHeaders!,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    if (kDebugMode) {
      debugPrint('HTTP $method $uri');
      if (query != null) debugPrint('↳ query: $query');
      if (body != null) debugPrint('↳ body: ${jsonEncode(body)}');
    }

    try {
      http.Response res;
      switch (method) {
        case 'GET':
          res = await _client.get(uri, headers: headers).timeout(requestTimeout);
          break;
        case 'POST':
          res = await _client
              .post(uri, headers: headers, body: body == null ? null : jsonEncode(body))
              .timeout(requestTimeout);
          break;
        case 'DELETE':
          if (body == null) {
            res = await _client.delete(uri, headers: headers).timeout(requestTimeout);
          } else {
            final req = http.Request('DELETE', uri)..headers.addAll(headers)..body = jsonEncode(body);
            final streamed = await _client.send(req).timeout(requestTimeout);
            res = await http.Response.fromStream(streamed);
          }
          break;
        default:
          throw ArgumentError('Unsupported method: $method');
      }

      if (kDebugMode) {
        debugPrint('↳ status: ${res.statusCode}');
        debugPrint('↳ body: ${res.body}');
      }

      return _mapResponse(res);
    } on SocketException {
      _showToast('No internet connection', Colors.redAccent);
      throw FetchDataException('No Internet connection');
    } on HttpException catch (e) {
      throw FetchDataException('HTTP error: ${e.message}');
    } on FormatException {
      throw FetchDataException('Bad response format');
    } on TimeoutException {
      throw FetchDataException('Request timeout');
    }
  }

  dynamic _mapResponse(http.Response response) {
    final code = response.statusCode;
    final bodyText = response.body;
    final contentType = response.headers['content-type'] ?? '';
    final isJson = contentType.contains('application/json');

    dynamic parsed;
    if (bodyText.isEmpty) {
      parsed = null;
    } else if (isJson) {
      parsed = jsonDecode(bodyText);
    } else {
      parsed = bodyText;
    }

    if (code >= 200 && code < 300) {
      return parsed;
    }

    switch (code) {
      case 400:
        throw BadRequestException(bodyText);
      case 401:
      case 403:
        throw UnauthorisedException(bodyText);
      case 500:
        throw InternalServerException('Internal server error');
      default:
        throw FetchDataException('Error communicating with server: $code');
    }
  }

  void _showToast(String msg, Color bg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: bg,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }
}
