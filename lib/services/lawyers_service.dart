import '../config/app_config.dart';
import '../data/mock_data.dart';
import '../models/lawyer.dart';
import 'api_client.dart';

class LawyersService {
  LawyersService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Lawyer>> fetchLawyers() async {
    if (!AppConfig.hasBackend) return MockData.lawyers;

    try {
      final response = await _apiClient.get(AppConfig.lawyersEndpoint);
      if (response is List) {
        return response
            .whereType<Map<String, dynamic>>()
            .map(Lawyer.fromJson)
            .toList();
      }
      if (response is Map<String, dynamic> && response['results'] is List) {
        return (response['results'] as List)
            .whereType<Map<String, dynamic>>()
            .map(Lawyer.fromJson)
            .toList();
      }
      return MockData.lawyers;
    } catch (_) {
      return MockData.lawyers;
    }
  }

  Future<Lawyer?> fetchLawyerById(String id) async {
    if (!AppConfig.hasBackend) {
      for (final item in MockData.lawyers) {
      if (item.id == id) return item;
    }
    return null;
    }
    try {
      final response = await _apiClient.get(AppConfig.lawyerProfileEndpoint, resourceId: id);
      if (response is Map<String, dynamic>) {
        return Lawyer.fromJson(response);
      }
    } catch (_) {}
    for (final item in MockData.lawyers) {
      if (item.id == id) return item;
    }
    return null;
  }
}
