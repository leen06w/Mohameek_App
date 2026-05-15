/// يمثل مستند "طلب الاستشارة" الذي يربط الطالب بالمحامي.
/// يدير هذا الموديل كافة تفاصيل الطلب وحالته الحالية (قيد الانتظار، مقبول، مرفوض، تفاوض).
class RequestItem {
  final String id;
  final String lawyerName;
  final String lawyerSpecialty;
  final String consultationType;
  final String preferredDate;
  final String preferredTime;
  final String caseType;
  final String description;
  final String status;
  final String submittedAt;
  final String? price;
  final String? negotiationNote; // ملاحظات المحامي عند الحاجة للتفاوض
  final String? rejectionReason; // سبب الرفض في حال عدم قبول الطلب
  final String? decisionAt; // وقت صدور قرار المحامي

  const RequestItem({
    required this.id,
    required this.lawyerName,
    required this.lawyerSpecialty,
    required this.consultationType,
    required this.preferredDate,
    required this.preferredTime,
    required this.caseType,
    required this.description,
    required this.status,
    required this.submittedAt,
    this.price,
    this.negotiationNote,
    this.rejectionReason,
    this.decisionAt,
  });

  /// تستخدم بشكل أساسي في لوحة تحكم المحامي لتحديث حالة الطلب (Status) فقط دون المساس ببيانات الطالب الأساسية.
  RequestItem copyWith({
    String? id,
    String? lawyerName,
    String? lawyerSpecialty,
    String? consultationType,
    String? preferredDate,
    String? preferredTime,
    String? caseType,
    String? description,
    String? status,
    String? submittedAt,
    String? price,
    String? negotiationNote,
    String? rejectionReason,
    String? decisionAt,
  }) {
    return RequestItem(
      id: id ?? this.id,
      lawyerName: lawyerName ?? this.lawyerName,
      lawyerSpecialty: lawyerSpecialty ?? this.lawyerSpecialty,
      consultationType: consultationType ?? this.consultationType,
      preferredDate: preferredDate ?? this.preferredDate,
      preferredTime: preferredTime ?? this.preferredTime,
      caseType: caseType ?? this.caseType,
      description: description ?? this.description,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      price: price ?? this.price,
      negotiationNote: negotiationNote ?? this.negotiationNote,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      decisionAt: decisionAt ?? this.decisionAt,
    );
  }

  /// دالة تحويل البيانات من صيغة JSON إلى كائن برمي.
  /// تدعم دمج الأسماء المختلفة للحقول (مثل lawyer_name و lawyerName) لضمان التوافق مع إصدارات قاعدة البيانات المختلفة.
  factory RequestItem.fromJson(Map<String, dynamic> json) {
    return RequestItem(
      id: (json['id'] ?? '').toString(),
      lawyerName:
          (json['lawyer_name'] ?? json['lawyerName'] ?? 'محامٍ').toString(),
      lawyerSpecialty:
          (json['lawyer_specialty'] ?? json['lawyerSpecialty'] ?? '')
              .toString(),
      consultationType:
          (json['consultation_type'] ?? json['consultationType'] ?? '')
              .toString(),
      preferredDate:
          (json['preferred_date'] ?? json['preferredDate'] ?? '').toString(),
      preferredTime:
          (json['preferred_time'] ?? json['preferredTime'] ?? '').toString(),
      caseType: (json['case_type'] ?? json['caseType'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      submittedAt:
          (json['submitted_at'] ?? json['submittedAt'] ?? '').toString(),
      price: json['price']?.toString(),
      negotiationNote:
          (json['negotiation_note'] ?? json['negotiationNote'])?.toString(),
      rejectionReason:
          (json['rejection_reason'] ?? json['rejectionReason'])?.toString(),
      decisionAt: (json['decision_at'] ?? json['decisionAt'])?.toString(),
    );
  }

  /// تحويل الطلب إلى صيغة JSON لحفظه في الفايربيس أو الذاكرة المحلية [SharedPreferences].
  Map<String, dynamic> toJson() => {
        'id': id,
        'lawyer_name': lawyerName,
        'lawyer_specialty': lawyerSpecialty,
        'consultation_type': consultationType,
        'preferred_date': preferredDate,
        'preferred_time': preferredTime,
        'case_type': caseType,
        'description': description,
        'status': status,
        'submitted_at': submittedAt,
        'price': price,
        'negotiation_note': negotiationNote,
        'rejection_reason': rejectionReason,
        'decision_at': decisionAt,
      };
}
