import '../models/app_user.dart';
import 'session_service.dart';

class AuthService {
  final SessionService _session = SessionService();

  /// 🔐 تسجيل الدخول
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    // 🔥 بيانات تجريبية ثابتة
    final demoUsers = {
      'user@test.com': {
        'password': '123',
        'name': 'لين وليد',
        'phone': '0500000000',
        'city': 'الرياض',
        'address': 'حي العليا',
        'role': 'user',
      },
      'lawyer@test.com': {
        'password': '123',
        'name': 'أحمد محامي',
        'phone': '0555555555',
        'city': 'الرياض',
        'address': 'مكتب محاماة',
        'role': 'lawyer',
      },
      'admin@test.com': {
        'password': '123',
        'name': 'مدير النظام',
        'phone': '0000000000',
        'city': 'الرياض',
        'address': 'الإدارة',
        'role': 'admin',
      },
    };

    final data = demoUsers[email];

    if (data != null && data['password'] == password) {
      final user = AppUser(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: data['name']!,
        email: email,
        phone: data['phone']!,
        city: data['city']!,
        address: data['address']!,
        role: data['role']!,
      );

      await _session.saveUser(user);

      return LoginResult(success: true, user: user);
    }

    return const LoginResult(
      success: false,
      errorMessage: 'بيانات الدخول غير صحيحة',
    );
  }

  /// 🆕 إنشاء حساب
  Future<LoginResult> signup(AppUser user) async {
    await _session.saveUser(user);
    return LoginResult(success: true, user: user);
  }

  /// 👤 المستخدم الحالي
  Future<AppUser?> getCurrentUser() async {
    return await _session.getUser();
  }

  /// ✏️ تحديث
  Future<void> updateUser(AppUser user) async {
    await _session.saveUser(user);
  }

  /// 🚪 تسجيل خروج
  Future<void> logout() async {
    await _session.clear();
  }
}

class LoginResult {
  final bool success;
  final AppUser? user;
  final String? errorMessage;

  const LoginResult({
    required this.success,
    this.user,
    this.errorMessage,
  });
}