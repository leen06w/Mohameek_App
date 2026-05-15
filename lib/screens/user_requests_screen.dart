import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';
import '../models/request_item.dart';
import '../services/requests_service.dart';

/// كلاس من نوع StatefulWidget يمثل شاشة "طلباتي" المخصصة للطلاب لمتابعة وتتبع طلبات الاستشارة المرسلة للمحامين.
/// يتولى الكلاس جلب الطلبات من السيرفر، وإدارة مؤشرات التحميل، وعرض حالات القبول والرفض، وفتح مسار بوابة الدفع المالي.
class UserRequestsScreen extends StatefulWidget {
  const UserRequestsScreen({super.key});

  @override
  State<UserRequestsScreen> createState() => _UserRequestsScreenState();
}

/// كلاس الحالة الديناميكي المسؤول عن معالجة استدعاء دالة جلب الطلبات، وتنظيم أوسمة الحالات [InfoChip]، والتحويل الآمن لبوابة الدفع.
class _UserRequestsScreenState extends State<UserRequestsScreen> {
  final _requestsService =
      RequestsService(); // استدعاء ملف خدمة وإدارة سجلات الطلبات في قاعدة البيانات

  List<RequestItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// دالة غير متزامنة تتصل بالـ RequestsService لجلب قائمة الطلبات وتحديث الحالة محلياً
  Future<void> _load() async {
    setState(
        () => _loading = true); // تشغيل مؤشر التحميل وتصفير الحالات السابقة

    final items = await _requestsService.fetchRequests();

    if (!mounted) return;

    setState(() {
      _items = items;
      _loading = false;
    });
  }

  /// دالة معالجة زر العودة العلوي الذكي؛ لضمان عدم حدوث فراغ في سجل التصفح
  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(
          context); // الرجوع للشاشة السابقة إذا تم فتحها من نظام الـ Stacks
    } else {
      // كخيار أمان أخير، إذا فتحت الشاشة بشكل مستقل، يتم تصفير المسارات ونقل الطالب آلياً للوحة التحكم الرئيسية
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.userDashboard,
        (route) => false,
      );
    }
  }

  /// فتح اللوحة السفلية المنبثقة لاستعراض التفاصيل الكاملة للمشكلة القانونية
  void _openDetails(RequestItem request) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestDetailsSheet(request: request),
    );
  }

  /// دالة التوجيه المالي: تنقل الطالب فوراً لبوابة الدفع الآمنة وتمرر كائن الطلب [request] كـ حجة Arguments بالمسار
  void _goToPayment(RequestItem request) {
    Navigator.pushNamed(
      context,
      AppRoutes.userPayment,
      arguments: request,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      scrollable:
          false, // تعطيل السكرول الخارجي للـ AppShell للاعتماد على سكرول الـ ListView الداخلي لضمان ثبات الواجهة
      padding: EdgeInsets.zero,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: _handleBack,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'طلباتي',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: RefreshIndicator(
        onRefresh:
            _load, // ربط سحب الشاشة للأسفل (Pull-to-Refresh) بدالة تحديث البيانات اللحظية
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            Text(
              'تتبع حالة طلباتك وقم بإكمال عملية الدفع للطلبات المقبولة',
              style: TextStyle(
                color: AppColors.foreground.withValues(alpha: 0.62),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            // --- المعالجة الشرطية المتقدمة لواجهة المستخدم (Conditional UI) ---
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_items.isEmpty)
              const EmptyState(
                icon: Icons.inbox_outlined,
                message: 'لا توجد طلبات حالياً',
              )
            else
              ..._items.map(
                (request) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    request.lawyerName,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    request.lawyerSpecialty,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.foreground
                                          .withValues(alpha: 0.62),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _statusChip(request.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // حاوية كرت ملخص تفاصيل نوع القضية والمواعيد المطلوب جدولتها
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _miniRow('نوع القضية', request.caseType),
                              _miniRow(
                                'نوع الاستشارة',
                                request.consultationType,
                              ),
                              _miniRow(
                                'الموعد المطلوب',
                                '${request.preferredDate} - ${request.preferredTime}',
                              ),
                              if (request.price != null)
                                _miniRow(
                                  'الرسوم',
                                  '${request.price} ر.س',
                                  highlight: true,
                                ),
                              if ((request.decisionAt ?? '').isNotEmpty)
                                _miniRow(
                                  'تاريخ القرار',
                                  request.decisionAt!,
                                ),
                            ],
                          ),
                        ),
                        // بطاقة عرض الملاحظات التفاوضية أو التعليمات المرسلة من المحامي للطالب (تظهر شرطياً عند وجودها)
                        if (request.negotiationNote != null &&
                            request.negotiationNote!.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              request.negotiationNote!,
                              textAlign: TextAlign.right,
                              style: const TextStyle(height: 1.6),
                            ),
                          ),
                        ],
                        // بطاقة عرض مسببات رفض الطلب الصريحة لحفظ حق الشفافية للطالب (تظهر شرطياً فقط عند الرفض)
                        if (request.rejectionReason != null &&
                            request.rejectionReason!.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              border: Border.all(
                                color: const Color(0xFFFECACA),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'سبب الرفض',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.destructive,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  request.rejectionReason!,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(height: 1.6),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                text: 'التفاصيل',
                                onPressed: () => _openDetails(request),
                              ),
                            ),
                            // ميزة أمان منطقية صارمة: حظر إظهار أزرار الدفع الإلكتروني إلا إذا كان الطلب مقبولاً أو قيد التفاوض النشط
                            if (request.status == 'accepted' ||
                                request.status == 'negotiating') ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: PrimaryButton(
                                  text: 'الدفع',
                                  onPressed: () => _goToPayment(request),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// دالة إدارة وتوليد كبسولات وأوسمة الحالات (Status Chips)؛ تقوم بفرز الحالات برمجياً وتلوينها بصرياً وتزويدها بالأيقونة الملائمة
  Widget _statusChip(String status) {
    switch (status) {
      case 'pending':
        return const InfoChip(
          label: 'قيد الانتظار',
          background: Color(0xFFFFF7ED),
          foreground: Color(0xFFC2410C),
          icon: Icons.schedule,
        );
      case 'accepted':
        return const InfoChip(
          label: 'مقبول',
          background: Color(0xFFEAF8EE),
          foreground: AppColors.success,
          icon: Icons.check_circle,
        );
      case 'rejected':
        return const InfoChip(
          label: 'مرفوض',
          background: Color(0xFFFEE2E2),
          foreground: AppColors.destructive,
          icon: Icons.cancel,
        );
      case 'negotiating':
        return const InfoChip(
          label: 'قيد التفاوض',
          background: Color(0xFFEFF6FF),
          foreground: AppColors.primary,
          icon: Icons.gavel,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// سطر بناء ملخص الحقل المصغر؛ يفصل التسمية عن القيمة بمحاذاة مرنة وقابلة لإعادة الاستخدام داخل الكرت
  Widget _miniRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: highlight ? AppColors.primary : AppColors.foreground,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: AppColors.foreground.withValues(alpha: 0.58),
            ),
          ),
        ],
      ),
    );
  }
}

/// كلاس من نوع StatelessWidget يمثل لوحة المراجعة المنبثقة من الأسفل لاستعراض تفاصيل مشكلة الطالب القانونية كاملة.
/// يعتمد عليها هندسياً لتخفيف البيانات وضغط الذاكرة الرسومية عن الكروت الرئيسية، وعرض الحقول التفصيلية بوضوح تام للعميل.
class _RequestDetailsSheet extends StatelessWidget {
  final RequestItem request;

  const _RequestDetailsSheet({required this.request});

// توطين وترجمة الحقول الصارمة لنصوص عربية صريحة باللوحة
  String _statusLabel() {
    switch (request.status) {
      case 'accepted':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'negotiating':
        return 'قيد التفاوض';
      default:
        return 'قيد الانتظار';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 100),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Center(
              child: SizedBox(
                width: 50,
                child: Divider(thickness: 4),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              request.lawyerName,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              request.description,
              textAlign: TextAlign.right,
              style: const TextStyle(height: 1.7),
            ),
            const SizedBox(height: 16),
            Text(
              'نوع القضية: ${request.caseType}',
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            Text(
              'نوع الاستشارة: ${request.consultationType}',
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            Text(
              'الحالة: ${_statusLabel()}',
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            Text(
              'تم الإرسال: ${request.submittedAt}',
              textAlign: TextAlign.right,
            ),
            if ((request.decisionAt ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'تاريخ القرار: ${request.decisionAt}',
                textAlign: TextAlign.right,
              ),
            ],
            if (request.price != null) ...[
              const SizedBox(height: 8),
              Text(
                'الرسوم: ${request.price} ر.س',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
            if (request.negotiationNote != null &&
                request.negotiationNote!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  request.negotiationNote!,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
            if (request.rejectionReason != null &&
                request.rejectionReason!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'سبب الرفض:\n${request.rejectionReason!}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(height: 1.6),
                ),
              ),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'إغلاق',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
