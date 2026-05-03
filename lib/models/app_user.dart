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
  final String bio; // أضفنا هذا الحقل

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
    this.bio = '', // قيمة افتراضية فارغة
  });

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

  // دالة مفيدة جداً لتحديث بيانات المستخدم دون إعادة إنشاء الكائن كاملاً
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
