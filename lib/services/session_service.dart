import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

/// تستخدم هذه الخدمة لتخزين بيانات المستخدم والـ Token على ذاكرة الجهاز الدائمة،
/// مما يسمح للتطبيق بتذكر المستخدم حتى بعد إغلاقه وإعادة فتحه.
class SessionService {
  static const _userKey = 'app_user'; // المفتاح البرمجي لتخزين بيانات المستخدم
  static const _accessTokenKey = 'accessToken'; // مفتاح تخزين توكن الوصول
  /// حفظ بيانات المستخدم: يتم تحويل كائن المستخدم إلى نص (JSON) وتخزينه محلياً.
  Future<void> saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
  }

  /// استرجاع بيانات المستخدم: قراءة النص المخزن وتحويله مجدداً إلى كائن (Object) لاستخدامه في الواجهات.
  Future<AppUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_userKey);

    if (json == null) return null;

    // تحويل البيانات المسترجعة من صيغة JSON إلى كائن AppUser
    return AppUser.fromMap(jsonDecode(json), '');
  }

  /// حفظ توكن الأمان الخاص بالـ API.
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
  }

  /// جلب التوكن لاستخدامه في طلبات الـ HTTP المشفرة.ر
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// تطهير الجلسة: مسح كافة البيانات المخزنة عند تسجيل الخروج لضمان الأمان.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// فحص حالة الدخول: دالة سريعة لمعرفة ما إذا كان هناك مستخدم مسجل حالياً أم لا.
  Future<bool> isLoggedIn() async {
    final user = await getUser();
    return user != null;
  }
}
