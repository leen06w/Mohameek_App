import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // استيراد مكتبة الفايربيس لإدارة الحسابات والأمان
import '../core/theme/app_colors.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';

// الكلاس الثابت المسؤول عن تعريف شاشة استعادة كلمة المرور
/// كلاس من نوع StatefulWidget يمثل شاشة "استعادة وتعيين كلمة المرور المفقودة".
/// يوفر حقولاً محمية بأنظمة التحقق الرقمي (Validation)، ويتصل بخدمات الفايربيس للتحقق من وجود البريد،
/// ويقوم بتوليد روابط أمان مشفرة وإرسالها لبريد المستخدم تلقائياً دون أي تدخل يدوي من خادم التطبيق.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

// كلاس الحالة الديناميكي الذي يحتوي على منطق الواجهة والاتصال بالفايربيس
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // مفتاح عالمي لإدارة حالة الـ Form والتحقق من صحة المدخلات مجتمعة
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // متحكم بحقل النص الخاص بالبريد الإلكتروني، ويحتوي على بريد افتراضي للتسهيل أثناء التجربة
  final TextEditingController _emailController =
      TextEditingController(text: 'rr@dd.com');

  bool _submitting =
      false; // متغير لتتبع حالة الإرسال الحالية لإظهار مؤشر التحميل
  bool _linkSent =
      false; // متغير يتحول إلى true عند نجاح إرسال الرابط لإظهار رسالة النجاح الخضراء

  @override
  void dispose() {
    _emailController
        .dispose(); // تفريغ الذاكرة من المتحكم فور الخروج من الشاشة لمنع تسريب البيانات
    super.dispose();
  }

// دالة الرجوع للشاشة السابقة بأمان بعد التأكد من إمكانية العودة
  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

// الدالة الأساسية لإرسال طلب إعادة تعيين كلمة المرور
  Future<void> _submit() async {
    FocusScope.of(context)
        .unfocus(); // إغلاق لوحة المفاتيح تلقائياً عند الضغط على الزر لتحسين تجربة المستخدم

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true; // تشغيل حالة التحميل وتغيير نص الزر
      _linkSent = false; // إخفاء رسالة النجاح السابقة إن وجدت
    });

    try {
      // استدعاء دالة الفايربيس الرسمية لإرسال بريد إعادة التعيين مع تنظيف الفراغات المحيطة بالبريد
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (!mounted)
        return; // التأكد من أن الشاشة لا تزال مفتوحة قبل تحديث الواجهة

      setState(() {
        _submitting = false; // إيقاف مؤشر التحميل
        _linkSent = true; // إظهار بطاقة النجاح الخضراء للمستخدم
      });
// إظهار رسالة سفلية خفيفة تؤكد نجاح العملية
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('تم إرسال رابط إعادة تعيين كلمة المرور بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
    } on FirebaseAuthException catch (e) {
      setState(() => _submitting = false);

      // التعامل مع أخطاء الفايربيس (مثل إيميل غير موجود)
      String message = 'حدث خطأ ما، حاول مرة أخرى';
      if (e.code == 'user-not-found') {
        message = 'عذراً، هذا البريد الإلكتروني غير مسجل لدينا';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تأكد من اتصالك بالإنترنت')),
      );
    }
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      hintText: 'example@email.com',
      prefixIcon: const Icon(Icons.email_outlined),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.3,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.destructive,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.destructive,
          width: 1.3,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: _handleBack,
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'نسيت كلمة المرور',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: Center(
        child: SectionCard(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة تعيين كلمة المرور.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.foreground.withValues(alpha: 0.75),
                    height: 1.7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: _inputDecoration(),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'يرجى إدخال البريد الإلكتروني';
                    }
                    final emailRegex = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    );
                    if (!emailRegex.hasMatch(text)) {
                      return 'البريد الإلكتروني غير صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // زر الإرسال التفاعلي الذي يتغير نصه وحالته أثناء الاتصال بالسيرفر
                PrimaryButton(
                  text: _submitting ? 'جارٍ الإرسال...' : 'إرسال الرابط',
                  onPressed: _submitting
                      ? null
                      : _submit, // تعطيل الزر أثناء التحميل لمنع تكرار الطلبات
                ),
                // عرض بطاقة النجاح الخضراء بشكل شرطي وفقط عند اكتمال الإرسال بنجاح
                if (_linkSent) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8EE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFB7E4C7)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'تم إرسال الرابط بنجاح. تحقق من بريدك الإلكتروني.',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
