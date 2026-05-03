import '../config/app_config.dart';
import '../data/mock_data.dart';
import '../models/legal_case.dart';
import 'api_client.dart';

class CasesService {
  CasesService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<LegalCase>> fetchCases({required String userType}) async {
    if (!AppConfig.hasBackend) {
      return userType == 'lawyer' ? MockData.lawyerCases : MockData.userCases;
    }

    try {
      final response = await _apiClient.get(AppConfig.casesEndpoint);
      if (response is List) {
        return response.whereType<Map<String, dynamic>>().map(LegalCase.fromJson).toList();
      }
      if (response is Map<String, dynamic> && response['results'] is List) {
        return (response['results'] as List)
            .whereType<Map<String, dynamic>>()
            .map(LegalCase.fromJson)
            .toList();
      }
    } catch (_) {}

    return userType == 'lawyer' ? MockData.lawyerCases : MockData.userCases;
  }
}
