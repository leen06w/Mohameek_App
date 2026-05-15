/// كلاس البيانات الأساسي الذي يمثل "المستخدم" داخل نظام محاميك.
/// يتميز هذا الموديل بالمرونة؛ حيث يجمع الحقول المشتركة بين الطلاب والمحامين،
/// ويدير عمليات التحويل من وإلى صيغة Map للتعامل مع قاعدة بيانات Cloud Firestore.
class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String city;
  final String address;
  final String role;
  final String status;
  final String specialty;
  final String gender;
  final String licenseDate;
  final String barAssociation;
  final String practiceAreas;
  final String zipCode;
  final String bio;

  const AppUser({
    this.id = '',
    this.name = '',
    this.email = '',
    this.phone = '',
    this.city = '',
    this.address = '',
    this.role = 'student',
    this.status = 'نشط',
    this.specialty = '',
    this.gender = '',
    this.licenseDate = '',
    this.barAssociation = '',
    this.practiceAreas = '',
    this.zipCode = '',
    this.bio = '',
  });

  /// دالة (Factory) تقوم بتحويل البيانات المسترجعة من Firestore إلى كائن برمي [AppUser].
  /// تضمن الدالة سلامة البيانات عبر استخدام [toString] لمنع انهيار التطبيق عند وجود قيم فارغة.
  factory AppUser.fromMap(Map<String, dynamic>? map, String documentId) {
    final data = map ?? {};
    return AppUser(
      id: documentId,
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      role: (data['role'] ?? 'student').toString(),
      status: (data['status'] ?? 'نشط').toString(),
      specialty: (data['specialty'] ?? '').toString(),
      gender: (data['gender'] ?? '').toString(),
      licenseDate: (data['licenseDate'] ?? '').toString(),
      barAssociation: (data['barAssociation'] ?? '').toString(),
      practiceAreas: (data['practiceAreas'] ?? '').toString(),
      zipCode: (data['zipCode'] ?? '').toString(),
      bio: (data['bio'] ?? '').toString(),
    );
  }

  /// تقوم بتحويل كائن [AppUser] إلى خريطة بيانات (Map) لرفعها وتخزينها في مستندات Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'address': address,
      'role': role,
      'status': status,
      'specialty': specialty,
      'gender': gender,
      'licenseDate': licenseDate,
      'barAssociation': barAssociation,
      'practiceAreas': practiceAreas,
      'zipCode': zipCode,
      'bio': bio,
    };
  }

  /// دالة برمجية احترافية تسمح بتحديث حقول معينة في بيانات المستخدم مع الحفاظ على بقية البيانات
  /// دون الحاجة لإعادة إنشاء الكائن من الصفر، مما يحسن من كفاءة الذاكرة.
  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? city,
    String? address,
    String? role,
    String? status,
    String? specialty,
    String? gender,
    String? licenseDate,
    String? barAssociation,
    String? practiceAreas,
    String? zipCode,
    String? bio,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      address: address ?? this.address,
      role: role ?? this.role,
      status: status ?? this.status,
      specialty: specialty ?? this.specialty,
      gender: gender ?? this.gender,
      licenseDate: licenseDate ?? this.licenseDate,
      barAssociation: barAssociation ?? this.barAssociation,
      practiceAreas: practiceAreas ?? this.practiceAreas,
      zipCode: zipCode ?? this.zipCode,
      bio: bio ?? this.bio,
    );
  }
}
