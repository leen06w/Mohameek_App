import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lawyer.dart';

class LawyersService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔍 جلب قائمة المحامين الحقيقيين من الفايربيس
  Future<List<Lawyer>> fetchLawyers() async {
    try {
      final snapshot = await _db
          .collection('Users')
          .where('role', isEqualTo: 'lawyer')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();

        return Lawyer(
          id: doc.id,
          name: data['name'] ?? 'محامي بدون اسم',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          specialty: data['specialty'] ?? 'عام',
          city: data['city'] ?? 'غير محدد',
          casesCount: data['casesCount']?.toString() ?? '0',
          experience: data['experience'] ?? '0',
          cases: int.tryParse(data['casesCount']?.toString() ?? '0') ?? 0,
          rating: double.tryParse(data['rating']?.toString() ?? '4.5') ?? 4.5,
          reviews: 10,
          price: data['price'] ?? '500',
          lat: (data['latitude'] ?? 26.4207).toDouble(),
          lng: (data['longitude'] ?? 50.0888).toDouble(),
          officeName: data['officeName'] ?? '',
          officeAddress: data['address'] ?? '',
          bio: data['bio'] ?? '',
          workHours: data['workHours'] ?? 'من 8 ص إلى 5 م',
        );
      }).toList();
    } catch (e) {
      print('Error fetching lawyers: $e');
      return [];
    }
  }

  /// 📄 جلب بيانات محامي واحد عن طريق الـ ID
  Future<Lawyer?> fetchLawyerById(String id) async {
    try {
      final doc = await _db.collection('Users').doc(id).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return Lawyer(
        id: doc.id,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        phone: data['phone'] ?? '',
        specialty: data['specialty'] ?? '',
        city: data['city'] ?? '',
        casesCount: data['casesCount']?.toString() ?? '0',
        experience: data['experience'] ?? '0',
        cases: int.tryParse(data['casesCount']?.toString() ?? '0') ?? 0,
        rating: double.tryParse(data['rating']?.toString() ?? '4.5') ?? 4.5,
        reviews: 10,
        price: data['price'] ?? '',
        lat: (data['latitude'] ?? 26.4207).toDouble(),
        lng: (data['longitude'] ?? 50.0888).toDouble(),
        officeName: data['officeName'] ?? '',
        officeAddress: data['address'] ?? '',
        bio: data['bio'] ?? '',
        // 👈 أضفته هنا أيضاً لضمان عدم حدوث خطأ
        workHours: data['workHours'] ?? 'غير محدد',
      );
    } catch (e) {
      print('Error fetching lawyer by id: $e');
      return null;
    }
  }
}
