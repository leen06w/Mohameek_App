import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import 'session_service.dart';

/// الخدمة المركزية المسؤولة عن نظام المصادقة (Authentication).
/// تتواصل مع Firebase Auth للتحقق من الحسابات ومع Firestore لجلب بيانات المستخدمين.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SessionService _session = SessionService();

  /// دالة تسجيل الدخول: تتحقق من البريد وكلمة المرور وتجلب بيانات الدور (Role) من Firestore.
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // جلب بيانات المستخدم الإضافية (مثل الاسم والدور) من قاعدة البيانات

      DocumentSnapshot doc =
          await _db.collection('Users').doc(credential.user!.uid).get();

      if (!doc.exists) {
        return const LoginResult(
            success: false, errorMessage: 'بيانات المستخدم غير موجودة');
      }

      final data = doc.data() as Map<String, dynamic>;

      final user = AppUser(
        id: credential.user!.uid,
        name: data['name'] ?? '',
        email: email,
        phone: data['phone'] ?? '',
        city: data['city'] ?? '',
        address: data['address'] ?? '',
        role: data['role'] ?? 'user',
      );

      // حفظ بيانات الجلسة محلياً لسرعة الوصول
      await _session.saveUser(user);
      return LoginResult(success: true, user: user);
    } on FirebaseAuthException catch (e) {
      return LoginResult(
          success: false, errorMessage: e.message ?? 'خطأ في الدخول');
    } catch (e) {
      return LoginResult(success: false, errorMessage: e.toString());
    }
  }

  /// دالة إنشاء حساب جديد وتخزين البيانات في Firestore مع حفظ الجلسة محلياً.
  Future<LoginResult> signup(AppUser user, String password) async {
    try {
      // 1. إنشاء الحساب في Firebase Authentication
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      // 2. تجهيز البيانات للتخزين في Firestore
      final userData = {
        'uid': credential.user!.uid,
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'city': user.city,
        'address': user.address,
        'role': user.role,
        'status': user.status,
        'specialty': user.specialty,
        'createdAt':
            FieldValue.serverTimestamp(), // تخزين وقت إنشاء الحساب بدقة السيرفر
      };

      // 3. التخزين في مجموعة Users
      await _db.collection('Users').doc(credential.user!.uid).set(userData);

      final newUser = AppUser(
        id: credential.user!.uid,
        name: user.name,
        email: user.email,
        phone: user.phone,
        city: user.city,
        address: user.address,
        role: user.role,
      );

      await _session.saveUser(newUser);
      return LoginResult(success: true, user: newUser);
    } on FirebaseAuthException catch (e) {
      return LoginResult(success: false, errorMessage: e.message ?? e.message!);
    } catch (e) {
      return LoginResult(success: false, errorMessage: e.toString());
    }
  }

  /// جلب بيانات المستخدم المسجل حالياً من الجلسة المحفوظة.
  Future<AppUser?> getCurrentUser() async {
    return await _session.getUser();
  }

  /// تحديث بيانات المستخدم وتعديلها في الجلسة المحلية.
  Future<void> updateUser(AppUser user) async {
    await _session.saveUser(user);
  }

  /// تسجيل الخروج وتطهير الجلسة الحالية
  Future<void> logout() async {
    await _auth.signOut();
    await _session.clear();
  }
}

class LoginResult {
  final bool success;
  final AppUser? user;
  final String? errorMessage;
  const LoginResult({required this.success, this.user, this.errorMessage});
}
