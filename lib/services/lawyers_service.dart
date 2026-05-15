import 'package:cloud_firestore/cloud_firestore.dart'; // الربط مع قاعدة بيانات جوجل السحابية
import '../models/lawyer.dart';

/// خدمة إدارة بيانات المحامين والخبراء القانونيين.
/// تتولى هذه الخدمة عمليات الاستعلام (Querying) من مجموعة Users بداخل Firestore.
class LawyersService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// جلب كافة المحامين: تقوم بتصفية المستخدمين بناءً على الدور (role == lawyer).
  Future<List<Lawyer>> fetchLawyers() async {
    try {
      final snapshot = await _db
          .collection('Users')
          .where('role', isEqualTo: 'lawyer')
          .get();

      // تحويل الوثائق (Documents) القادمة من Firestore إلى قائمة من كائنات Lawyer البرمجية
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

  /// جلب بيانات محامي واحد: تستخدم عند فتح صفحة تفصيلية لمحامي معين عبر معرّفه الفريد (ID)
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
