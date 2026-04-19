import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme/app_colors.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'الرياض');

  final _authService = AuthService();

  bool _submitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final user = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      city: _cityController.text.trim(),
      address: _addressController.text.trim(),
      role: 'user',
    );

    final result = await _authService.signup(user);

    if (!mounted) return;

    setState(() => _submitting = false);

    if (!result.success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'حدث خطأ أثناء إنشاء الحساب'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    await _showSuccessDialog(
      title: 'تم إنشاء الحساب بنجاح',
      message:
          'تم تسجيلك بنجاح في منصة محاميك، ويمكنك الآن البدء في استخدام الخدمات القانونية.',
      buttonText: 'الانتقال إلى الرئيسية',
    );

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.userDashboard);
  }

  Future<void> _showSuccessDialog({
    required String title,
    required String message,
    required String buttonText,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8EE),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFB7E4C7)),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 48,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.7,
                    fontSize: 14,
                    color: AppColors.foreground.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(
                      buttonText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: AppColors.foreground.withValues(alpha: 0.65),
        size: 20,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.3,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.destructive,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.destructive,
          width: 1.3,
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: type,
            validator: validator,
            decoration: _inputDecoration(
              hint: hint,
              icon: icon,
              suffixIcon: suffixIcon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Column(
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: _handleBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text(
                'رجوع',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.foreground.withValues(alpha: 0.75),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.20),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'إنشاء حساب جديد',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'انضم إلى محاميك اليوم',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.foreground.withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildField(
              label: 'الاسم الكامل',
              hint: 'أدخل اسمك الكامل',
              icon: Icons.person_outline,
              controller: _fullNameController,
              validator: (v) => v!.trim().isEmpty ? 'الحقل مطلوب' : null,
            ),
            _buildField(
              label: 'البريد الإلكتروني',
              hint: 'أدخل بريدك الإلكتروني',
              icon: Icons.email_outlined,
              controller: _emailController,
              type: TextInputType.emailAddress,
              validator: (v) {
                final text = v?.trim() ?? '';
                if (text.isEmpty) return 'الحقل مطلوب';
                if (!text.contains('@')) return 'بريد إلكتروني غير صحيح';
                return null;
              },
            ),
            _buildField(
              label: 'رقم الهاتف',
              hint: '(+966 XX XXX XXXX)',
              icon: Icons.phone_outlined,
              controller: _phoneController,
              type: TextInputType.phone,
              validator: (v) => v!.trim().isEmpty ? 'الحقل مطلوب' : null,
            ),
            _buildField(
              label: 'كلمة المرور',
              hint: 'أنشئ كلمة مرور',
              icon: Icons.lock_outline,
              controller: _passwordController,
              obscure: _obscurePassword,
              validator: (v) =>
                  (v?.length ?? 0) < 6 ? 'يجب أن تكون 6 أحرف على الأقل' : null,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            _buildField(
              label: 'تأكيد كلمة المرور',
              hint: 'أعد إدخال كلمة المرور',
              icon: Icons.lock_person_outlined,
              controller: _confirmPasswordController,
              obscure: _obscureConfirmPassword,
              validator: (v) =>
                  v != _passwordController.text ? 'كلمتا المرور غير متطابقتين' : null,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            _buildField(
              label: 'عنوان الشارع',
              hint: 'أدخل عنوان الشارع الخاص بك',
              icon: Icons.add_home_work_outlined,
              controller: _addressController,
              validator: (v) => v!.trim().isEmpty ? 'الحقل مطلوب' : null,
            ),
            _buildField(
              label: 'المدينة',
              hint: 'أدخل مدينتك',
              icon: Icons.location_on_outlined,
              controller: _cityController,
              validator: (v) => v!.trim().isEmpty ? 'الحقل مطلوب' : null,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'إنشاء حساب',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'لديك حساب بالفعل؟ ',
                  style: TextStyle(
                    color: AppColors.foreground.withValues(alpha: 0.58),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: _handleBack,
                  child: const Text(
                    'تسجيل الدخول',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterNote() {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        'بإنشاء حساب، أنت توافق على شروط الخدمة',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.foreground.withValues(alpha: 0.50),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _buildTopHeader(),
            const SizedBox(height: 18),
            _buildFormCard(),
            _buildFooterNote(),
          ],
        ),
      ),
    );
  }
}