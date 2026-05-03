import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get appMode {
    final value = (dotenv.env['APP_MODE'] ?? 'demo').trim().toLowerCase();
    return value.isEmpty ? 'demo' : value;
  }

  static bool get isDemoMode => appMode == 'demo';

  static String get apiBaseUrl => _normalize(dotenv.env['API_BASE_URL'] ?? '');

  static String get authLoginEndpoint =>
      dotenv.env['AUTH_LOGIN_ENDPOINT'] ?? '/auth/login/';
  static String get lawyersEndpoint =>
      dotenv.env['LAWYERS_ENDPOINT'] ?? '/lawyers/';
  static String get lawyerProfileEndpoint =>
      dotenv.env['LAWYER_PROFILE_ENDPOINT'] ?? '/lawyers/{id}/';
  static String get bookingsEndpoint =>
      dotenv.env['BOOKINGS_ENDPOINT'] ?? '/bookings/';
  static String get requestsEndpoint =>
      dotenv.env['REQUESTS_ENDPOINT'] ?? '/requests/';
  static String get casesEndpoint =>
      dotenv.env['CASES_ENDPOINT'] ?? '/cases/';
  static String get aiChatEndpoint =>
      dotenv.env['AI_CHAT_ENDPOINT'] ?? '/ai/legal-chat/';

  static String get geminiApiKey => (dotenv.env['GEMINI_API_KEY'] ?? '').trim();
  static String get geminiModel =>
      (dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash').trim();
  static String get mapsApiKey =>
      (dotenv.env['GOOGLE_MAPS_API_KEY='] ?? '').trim();

  static bool get hasBackend => !isDemoMode && apiBaseUrl.isNotEmpty;
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
  static bool get hasMapsKey => mapsApiKey.isNotEmpty;

  static String resolve(String path, {String? resourceId}) {
    final cleaned = path.startsWith('/') ? path : '/$path';
    final withId =
        resourceId == null ? cleaned : cleaned.replaceAll('{id}', resourceId);
    return '$apiBaseUrl$withId';
  }

  static String _normalize(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) return '';
    if (trimmed.contains('your-backend-domain.com')) return '';

    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }

    return trimmed;
  }
}