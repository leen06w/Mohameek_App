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

  const Lawyer({
    required this.id,
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

  factory Lawyer.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return Lawyer(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      specialty: (json['specialty'] ?? json['practice_area'] ?? '').toString(),
      rating: parseDouble(json['rating']),
      reviews: parseInt(json['reviews']),
      cases: parseInt(json['cases']),
      city: (json['city'] ?? '').toString(),
      price: (json['price'] ?? json['consultation_fee'] ?? '').toString(),
      experience: (json['experience'] ?? '').toString(),
      lat: parseDouble(json['lat'] ?? json['latitude']),
      lng: parseDouble(json['lng'] ?? json['longitude']),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      officeName: (json['office_name'] ?? json['officeName'] ?? '').toString(),
      officeAddress: (json['office_address'] ?? json['officeAddress'] ?? '').toString(),
      workHours: (json['work_hours'] ?? json['workHours'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      licenseNumber: (json['license_number'] ?? json['licenseNumber'] ?? '').toString(),
    );
  }
}
