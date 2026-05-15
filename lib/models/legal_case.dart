/// يمثل تفاصيل القضية القانونية "النشطة" أو "المكتملة".
/// يتتبع نسبة التقدم [progress] وتاريخ آخر تحديث لعرضها في شريط التقدم بـ لوحة التحكم.
class LegalCase {
  final String id;
  final String title;
  final String client;
  final String type;
  final String status;
  final double progress; // نسبة الإنجاز في القضية (0-100)
  final String updatedAt;

  const LegalCase({
    required this.id,
    required this.title,
    required this.client,
    required this.type,
    required this.status,
    required this.progress,
    required this.updatedAt,
  });

  factory LegalCase.fromJson(Map<String, dynamic> json) {
    final rawProgress = json['progress'];
    final progress = rawProgress is num
        ? rawProgress.toDouble()
        : double.tryParse(rawProgress?.toString() ?? '') ?? 0;

    return LegalCase(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      client: (json['client'] ?? json['client_name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      progress: progress,
      updatedAt: (json['updated_at'] ?? json['updatedAt'] ?? '').toString(),
    );
  }
}
