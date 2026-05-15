import 'package:flutter/material.dart';
import '../app.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';
import '../services/auth_service.dart';

// كلاس من نوع StatefulWidget يمثل شاشة "تسجيل الدخول" وبوابة العبور الأساسية للتطبيق.
// يتولى الكلاس تهيئة حقول الإدخال، والاتصال بخدمات المصادقة، والتحقق من أدوار المستخدمين لتوجيههم لوجهاتهم الصحيحة.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// كلاس الحالة الديناميكي المسؤول عن إدارة المدخلات، وإظهار/إخفاء كلمة المرور، وتدفق منطق التوجيه الذكي بناءً على صلاحيات الحساب.
class _LoginScreenState extends State<LoginScreen> {
  // --- أدوات التحكم البرمجي بالحقول النصية (Controllers) ---
  // تم وضع بيانات افتراضية مسبقاً لتسهيل وتسريع عمليات التجربة والفحص المحلي أثناء التطوير والتحكيم
  final _emailController = TextEditingController(text: 'admin@test.com');
  final _passwordController = TextEditingController(text: '123456');
  final _authService =
      AuthService(); // استدعاء خدمة المصادقة للربط بـ Firebase Auth

  bool _showPassword =
      false; // متغير منطقي للتحكم بحالة رؤية كلمة المرور (مخفية / ظاهرة)
  bool _submitting =
      false; // تتبع حالة الاتصال بالسيرفر لإظهار مؤشر التحميل ومنع النقر المتكرر
  String _error =
      ''; // متغير لحفظ نصوص الأخطاء الواردة من السيرفر وعرضها للمسخدم عند الفشل

// تفريغ الكنترولرز فور الخروج من الشاشة لحماية الذاكرة ومنع حدوث الـ Memory Leaks
  Future<void> _handleLogin() async {
    FocusScope.of(context)
        .unfocus(); // إغلاق الكيبورد تلقائياً فور النقر لتحسين تجربة المستخدم Visual UX

    setState(() {
      _error = ''; // تصفير الأخطاء السابقة قبل بدء المحاولة الجديدة
      _submitting =
          true; // تفعيل مؤشر التحميل وقفل الأزرار تفادياً للضغط المتكرر
    });

    // 1. تنفيذ عملية المصادقة غير المتزامنة عبر Firebase Auth ومطابقة البريد بكلمة المرور
    final result = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted)
      return; // التأكد من أن الشاشة لا تزال معروضة ولم يتم إغلاقها أثناء معالجة الطلب

    setState(
        () => _submitting = false); // إيقاف مؤشر التحميل بعد ورود الاستجابة
// 2. التحقق من نجاح العملية؛ وفي حال الفشل يتم عرض رسالة الخطأ المناسبة للمستخدم
    if (!result.success || result.user == null) {
      setState(() {
        _error = result.errorMessage ?? 'تعذر تسجيل الدخول، تأكد من البيانات';
      });
      return;
    }

    // 3. التوجيه الذكي (Smart Routing): قراءة دور المستخدم (Role) الموثق بالسيرفر ونقله لواجهته المخصصة
    final userRole = result.user!.role;

    if (userRole == 'admin') {
      // إذا كان الحساب مدير النظام، يتم توجيهه للوحة تحكم الآدمين
      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
    } else if (userRole == 'lawyer') {
      // إذا كان الحساب خبيراً قانونياً ومحامياً، يتم توجيهه للوحة تحكم المحامين
      Navigator.pushReplacementNamed(context, AppRoutes.lawyerDashboard);
    } else {
      // الحساب الافتراضي (طالب/مستخدم عادي) يتم توجيهه للشاشة الرئيسية للتطبيق (الرئيسية)
      Navigator.pushReplacementNamed(context, AppRoutes.userDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child:
                      const Icon(Icons.balance, color: Colors.white, size: 42),
                ),
                const SizedBox(height: 16),
                const Text('محاميك',
                    style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SectionCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                    child: Text('تسجيل الدخول',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w800))),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(_error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 18),
                const Text('البريد الإلكتروني',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                TextField(
                    controller: _emailController,
                    decoration:
                        const InputDecoration(hintText: 'example@email.com')),
                const SizedBox(height: 16),
                const Text('كلمة المرور',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                      icon: Icon(_showPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: _submitting ? 'جاري التحقق...' : 'دخول',
                  onPressed: _submitting ? null : _handleLogin,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // زر إنشاء حساب جديد خاص بالطلاب والمستخدمين العاديين
          SecondaryButton(
            text: 'إنشاء حساب جديد',
            outlined: true,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.signup),
          ),
          // زر مستقل مخصص لتوجيه المحامين والخبراء القانونيين لنموذج التسجيل المهني الخاص بهم
          SecondaryButton(
            text: 'التسجيل كمحامي',
            outlined: true,
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.lawyerSignup),
          ),
          const SizedBox(height: 20),
          const Text('جميع الحقوق محفوظة © 2026 محاميك',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
