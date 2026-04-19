class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String city;
  final String address;
  final String role;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.address,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'address': address,
      'role': role,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      city: map['city'] ?? '',
      address: map['address'] ?? '',
      role: map['role'] ?? 'user',
    );
  }
}