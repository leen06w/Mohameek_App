import 'package:flutter/material.dart';
import '../app.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // للسهولة أثناء التجربة تركت البيانات الافتراضية
  final _emailController = TextEditingController(text: 'admin@test.com');
  final _passwordController = TextEditingController(text: '123456');
  final _authService = AuthService();

  bool _showPassword = false;
  bool _submitting = false;
  String _error = '';

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _error = '';
      _submitting = true;
    });

    // تنفيذ عملية تسجيل الدخول عبر Firebase Auth
    final result = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _submitting = false);

    if (!result.success || result.user == null) {
      setState(() {
        _error = result.errorMessage ?? 'تعذر تسجيل الدخول، تأكد من البيانات';
      });
      return;
    }

    // التوجيه الذكي بناءً على الرتبة (Role) من قاعدة البيانات
    final userRole = result.user!.role;

    if (userRole == 'admin') {
      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
    } else if (userRole == 'lawyer') {
      Navigator.pushReplacementNamed(context, AppRoutes.lawyerDashboard);
    } else {
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
          SecondaryButton(
            text: 'إنشاء حساب جديد',
            outlined: true,
            onPressed: () => Navigator.pushNamed(
                context, AppRoutes.signup), // تأكدي من هذا السطر
          ),
          // أضيفي هذا الزر تحت زر إنشاء حساب جديد مباشرة
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
