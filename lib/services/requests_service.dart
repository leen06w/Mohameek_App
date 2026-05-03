import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_data.dart';
import '../models/request_item.dart';

class RequestsService {
  static const String _requestsKey = 'user_requests_store';

  Future<List<RequestItem>> fetchRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_requestsKey);

    if (raw == null || raw.trim().isEmpty) {
      final seeded = List<RequestItem>.from(MockData.requests);
      await _saveAll(seeded);
      return seeded;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(RequestItem.fromJson)
            .toList();
      }
    } catch (_) {}

    final fallback = List<RequestItem>.from(MockData.requests);
    await _saveAll(fallback);
    return fallback;
  }

  Future<void> resetToMockData() async {
    await _saveAll(List<RequestItem>.from(MockData.requests));
  }

  Future<void> addRequest(RequestItem request) async {
    final items = await fetchRequests();
    final exists = items.any((item) => item.id == request.id);
    if (exists) return;

    final updated = [...items, request];
    await _saveAll(updated);
  }

  Future<RequestItem> createRequest(Map<String, dynamic> data) async {
    final request = RequestItem(
      id: (data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
          .toString(),
      lawyerName: (data['lawyer_name'] ??
              data['lawyerName'] ??
              data['lawyer_name_ar'] ??
              'محامٍ')
          .toString(),
      lawyerSpecialty:
          (data['lawyer_specialty'] ?? data['lawyerSpecialty'] ?? '')
              .toString(),
      consultationType:
          (data['consultation_type'] ?? data['consultationType'] ?? '')
              .toString(),
      preferredDate:
          (data['preferred_date'] ?? data['preferredDate'] ?? '').toString(),
      preferredTime:
          (data['preferred_time'] ?? data['preferredTime'] ?? '').toString(),
      caseType: (data['case_type'] ?? data['caseType'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      submittedAt: (data['submitted_at'] ??
              data['submittedAt'] ??
              DateTime.now().toString())
          .toString(),
      price: data['price']?.toString(),
      negotiationNote:
          (data['negotiation_note'] ?? data['negotiationNote'])?.toString(),
      rejectionReason:
          (data['rejection_reason'] ?? data['rejectionReason'])?.toString(),
      decisionAt: (data['decision_at'] ?? data['decisionAt'])?.toString(),
    );

    final items = await fetchRequests();
    final updated = [...items, request];
    await _saveAll(updated);

    return request;
  }

  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
    String? negotiationNote,
    String? rejectionReason,
    String? decisionAt,
    String? price,
  }) async {
    final items = await fetchRequests();

    final updated = items.map((item) {
      if (item.id != requestId) return item;

      return item.copyWith(
        status: status,
        negotiationNote: negotiationNote ?? item.negotiationNote,
        rejectionReason: rejectionReason ?? item.rejectionReason,
        decisionAt: decisionAt ?? item.decisionAt,
        price: price ?? item.price,
      );
    }).toList();

    await _saveAll(updated);
  }

  Future<void> _saveAll(List<RequestItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_requestsKey, encoded);
  }
}