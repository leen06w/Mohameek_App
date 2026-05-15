import 'package:flutter/material.dart';
import '../app.dart';
import '../core/theme/app_colors.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

/// كلاس من نوع StatefulWidget يمثل شاشة "إنشاء حساب جديد" المخصصة للطلاب والمستخدمين العاديين.
/// يتولى الكلاس جمع وتحليل البيانات الشخصية والجغرافية، والتحقق من سلامة كلمات المرور وتطابقها، وربطها بالسيرفر.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

/// كلاس الحالة الديناميكي المسؤول عن إدارة الفالديتور، والتحكم بالأمان البصري لكشف كلمات المرور، وهندسة النوافذ الحوارية الناجحة.
class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

// --- متحكمات الحقول النصية لبيانات الطالب (TextEditingControllers) ---
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  final _authService =
      AuthService(); // تهيئة خدمة المصادقة للربط الفوري مع Firebase

  bool _submitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    // تفريغ كافة الكنترولرز من الذاكرة العشوائية فور مغادرة الصفحة لمنع الـ Memory Leaks
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  /// الدالة الأساسية لمعالجة شروط الفحص وإنشاء حساب العميل الجديد بـ قاعدة بيانات الفايربيس
  Future<void> _submit() async {
    FocusScope.of(context)
        .unfocus(); // إغلاق لوحة مفاتيح الهاتف تلقائياً فور النقر لدعم تجربة المستخدم UX

// 1. فحص استيفاء شروط الـ Validator لكافة الحقول المدخلة بالنموذج
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting =
        true); // تفعيل حلقة التحميل بالزر وقفل التفاعل لمنع الطلبات المزدوجة

    try {
      // 2. بناء كائن مستخدم جديد بالاعتماد على الموديل الرئيسي AppUser وحقن صلاحية مستخدم عادي (user)
      final user = AppUser(
        id: '', // يتم توليد المعرف الفرعي التلقائي (uid) بداخل الـ AuthService بواسطة الفايربيس
        name: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        role: 'user',
      );

// 3. استدعاء دالة التسجيل بالخلفية وتمرير كائن البيانات مع النص الصريح المفلتر لكلمة المرور
      final result =
          await _authService.signup(user, _passwordController.text.trim());
      if (!mounted)
        return; // فحص أمان للتأكد من بقاء الشاشة نشطة قبل تحديث الواجهة الرسومية

      setState(
          () => _submitting = false); // إيقاف التحميل بعد ورود استجابة السيرفر
// 4. معالجة نتيجة الرفع؛ وعرض تنبيه سفلي مخصص في حال حدوث عطل أو تكرار بالبريد
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'حدث خطأ أثناء إنشاء الحساب'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

// 5. في حال النجاح التام؛ يتم فتح نافذة الترحيب الحوارية المشروحة بالأسفل
      await _showSuccessDialog(
        title: 'تم إنشاء الحساب بنجاح',
        message:
            'تم تسجيلك بنجاح في منصة محاميك، ويمكنك الآن البدء في استخدام الخدمات القانونية.',
        buttonText: 'الانتقال إلى الرئيسية',
      );

      if (!mounted) return;
      // نقل الطالب جذرياً للوحة التحكم الرئيسية الخاصة بالمستخدمين ومسح سجل العودة للخلف تأميناً للحساب
      Navigator.pushReplacementNamed(context, AppRoutes.userDashboard);
    } catch (e) {
      setState(() => _submitting = false);
      print("Error during signup: $e");
    }
  }

  /// بناء وإظهار نافذة النجاح الحوارية المنبثقة بشكل فخم يعزز الثقة البصرية بالتطبيق
  Future<void> _showSuccessDialog({
    required String title,
    required String message,
    required String buttonText,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible:
          false, // حظر إغلاق النافذة عند النقر خارجها لضمان إكمال التوجيه بالشكل السليم
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // تصميم وسام الدائرة الأخضر الخاص بالنجاح
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8EE),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFB7E4C7)),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      size: 48, color: AppColors.success),
                ),
                const SizedBox(height: 18),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, height: 1.7)),
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
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(buttonText,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// دالة معالجة العودة للشاشة السابقة بأمان
  void _handleBack() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  /// دالة مساعدة لتوفير وتوحيد وتنسيق المظهر والزوايا والظلال لجميع حقول النص بالنموذج
  InputDecoration _inputDecoration(
      {required String hint, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon,
          color: AppColors.foreground..withValues(alpha: 0.65), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.3)),
    );
  }

  /// مكون إعادة الاستخدام البرمي (Reusable Component Widget) لبناء حقول الإدخال مضافاً إليها عناوينها وفحوصاتها التلقائية
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
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: type,
            validator: validator,
            decoration: _inputDecoration(
                hint: hint, icon: icon, suffixIcon: suffixIcon),
          ),
        ],
      ),
    );
  }

  /// دالة فصل الواجهة: مسؤولة عن رسم وتنسيق اللوجو والشريط العلوي الترحيبي بـ الشاشة
  Widget _buildTopHeader() {
    return Column(
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: _handleBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('رجوع',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(
                  foregroundColor:
                      AppColors.foreground.withValues(alpha: 0.75)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: 74,
          height: 74,
          decoration: const BoxDecoration(
              color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.inventory_2_outlined,
              color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        const Text('إنشاء حساب جديد',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('انضم إلى محاميك اليوم',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  /// دالة فصل الواجهة: مسؤولة عن تعبئة وتنظيم كرت الفورم المحتوي على الـ 7 حقول للفحص والتسجيل
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey, // ربط الفورم بالمفتاح العالمي
        child: Column(
          children: [
            _buildField(
                label: 'الاسم الكامل',
                hint: 'أدخل اسمك الكامل',
                icon: Icons.person_outline,
                controller:
                    _fullNameController, // إخفاء أو كشف الحروف بناءً على المتغير
                validator: (v) => v!.trim().isEmpty ? 'الحقل مطلوب' : null),
            _buildField(
                label: 'البريد الإلكتروني',
                hint: 'أدخل بريدك الإلكتروني',
                icon: Icons.email_outlined,
                controller: _emailController,
                type: TextInputType.emailAddress,
                validator: (v) =>
                    v!.isEmpty || !v.contains('@') ? 'بريد غير صحيح' : null),
            _buildField(
                label: 'رقم الهاتف',
                hint: '(+966 XX XXX XXXX)',
                icon: Icons.phone_outlined,
                controller: _phoneController,
                type: TextInputType.phone,
                validator: (v) => v!.trim().isEmpty ? 'الحقل مطلوب' : null),
            _buildField(
              label: 'كلمة المرور',
              hint: 'أنشئ كلمة مرور',
              icon: Icons.lock_outline,
              controller: _passwordController,
              obscure: _obscurePassword,
              validator: (v) =>
                  (v?.length ?? 0) < 6 ? 'يجب أن تكون 6 أحرف على الأقل' : null,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            _buildField(
              label: 'تأكيد كلمة المرور',
              hint: 'أعد إدخال كلمة المرور',
              icon: Icons.lock_person_outlined,
              controller: _confirmPasswordController,
              obscure: _obscureConfirmPassword,
              validator: (v) => v != _passwordController.text
                  ? 'كلمتا المرور غير متطابقتين'
                  : null,
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            _buildField(
                label: 'عنوان الشارع',
                hint: 'أدخل عنوان الشارع الخاص بك',
                icon: Icons.add_home_work_outlined,
                controller: _addressController,
                validator: (v) => v!.trim().isEmpty ? 'الحقل مطلوب' : null),
            _buildField(
                label: 'المدينة',
                hint: 'أدخل مدينتك',
                icon: Icons.location_on_outlined,
                controller: _cityController,
                validator: (v) => v!.trim().isEmpty ? 'الحقل مطلوب' : null),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('إنشاء حساب',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('لديك حساب بالفعل؟ ',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                TextButton(
                    onPressed: _handleBack,
                    child: const Text('تسجيل الدخول',
                        style: TextStyle(fontWeight: FontWeight.w800))),
              ],
            ),
          ],
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
          // استخدام الـ ListView للسماح بالتمرير عند خروج لوحة مفاتيح الهاتف ومنع الـ Overflow
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _buildTopHeader(),
            const SizedBox(height: 18),
            _buildFormCard(),
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: Text('بإنشاء حساب، أنت توافق على شروط الخدمة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.foreground..withValues(alpha: 0.50),
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
