import 'package:flutter/material.dart';

import '../app.dart';
import '../config/app_config.dart';
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
  final _emailController = TextEditingController(text: 'user@test.com');
  final _passwordController = TextEditingController(text: '123');
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

    final result = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _submitting = false);

    if (!result.success || result.user == null) {
      setState(() {
        _error = result.errorMessage ?? 'تعذر تسجيل الدخول';
      });
      return;
    }

    switch (result.user!.role) {
      case 'admin':
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        break;
      case 'lawyer':
        Navigator.pushReplacementNamed(context, AppRoutes.lawyerDashboard);
        break;
      default:
        Navigator.pushReplacementNamed(context, AppRoutes.userDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = AppConfig.isDemoMode || !AppConfig.hasBackend;

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
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 20,
                        color: Color(0x22000000),
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.balance,
                    color: AppColors.background,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'محاميك',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'منصتك القانونية الموثوقة',
                  style: TextStyle(
                    color: AppColors.foreground.withValues(alpha: 0.65),
                  ),
                ),
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
                  child: Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (isDemo) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Text(
                      'الوضع التجريبي مفعل حاليًا.\n'
                      'لن يتم الاتصال بأي Backend.\n\n'
                      'الحسابات المتاحة:\n'
                      'user@test.com / 123\n'
                      'lawyer@test.com / 123\n'
                      'admin@test.com / 123',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.destructive.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.destructive.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Text(
                      _error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.destructive,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                const Text(
                  'البريد الإلكتروني',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    hintText: 'example@email.com',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'كلمة المرور',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  textDirection: TextDirection.ltr,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.forgotPassword,
                    ),
                    child: const Text('نسيت كلمة المرور؟'),
                  ),
                ),
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
            onPressed: () => Navigator.pushNamed(context, AppRoutes.signup),
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            text: 'التسجيل كمحامي',
            icon: const Icon(Icons.work_outline),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.lawyerSignup),
          ),
          const SizedBox(height: 20),
          Text(
            'جميع الحقوق محفوظة © 2026 محاميك',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.foreground.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}