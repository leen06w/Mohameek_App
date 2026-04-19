import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'session_service.dart';

class ApiClient {
  ApiClient({http.Client? client, SessionService? sessionService})
      : _client = client ?? http.Client(),
        _sessionService = sessionService ?? SessionService();

  final http.Client _client;
  final SessionService _sessionService;

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{'content-type': 'application/json'};
    if (auth) {
      final token = await _sessionService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String path, {bool auth = true, String? resourceId}) async {
    final response = await _client.get(
      Uri.parse(AppConfig.resolve(path, resourceId: resourceId)),
      headers: await _headers(auth: auth),
    );
    return _decode(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final response = await _client.post(
      Uri.parse(AppConfig.resolve(path)),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final raw = utf8.decode(response.bodyBytes);
    dynamic decoded;
    if (raw.isNotEmpty) {
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        decoded = raw;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded is Map<String, dynamic>
            ? (decoded['detail'] ?? decoded['message'] ?? raw).toString()
            : raw,
      );
    }
    return decoded;
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
