import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';
import '../models/request_item.dart';
import 'booking_screen.dart';
import 'user_dashboard_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Object? details;

  const PaymentScreen({super.key, this.details});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int step = 1;
  bool _isProcessing = false; // 👈 تأكدي من وجود الشرطة السفلية
  final String _selectedMethod = 'Visa';

  final cardNumberController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();
  final cardNameController = TextEditingController();

  final otpControllers = List.generate(6, (_) => TextEditingController());
  final otpFocusNodes = List.generate(6, (_) => FocusNode());

  BookingDetails? get bookingDetails => widget.details is BookingDetails
      ? widget.details as BookingDetails
      : null;

  RequestItem? get requestDetails =>
      widget.details is RequestItem ? widget.details as RequestItem : null;

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
    final digits = cardNumberController.text.replaceAll(' ', '');
    final chunks = <String>[];

    for (var i = 0; i < digits.length; i += 4) {
      final end = (i + 4 < digits.length) ? i + 4 : digits.length;
      chunks.add(digits.substring(i, end));
    }

    return chunks.join(' ');
  }

  bool get canContinue {
    return cardNumberController.text.replaceAll(' ', '').length == 16 &&
        expiryController.text.trim().length == 5 &&
        cvvController.text.trim().length == 3 &&
        cardNameController.text.trim().isNotEmpty;
  }

  bool get otpComplete =>
      otpControllers.every((item) => item.text.trim().isNotEmpty);

  void _handleBack() {
    if (step > 1 && step < 3) {
      setState(() => step = step - 1);
      return;
    }

    Navigator.maybePop(context);
  }

  void _onCardNumberChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 16 ? digits.substring(0, 16) : digits;

    final chunks = <String>[];
    for (var i = 0; i < limited.length; i += 4) {
      final end = (i + 4 < limited.length) ? i + 4 : limited.length;
      chunks.add(limited.substring(i, end));
    }

    final formatted = chunks.join(' ');

    cardNumberController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    setState(() {});
  }

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

  void _onOtpChanged(int index, String value) {
    final digit = value.replaceAll(RegExp(r'\D'), '');

    if (digit.isEmpty) {
      otpControllers[index].clear();

      if (index > 0) {
        otpFocusNodes[index - 1].requestFocus();
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
      otpFocusNodes[index + 1].requestFocus();
    } else {
      otpFocusNodes[index].unfocus();
    }

    setState(() {});
  }

  Future<void> _continueToOtp() async {
    if (!canContinue) return;

    setState(() => step = 2);

    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      otpFocusNodes.first.requestFocus();
    }
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      await Future.delayed(const Duration(seconds: 2));

      // حفظ سجل دفع حقيقي في الفايربيس
      await FirebaseFirestore.instance.collection('Payments').add({
        'lawyerName': lawyerName,
        'amount': bookingPrice,
        'consultationType': consultationType,
        'date': FieldValue.serverTimestamp(),
        'status': 'success',
        'method': _selectedMethod,
        'userId': FirebaseAuth.instance.currentUser?.uid,
      });

      if (!mounted) return;
      _showSuccessDialog();
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
        onLeadingPressed: step == 3 ? null : _handleBack,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          _ProgressStrip(step: step),
          const SizedBox(height: 20),
          if (step == 1) _buildCardStep(),
          if (step == 2) _buildOtpStep(),
          if (step == 3) _buildSuccessStep(),
        ],
      ),
    );
  }

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
            textDirection: TextDirection.ltr,
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
                FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
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
                        obscureText: true,
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
            number: _formattedCardNumber,
            holder: cardNameController.text,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: 'المتابعة',
            onPressed: canContinue ? _continueToOtp : null,
          ),
        ],
      ),
    );
  }

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
              // 👈 إضافة سنتر لضمان التوسيط
              child: FittedBox(
                // 👈 الحل السحري: يمنع الـ Overflow ويصغر الخانات لتناسب الشاشة
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    otpControllers.length,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SizedBox(
                        width:
                            45, // 💡 تم تصغير العرض قليلاً من 48 إلى 45 لزيادة السلاسة
                        height: 58,
                        child: TextField(
                          controller: otpControllers[index],
                          focusNode: otpFocusNodes[index],
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

  void _showSuccessDialog() {
    setState(() {
      _isProcessing = false;
      step = 3; // تفعيل واجهة النجاح
    });

    // العودة التلقائية للرئيسية (لوحة التحكم) بعد 3 ثواني
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

class _ProgressStrip extends StatelessWidget {
  final int step;

  const _ProgressStrip({required this.step});

  @override
  Widget build(BuildContext context) {
    final labels = ['البطاقة', 'التحقق', 'النجاح'];

    return Row(
      children: List.generate(labels.length, (index) {
        final active = step >= index + 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary
                        : AppColors.secondary.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              if (index < labels.length - 1) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }
}

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
          colors: [AppColors.primary, Color(0xCC123458)],
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
            textDirection: TextDirection.ltr,
            child: Text(
              number.isEmpty ? '1234 5678 9012 3456' : number,
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
            holder.isEmpty ? 'اسم حامل البطاقة' : holder,
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
        alignment: centered ? Alignment.center : Alignment.centerRight,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

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
            color: AppColors.success,
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
