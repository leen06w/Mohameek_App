import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart'; // مكتبة المصادقة للربط بالـ uid الخاص بالمستخدم الحالي
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // تتيح استخدام المنسقات (Formatters) للتحكم بمدخلات الكيبورد
import 'package:cloud_firestore/cloud_firestore.dart'; // لحفظ سجلات المدفوعات الناجحة في السيرفر آلياً
import '../core/theme/app_colors.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';
import '../models/request_item.dart';
import 'booking_screen.dart';
import 'user_dashboard_screen.dart';

/// كلاس من نوع StatefulWidget يمثل بوابة الدفع الإلكتروني الآمنة في التطبيق.
/// يتولى الكلاس عرض ملخص الحجز المالي، وفحص بطاقة الائتمان، ومعالجة رمز الـ OTP، وأرشفة العملية في الـ Firestore.
class PaymentScreen extends StatefulWidget {
  final Object?
      details; // استقبال بيانات الاستشارة المحجوزة (سواء كائن BookingDetails أو RequestItem)

  const PaymentScreen({super.key, this.details});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

/// كلاس الحالة الديناميكي المسؤول عن معالجة الخطوات الثلاثة، وتنسيق أرقام البطاقة لحظياً، وإدارة مؤشرات الـ OTP.
class _PaymentScreenState extends State<PaymentScreen> {
  int step =
      1; // تتبع خطوة عملية الدفع الحالية (1: بيانات البطاقة، 2: رمز OTP، 3: شاشة النجاح)
  bool _isProcessing =
      false; // مؤشر لحالة معالجة الدفع لمنع النقر المتكرر وحماية البيانات المالية
  final String _selectedMethod = 'Visa'; // وسيلة الدفع الافتراضية للنظام

// --- متحكمات الحقول النصية لبيانات بطاقة الائتمان ---
  final cardNumberController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();
  final cardNameController = TextEditingController();

// توليد مصفوفات ذكية للتحكم بالتركيز والنصوص لـ 6 خانات مخصصة لرمز الـ OTP
  final otpControllers = List.generate(6, (_) => TextEditingController());
  final otpFocusNodes = List.generate(6, (_) => FocusNode());

// دالة كاشف ذكية لمعرفة نوع تفاصيل الحجز الممررة عبر الواجهات
  BookingDetails? get bookingDetails => widget.details is BookingDetails
      ? widget.details as BookingDetails
      : null;

  RequestItem? get requestDetails =>
      widget.details is RequestItem ? widget.details as RequestItem : null;

// --- دوال جلب البيانات الشرطية لملخص الفاتورة المالي الحالي ---
  String get lawyerName {
    if (bookingDetails != null) return bookingDetails!.lawyer.name;
    if (requestDetails != null) return requestDetails!.lawyerName;
    return 'د. أحمد محمد العلي';
  }

  String get consultationType {
    if (bookingDetails != null) return bookingDetails!.consultationType;
    if (requestDetails != null) return requestDetails!.consultationType;
    return 'استشارة عن بعد';
  }

  String get bookingDate {
    if (bookingDetails != null) return bookingDetails!.date;
    if (requestDetails != null) return requestDetails!.preferredDate;
    return '2026-04-07';
  }

  String get bookingTime {
    if (bookingDetails != null) return bookingDetails!.time;
    if (requestDetails != null) return requestDetails!.preferredTime;
    return '10:00';
  }

  String get bookingPrice {
    if (bookingDetails != null) return bookingDetails!.price;
    if (requestDetails != null) return requestDetails!.price ?? '0';
    return '500';
  }

  @override
  void dispose() {
    // تفريغ كافة الموارد والمتحكمات وعقد التركيز فور الخروج لحماية الذاكرة والأمان المالي للمشروع
    cardNumberController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    cardNameController.dispose();

    for (final controller in otpControllers) {
      controller.dispose();
    }

    for (final node in otpFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  String get _formattedCardNumber {
    // دالة (Getter) لتنسيق أرقام البطاقة مع الفراغات لعرضها بشكل حي فوق كرت الفيزا التفاعلي
    final digits = cardNumberController.text.replaceAll(' ', '');
    final chunks = <String>[];

    for (var i = 0; i < digits.length; i += 4) {
      final end = (i + 4 < digits.length) ? i + 4 : digits.length;
      chunks.add(digits.substring(i, end));
    }

    return chunks.join(' ');
  }

// شرط منطقي للتأكد من اكتمال وصحة صياغة كافة حقول البطاقة قبل تفعيل زر المتابعة
  bool get canContinue {
    return cardNumberController.text.replaceAll(' ', '').length == 16 &&
        expiryController.text.trim().length == 5 &&
        cvvController.text.trim().length == 3 &&
        cardNameController.text.trim().isNotEmpty;
  }

// فحص اكتمال إدخال الـ 6 أرقام الخاصة بالتحقق للـ OTP
  bool get otpComplete =>
      otpControllers.every((item) => item.text.trim().isNotEmpty);

// دالة إدارة تراجع الخطوات عند النقر على سهم العودة العلوي
  void _handleBack() {
    if (step > 1 && step < 3) {
      setState(() => step = step - 1);
      return;
    }

    Navigator.maybePop(context);
  }

// دالة المعالجة الفورية لرقم البطاقة؛ تحظر الحروف وتحقن مسافة تنظيمية كل 4 أرقام آلياً
  void _onCardNumberChanged(String value) {
    final digits =
        value.replaceAll(RegExp(r'\D'), ''); // فلترة النص من أي حقول غير رقمية
    final limited = digits.length > 16 ? digits.substring(0, 16) : digits;

    final chunks = <String>[];
    for (var i = 0; i < limited.length; i += 4) {
      final end = (i + 4 < limited.length) ? i + 4 : limited.length;
      chunks.add(limited.substring(i, end));
    }

    final formatted = chunks.join(' ');

    cardNumberController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
          offset: formatted.length), // الحفاظ على بقاء مؤشر الكتابة في النهاية
    );

    setState(() {});
  }

// دالة المعالجة الفورية لتاريخ الانتهاء؛ تحقن خط السلاش آلياً بعد كتابة الشّهر
  void _onExpiryChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    String formatted = digits;

    if (digits.length >= 2) {
      final first = digits.substring(0, 2);
      final second = digits.length > 2
          ? digits.substring(2, digits.length > 4 ? 4 : digits.length)
          : '';
      formatted = second.isEmpty ? first : '$first/$second';
    }

    if (formatted.length > 5) {
      formatted = formatted.substring(0, 5);
    }

    expiryController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    setState(() {});
  }

// دالة المعالجة التلقائية لخانات الـ OTP؛ تنقل التركيز للمربع التالي آلياً فور الكتابة وللخلف فور الحذف
  void _onOtpChanged(int index, String value) {
    final digit = value.replaceAll(RegExp(r'\D'), '');

    if (digit.isEmpty) {
      otpControllers[index].clear();

      if (index > 0) {
        otpFocusNodes[index - 1].requestFocus(); // إرجاع المؤشر للخلف عند الحذف
      }

      setState(() {});
      return;
    }

    final lastDigit = digit.substring(digit.length - 1);

    otpControllers[index].value = TextEditingValue(
      text: lastDigit,
      selection: const TextSelection.collapsed(offset: 1),
    );

    if (index < otpControllers.length - 1) {
      otpFocusNodes[index + 1]
          .requestFocus(); // تقديم المؤشر للامام فور الكتابة
    } else {
      otpFocusNodes[index]
          .unfocus(); // إغلاق الكيبورد عند اكتمال الخانة الأخيرة
    }

    setState(() {});
  }

// الانتقال الآمن للخطوة الثانية وتفعيل مؤشر التركيز على حقل الـ OTP الأول
  Future<void> _continueToOtp() async {
    if (!canContinue) return;

    setState(() => step = 2);

    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      otpFocusNodes.first.requestFocus();
    }
  }

// الدالة الأساسية لمعالجة وحفظ عملية الدفع الناجحة في جدول المدفوعات بالفايربيس
  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      await Future.delayed(const Duration(
          seconds: 2)); // محاكاة عملية فحص البنك في الخلفية لثانيتين

      // 1. حقن وتوثيق سجل مالي حقيقي ومفصل داخل مجموعة المدفوعات (Payments) بالـ Firestore
      await FirebaseFirestore.instance.collection('Payments').add({
        'lawyerName': lawyerName,
        'amount': bookingPrice,
        'consultationType': consultationType,
        'date': FieldValue
            .serverTimestamp(), // توقيت الخادم المعتمد والنزيه لمنع التلاعب
        'status': 'success',
        'method': _selectedMethod,
        'userId': FirebaseAuth.instance.currentUser
            ?.uid, // ربط السجل بالمعرف الفرعي الفريد للعميل الحالي
      });

      if (!mounted) return;
      _showSuccessDialog(); // فتح واجهة النجاح النهائية والأرشفة
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('عذراً، حدث خطأ أثناء معالجة الدفع: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appBar: AppHeader(
        title: 'الدفع',
        leadingIcon: Icons.arrow_back,
        onLeadingPressed: step == 3
            ? null
            : _handleBack, // حظر الرجوع للخلف إذا اكتملت العملية بنجاح لتأمين البيانات
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // عرض كرت ملخص الفاتورة والبيانات طالما أن العملية لم تنتهي بنجاح بعد
          if (step != 3) ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ملخص الحجز',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(label: 'المحامي:', value: lawyerName),
                  _SummaryRow(label: 'نوع الاستشارة:', value: consultationType),
                  _SummaryRow(label: 'التاريخ:', value: bookingDate),
                  _SummaryRow(label: 'الوقت:', value: bookingTime),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _SummaryRow(
                    label: 'المجموع:',
                    value: '$bookingPrice ر.س',
                    highlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          _ProgressStrip(step: step), // حقن شريط الخطوات العلوي التفاعلي
          const SizedBox(height: 20),
          // التبديل والتحويل الشرطي بين واجهات الخطوات الثلاثة بناءً على قيمة المتغير step
          if (step == 1) _buildCardStep(),
          if (step == 2) _buildOtpStep(),
          if (step == 3) _buildSuccessStep(),
        ],
      ),
    );
  }

// --- بناء الخطوة الأولى: إدخال وفحص بيانات كرت البنك ---
  Widget _buildCardStep() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.credit_card, size: 24),
              SizedBox(width: 8),
              Text(
                'معلومات البطاقة',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _FieldLabel(text: 'رقم البطاقة'),
          Directionality(
            textDirection: TextDirection
                .ltr, // إجبار أرقام البطاقة على القراءة والترتيب من اليسار لليمين LTR
            child: TextField(
              controller: cardNumberController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9 ]')), // حظر إدخال أي رموز أو حروف برمجياً
              ],
              onChanged: _onCardNumberChanged,
              decoration: const InputDecoration(
                hintText: '1234 5678 9012 3456',
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(text: 'تاريخ الانتهاء'),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextField(
                        controller: expiryController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                        ],
                        onChanged: _onExpiryChanged,
                        decoration: const InputDecoration(
                          hintText: 'MM/YY',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(text: 'CVV'),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextField(
                        controller: cvvController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        obscureText:
                            true, // إخفاء أرقام رمز الأمان الثلاثية لحماية خصوصية العميل
                        maxLength: 3,
                        onChanged: (_) => setState(() {}),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                          hintText: '123',
                          counterText: '',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _FieldLabel(text: 'اسم حامل البطاقة'),
          TextField(
            controller: cardNameController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'الاسم كما هو مكتوب على البطاقة',
            ),
          ),
          const SizedBox(height: 18),
          _PaymentBrandCard(
            // حقل كرت المعاينة التفاعلي والحي للبطاقة
            number: _formattedCardNumber,
            holder: cardNameController.text,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: 'المتابعة',
            onPressed: canContinue
                ? _continueToOtp
                : null, // يتعطل الزر تلقائياً إذا لم تكتمل شروط الصياغة لسلامة المعالجة
          ),
        ],
      ),
    );
  }

// --- بناء الخطوة الثانية: واجهة التحقق الآمن عبر رمز الـ OTP ---
  Widget _buildOtpStep() {
    return SectionCard(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone_android,
              color: AppColors.primary,
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'التحقق من الهوية',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تم إرسال رمز التحقق إلى رقم جوالك المسجل',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.foreground.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '••• ••• 1234',
            style: TextStyle(
              color: AppColors.foreground.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 22),
          const _FieldLabel(
            text: 'أدخل رمز التحقق (OTP)',
            centered: true,
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              // إضافة سنتر لضمان التوسيط
              child: FittedBox(
                // الحل الهندسي السحري الذي يمنع الـ Overflow ويصغر الخانات تلقائياً لتناسب أبعاد المتصفح والشاشات الصغيرة
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    otpControllers.length,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SizedBox(
                        width:
                            45, //  تم تصغير العرض قليلاً من 48 إلى 45 لزيادة السلاسة
                        height: 58,
                        child: TextField(
                          controller: otpControllers[index],
                          focusNode: otpFocusNodes[
                              index], // ربط عقد التحكم بالتركيز والانتقال الآلي
                          keyboardType: TextInputType.number,
                          textInputAction: index == otpControllers.length - 1
                              ? TextInputAction.done
                              : TextInputAction.next,
                          maxLength: 1,
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(
                            fontSize:
                                22, // 💡 تصغير الخط قليلاً ليتناسب مع الحجم الجديد
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            color: AppColors.foreground,
                          ),
                          cursorColor: AppColors.primary,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.6,
                              ),
                            ),
                          ),
                          onChanged: (value) => _onOtpChanged(index, value),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: _isProcessing ? 'جاري المعالجة...' : 'تأكيد الدفع',
            onPressed: otpComplete && !_isProcessing ? _processPayment : null,
          ),
          TextButton(
            onPressed: () {},
            child: const Text('إعادة إرسال الرمز'),
          ),
        ],
      ),
    );
  }

// --- بناء الخطوة الثالثة والأخيرة: شاشة النجاح المالي التامة والمؤقت الآلي ---
  Widget _buildSuccessStep() {
    return SectionCard(
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF8EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 62,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'تم الدفع بنجاح!',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تم حجز الاستشارة القانونية بنجاح',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.foreground.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 22),
          const _NotifyRow(title: 'رسالة نصية (SMS)'),
          const SizedBox(height: 8),
          const _NotifyRow(title: 'البريد الإلكتروني'),
          const SizedBox(height: 8),
          const _NotifyRow(title: 'إشعار داخل التطبيق'),
          const SizedBox(height: 18),
          Text(
            'سيتم تحويلك تلقائيًا إلى الصفحة الرئيسية',
            style: TextStyle(
              color: AppColors.foreground.withValues(alpha: 0.52),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

// تفعيل واجهة النجاح المالي وبدء العد التنازلي للتحويل الجذري الآمن لوحة التحكم
  void _showSuccessDialog() {
    setState(() {
      _isProcessing = false;
      step = 3; // تفعيل واجهة النجاح
    });

    // تحويل آلي وجذري للمستخدم بعد 3 ثواني مع مسح وحظر سجل العودة لشاشة الدفع (pushAndRemoveUntil) لسلامة العمليات المالية
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const UserDashboardScreen()),
          (route) => false, // يحذف كل الصفحات اللي قبل عشان ما يقدر يرجع للدفع
        );
      }
    });
  }
}

/// ويدجت من نوع StatelessWidget مخصصة لرسم شريط مؤشر التقدم الأفقي بأعلى شاشة الدفع.
/// تتلقى الخطوة الحالية [step]، وتقوم بتوليد خطوط المؤشر ديناميكياً باستخدام [List.generate]،
/// وتتحكم بلون الخط (نشط بلون التطبيق الأساسي، أو خامل) لتعريف العميل بمرحلته الحالية في الدفع.
class _ProgressStrip extends StatelessWidget {
  final int step;

  const _ProgressStrip({required this.step});

  @override
  Widget build(BuildContext context) {
    final labels = ['البطاقة', 'التحقق', 'النجاح'];

    return Row(
      children: List.generate(labels.length, (index) {
        final active =
            step >= index + 1; // فحص ما إذا كانت المحطة الحالية نشطة أم لا

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary
                        : AppColors.secondary.withValues(
                            alpha: 0.55), // تلوين الخط بناءً على حالة النشاط
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              if (index < labels.length - 1)
                const SizedBox(
                    width:
                        8), // إضافة مسافة فاصلة بين الخطوط ما عدا العنصر الأخير
            ],
          ),
        );
      }),
    );
  }
}

/// ويدجت تفاعلية (Live Preview Card) تحاكي المظهر البصري لبطاقة الائتمان الحقيقية (Visa/MasterCard).
/// فائدتها تحسين تجربة المستخدم (UX UX)؛ حيث تستقبل رقم البطاقة [number] واسم حاملها [holder]،
/// وتعرضهم بشكل حي فوري فوق كرت مميز ذو تدرج لوني [LinearGradient] وظلال احترافية
class _PaymentBrandCard extends StatelessWidget {
  final String number;
  final String holder;

  const _PaymentBrandCard({
    required this.number,
    required this.holder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            Color(0xCC123458)
          ], // تدرج لوني فخم متناسق مع هوية "محاميك" البصرية
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22123458),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'بطاقة الدفع',
                style: TextStyle(
                  color: AppColors.background,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.credit_score, color: AppColors.background),
            ],
          ),
          const SizedBox(height: 28),
          Directionality(
            textDirection: TextDirection
                .ltr, // إجبار أرقام الفيزا على الترتيب من اليسار لليمين دائماً لسلامة المظهر
            child: Text(
              number.isEmpty
                  ? '1234 5678 9012 3456'
                  : number, // عرض رقم افتراضي تلميحي إذا كان الحقل فارغاً
              style: const TextStyle(
                color: AppColors.background,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            holder.isEmpty
                ? 'اسم حامل البطاقة'
                : holder, // عرض نص افتراضي إذا لم يكتب المستخدم اسمه بعد
            style: const TextStyle(
              color: AppColors.background,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// مكون بصري مصغر وموحد (Reusable Widget) مخصص لرسم وتنسيق نصوص العناوين فوق حقول الإدخال.
/// يدعم خاصية المحاذاة الشرطية [centered] لتوسيط النص (مثل واجهة الـ OTP) أو محاذاته لليمين تلقائياً.
class _FieldLabel extends StatelessWidget {
  final String text;
  final bool centered;

  const _FieldLabel({
    required this.text,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: centered
            ? Alignment.center
            : Alignment.centerRight, // تحديد اتجاه النص شرطياً
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// ويدجت مخصصة لتنسيق وعرض أسطر "ملخص الفاتورة المالي" بشكل مرن ومنظم.
/// تفصل التسمية [label] عن القيمة [value] باستخدام [Expanded]، وتدعم متغير [highlight]
/// لتكبير الخط وتلوينه بلون التطبيق الأساسي عند عرض المجموع النهائي ليلفت عين المستخدم.
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.foreground.withValues(alpha: 0.62),
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? AppColors.primary : AppColors.foreground,
              fontSize: highlight ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة بصرية مستقلة تُستخدم في واجهة النجاح الأخيرة (Step 3).
/// فائدتها عرض قنوات تأكيد الحجز للمستخدم (مثل البريد، SMS)، داخل حاوية محددة بالحواف
/// ومزودة بأيقونة صح خضراء ثابتة [Icons.check_circle] لتوحيد وتجميل شكل اللائحة النهائية.
class _NotifyRow extends StatelessWidget {
  final String title;

  const _NotifyRow({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.success, // أيقونة النجاح الخضراء الموحدة بالنظام
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
