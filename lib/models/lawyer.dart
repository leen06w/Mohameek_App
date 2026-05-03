class Lawyer {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final int reviews;
  final int cases;
  final String city;
  final String price;
  final String experience;
  final double lat;
  final double lng;
  final String email;
  final String phone;
  final String officeName;
  final String officeAddress;
  final String workHours;
  final String bio;
  final String licenseNumber;
  final String casesCount;

  const Lawyer({
    required this.id,
    required this.casesCount,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.reviews,
    required this.cases,
    required this.city,
    required this.price,
    required this.experience,
    required this.lat,
    required this.lng,
    required this.email,
    required this.phone,
    required this.officeName,
    required this.officeAddress,
    required this.workHours,
    this.bio = '',
    this.licenseNumber = '',
  });

  factory Lawyer.fromMap(Map<String, dynamic> map) {
    return Lawyer(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      specialty: (map['specialty'] ?? '').toString(),
      // استخدام tryParse لضمان عدم حدوث خطأ في تحويل الأرقام
      rating: double.tryParse(map['rating']?.toString() ?? '0.0') ?? 0.0,
      reviews: int.tryParse(map['reviews']?.toString() ?? '0') ?? 0,
      cases:
          int.tryParse((map['casesCount'] ?? map['cases'] ?? '0').toString()) ??
              0,
      casesCount: (map['casesCount'] ?? map['cases'] ?? '0').toString(),
      city: (map['city'] ?? '').toString(),
      price: (map['price'] ?? '').toString(),
      experience: (map['experience'] ?? '').toString(),
      lat: double.tryParse(
              (map['latitude'] ?? map['lat'] ?? '0.0').toString()) ??
          0.0,
      lng: double.tryParse(
              (map['longitude'] ?? map['lng'] ?? '0.0').toString()) ??
          0.0,
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      officeName: (map['officeName'] ?? '').toString(),
      officeAddress: (map['address'] ?? map['officeAddress'] ?? '').toString(),
      workHours: (map['workHours'] ?? '').toString(),
      bio: (map['bio'] ?? '').toString(),
      licenseNumber: (map['licenseNumber'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'rating': rating,
      'reviews': reviews,
      'casesCount': cases,
      'city': city,
      'price': price,
      'experience': experience,
      'latitude': lat,
      'longitude': lng,
      'email': email,
      'phone': phone,
      'officeName': officeName,
      'address': officeAddress,
      'workHours': workHours,
      'bio': bio,
      'licenseNumber': licenseNumber,
    };
  }
}
