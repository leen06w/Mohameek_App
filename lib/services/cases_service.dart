import '../config/app_config.dart';
import '../data/mock_data.dart';
import '../models/legal_case.dart';
import 'api_client.dart';

/// خدمة مخصصة لإدارة وجلب القضايا القانونية (Legal Cases).
/// تدعم الخدمة جلب البيانات من السيرفر الفعلي أو العودة للبيانات التجريبية (Mock Data) للتهيئة.
class CasesService {
  CasesService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// جلب قائمة القضايا بناءً على نوع المستخدم (محامي أو مستخدم).
  Future<List<LegalCase>> fetchCases({required String userType}) async {
    // إذا كان التطبيق مضبوطاً على عدم استخدام سيرفر حالياً، نستخدم البيانات التجريبية مباشرة
    if (!AppConfig.hasBackend) {
      return userType == 'lawyer' ? MockData.lawyerCases : MockData.userCases;
    }

    try {
      final response = await _apiClient.get(AppConfig.casesEndpoint);

      // تحويل استجابة الـ JSON إلى قائمة من كائنات LegalCase
      if (response is List) {
        return response
            .whereType<Map<String, dynamic>>()
            .map(LegalCase.fromJson)
            .toList();
      }
      if (response is Map<String, dynamic> && response['results'] is List) {
        return (response['results'] as List)
            .whereType<Map<String, dynamic>>()
            .map(LegalCase.fromJson)
            .toList();
      }
    } catch (_) {
      // في حال فشل الاتصال، نعود للبيانات التجريبية لضمان عدم توقف واجهة المستخدم
    }

    return userType == 'lawyer' ? MockData.lawyerCases : MockData.userCases;
  }
}
