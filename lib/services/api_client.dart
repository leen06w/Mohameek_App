import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'session_service.dart';

/// كلاس مخصص لتنظيم طلبات الـ HTTP API.
/// يقوم بتوحيد طريقة إرسال واستقبال البيانات وتوليد الـ Headers اللازمة (مثل Token المصادقة).
class ApiClient {
  ApiClient({http.Client? client, SessionService? sessionService})
      : _client = client ?? http.Client(),
        _sessionService = sessionService ?? SessionService();

  final http.Client _client;
  final SessionService _sessionService;

  /// توليد الـ Headers الافتراضية وإضافة توكن الجلسة إذا كان الطلب يتطلب صلاحيات.
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

  /// تنفيذ طلب من نوع GET لجلب البيانات.
  Future<dynamic> get(String path,
      {bool auth = true, String? resourceId}) async {
    final response = await _client.get(
      Uri.parse(AppConfig.resolve(path, resourceId: resourceId)),
      headers: await _headers(auth: auth),
    );
    return _decode(response);
  }

  /// تنفيذ طلب من نوع POST لإرسال بيانات جديدة.
  Future<dynamic> post(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final response = await _client.post(
      Uri.parse(AppConfig.resolve(path)),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  /// معالجة استجابة السيرفر وتحويلها من JSON إلى كائنات برمجية، مع إدارة أخطاء الاتصال.
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
// التحقق من كود الحالة (Status Code): إذا كان خارج نطاق الـ 200 يعتبر خطأ
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
