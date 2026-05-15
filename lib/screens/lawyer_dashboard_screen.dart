import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';
import '../data/mock_data.dart';
import '../models/legal_case.dart';
import '../models/request_item.dart';
import '../services/requests_service.dart';
import '../services/session_service.dart';
import '../models/lawyer.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // مكتبة الفايربيس الأساسية لإدارة قواعد البيانات اللحظية والـ Streams

/// كلاس من نوع StatefulWidget يمثل اللوحة الرئيسية والتحكم الشاملة الخاصة بالمحامي.
/// يقوم الكلاس بتهيئة الخدمات الحية وإدارة الحالات المتغيرة ديناميكياً بالواجهة،
/// مثل تتبع عداد الإشعارات غير المقروءة، وإدارة العمليات اللحظية بداخل الشاشة
class LawyerDashboardScreen extends StatefulWidget {
  const LawyerDashboardScreen({super.key});

  @override
  State<LawyerDashboardScreen> createState() => _LawyerDashboardScreenState();
}

class _LawyerDashboardScreenState extends State<LawyerDashboardScreen> {
  final AuthService _authService = AuthService();
  Lawyer? lawyer; // كائن لحفظ بيانات المحامي الحالي المسجل دخوله
  final RequestsService _requestsService = RequestsService();

// مصفوفة كائنات الإحصائيات الأربعة المعروضة بأعلى لوحة التحكم
  final List<_LawyerStat> stats = [
    _LawyerStat(
      label: 'الاستشارات',
      value: '24',
      color: Color(0xFF3B82F6),
      icon: Icons.calendar_today_outlined,
    ),
    _LawyerStat(
      label: 'القضايا',
      value: '5',
      color: Color(0xFF10B981),
      icon: Icons.folder_open_outlined,
    ),
    _LawyerStat(
      label: 'التقييم',
      value: '4.9',
      color: Color(0xFFF59E0B),
      icon: Icons.star_border_rounded,
    ),
    _LawyerStat(
      label: 'الطلبات الجديدة',
      value: '5',
      color: Color(0xFF8B5CF6),
      icon: Icons.notifications_active_outlined,
    ),
  ];

// مصفوفة بيانات المواعيد القادمة اليوم وغداً
  final List<_Appointment> upcomingAppointments = const [
    _Appointment(
      id: '1',
      client: 'محمد أحمد',
      type: 'استشارة عن بعد',
      time: '10:00 صباحاً',
      date: 'اليوم',
      urgent: true,
    ),
    _Appointment(
      id: '2',
      client: 'فاطمة سعيد',
      type: 'حضوري',
      time: '02:00 مساءً',
      date: 'اليوم',
      urgent: false,
    ),
    _Appointment(
      id: '3',
      client: 'عبدالله خالد',
      type: 'هاتفي',
      time: '04:30 مساءً',
      date: 'غداً',
      urgent: false,
    ),
  ];
  // دالة ذكية لحقن بيانات القضايا التجريبية في الفايربيس لضمان عدم ظهور الشاشة فارغة بالمناقشة
  Future<void> _seedLawyerCases() async {
    final CollectionReference casesRef =
        FirebaseFirestore.instance.collection('lawyerCases');

    final existing = await casesRef.get();
    if (existing.docs.isNotEmpty)
      return; // إذا كانت البيانات موجودة مسبقاً، نوقف الدالة فوراً منعاً للتكرار

    final List<Map<String, dynamic>> cases = [
      {
        'title': 'نزاع عقاري',
        'client': 'أحمد السديري',
        'status': 'نشطة',
        'progress': 65.0,
        'lawyerName': 'نورة العتيبي',
        'timestamp': FieldValue.serverTimestamp()
      },
      {
        'title': 'مطالبة مالية',
        'client': 'شركة الرواد',
        'status': 'مكتملة',
        'progress': 100.0,
        'lawyerName': 'نورة العتيبي',
        'timestamp': FieldValue.serverTimestamp()
      },
      {
        'title': 'جريمة معلوماتية',
        'client': 'نورة العلي',
        'status': 'جديدة',
        'progress': 15.0,
        'lawyerName': 'نورة العتيبي',
        'timestamp': FieldValue.serverTimestamp()
      },
      {
        'title': 'أحوال شخصية',
        'client': 'سارة عبدالله',
        'status': 'نشطة',
        'progress': 40.0,
        'lawyerName': 'نورة العتيبي',
        'timestamp': FieldValue.serverTimestamp()
      },
      {
        'title': 'مراجعة عقد توريد',
        'client': 'مؤسسة الأفق',
        'status': 'جديدة',
        'progress': 10.0,
        'lawyerName': 'نورة العتيبي',
        'timestamp': FieldValue.serverTimestamp()
      },
    ];

    for (var c in cases) {
      await casesRef.add(c); // إضافة المستندات تلو الآخر لجدول الفايربيس
    }
  }

  late final List<_PendingRequest> _pendingRequests;
  final Set<String> _viewedRequestIds = <String>{};

// مجموعة فريدة (Set) لتتبع وحفظ الأرقام المعرفية للطلبات التي قام المحامي بالاطلاع على تفاصيلها
  late List<_LawyerNotificationItem> _notifications;
  int _unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _seedNotifications();
    _loadLawyerData();
    _seedLawyerCases();

// إعداد عينات طلبات الطلاب الواردة بانتظار قرار المحامي
    _pendingRequests = <_PendingRequest>[
      const _PendingRequest(
        id: '1',
        client: 'نورة عبدالله',
        caseType: 'قضية أسرية',
        note: 'أحتاج استشارة عاجلة حول حضانة الأطفال.',
        consultationType: 'استشارة عن بعد',
        preferredDate: '2026-04-10',
        preferredTime: '11:00 صباحاً',
        budget: '350',
        attachmentsCount: 2,
        details:
            'العميلة تطلب استشارة عاجلة بخصوص حضانة الأطفال بعد خلاف أسري قائم. يوجد مستندان مرفقان، وتحتاج إلى توضيح قانوني أولي وخطوات الإجراء المناسبة.',
        lawyerName: 'د. سارة العلي',
        lawyerSpecialty: 'قانون الأسرة',
        description:
            'استشارة عاجلة حول حضانة الأطفال وإجراءات المتابعة القانونية.',
      ),
      const _PendingRequest(
        id: '2',
        client: 'شركة الأفق',
        caseType: 'نزاع تجاري',
        note: 'مراجعة عقد شراكة وتحديد المخاطر النظامية.',
        consultationType: 'حضوري',
        preferredDate: '2026-04-11',
        preferredTime: '02:30 مساءً',
        budget: '1200',
        attachmentsCount: 1,
        details:
            'الطلب مقدم من شركة ترغب في مراجعة عقد شراكة جديد، وتحليل البنود التي قد تسبب مخاطر نظامية أو نزاعات مستقبلية، مع إبداء الرأي القانوني قبل التوقيع.',
        lawyerName: 'د. أحمد محمد',
        lawyerSpecialty: 'القانون التجاري',
        description: 'مراجعة عقد شراكة وتحليل المخاطر النظامية قبل التوقيع.',
      ),
    ];

    _seedRequestsIfNeeded();
    _seedNotifications();
  }

// جلب بيانات المحامي الحالي وتحديث حالة الواجهة بناءً عليها
  Future<void> _loadLawyerData() async {
    final user = await _authService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        lawyer = Lawyer.fromMap(user.toMap());
      });
    }
  }

// توليد قائمة إشعارات وهمية منوعة للمحامي لمحاكاة حركة النظام اللحظية
  void _seedNotifications() {
    _notifications = [
      const _LawyerNotificationItem(
        title: 'تحديث في قضية عمالية',
        body: 'سارة عبدالله بانتظار استشارتك حول تأخر المستحقات المالية.',
        time: 'الآن',
        icon: Icons.assignment_late_outlined,
        type: _LawyerNotificationType.request,
        isUnread: true,
      ),
      const _LawyerNotificationItem(
        title: 'قضية مكتملة',
        body: 'تم أرشفة قضية "مراجعة عقد توريد" بنجاح.',
        time: 'منذ يومين',
        icon: Icons.check_circle_outline,
        type: _LawyerNotificationType.system,
        isUnread: false,
      ),
      const _LawyerNotificationItem(
        title: 'تذكير بموعد قريب',
        body: 'لديك موعد اليوم الساعة 10:00 صباحاً مع محمد أحمد.',
        time: 'قبل 35 دقيقة',
        icon: Icons.calendar_month_rounded,
        type: _LawyerNotificationType.appointment,
        isUnread: true,
      ),
      const _LawyerNotificationItem(
        title: 'إشعار من النظام',
        body: 'تم تحديث لوحة التحكم وإضافة تحسينات جديدة للأداء.',
        time: 'أمس',
        icon: Icons.notifications_active_outlined,
        type: _LawyerNotificationType.system,
        isUnread: false,
      ),
    ];

    _unreadNotificationsCount = _notifications
        .where((item) => item.isUnread)
        .length; // حساب عدد الإشعارات غير المقروءة ديناميكياً
  }

  Future<void> _seedRequestsIfNeeded() async {
    final current = await _requestsService.fetchRequests();
    if (current.isNotEmpty) return;

    for (final request in _pendingRequests) {
      await _requestsService.addRequest(
        RequestItem(
          id: request.id,
          lawyerName: request.lawyerName,
          lawyerSpecialty: request.lawyerSpecialty,
          consultationType: request.consultationType,
          preferredDate: request.preferredDate,
          preferredTime: request.preferredTime,
          caseType: request.caseType,
          description: request.description,
          status: 'pending',
          submittedAt: '2026-04-06 09:30',
          price: request.budget,
        ),
      );
    }
  }

// دالة تسجيل الخروج وتطهير الجلسة الحالية والتحويل لشاشة الدخول
  Future<void> _logout() async {
    await SessionService().clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

// فتح لوحة الإشعارات المنبثقة من الأسفل وتصفير عداد غير المقروء فور الفتح لراحة المستخدم
  void _openNotificationsSheet() {
    final hadUnread = _notifications.any((item) => item.isUnread);

    if (hadUnread) {
      setState(() {
        _notifications = _notifications
            .map((item) => item.copyWith(isUnread: false))
            .toList();
        _unreadNotificationsCount = 0;
      });
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LawyerNotificationsHeader(
                  unreadCount: _unreadNotificationsCount,
                  totalCount: _notifications.length,
                ),
                const SizedBox(height: 14),
                if (_notifications.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      'لا توجد إشعارات حالياً',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 520),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _notifications[index];
                        return _LawyerNotificationCard(item: item);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

// فتح نافذة تفاصيل الطلب وتسجيل الـ ID الخاص به كمقروء ومطلع عليه لتفعيل أزرار القرار
  Future<void> _openRequestDetails(_PendingRequest request) async {
    _viewedRequestIds
        .add(request.id); // حقن المعرف الفرعي في الـ Set كمطلع عليه

    if (!mounted) return;
    setState(
        () {}); // إعادة بناء الواجهة لتتحول البطاقة إلى حالة "تم الاطلاع" باللون الأزرق

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تفاصيل الطلب #${request.id}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'اسم العميل', value: request.client),
                _DetailRow(label: 'نوع القضية', value: request.caseType),
                _DetailRow(
                  label: 'نوع الاستشارة',
                  value: request.consultationType,
                ),
                _DetailRow(
                  label: 'التاريخ المفضل',
                  value: request.preferredDate,
                ),
                _DetailRow(
                  label: 'الوقت المفضل',
                  value: request.preferredTime,
                ),
                _DetailRow(label: 'الميزانية', value: '${request.budget} ر.س'),
                _DetailRow(
                  label: 'عدد المرفقات',
                  value: '${request.attachmentsCount}',
                ),
                const SizedBox(height: 10),
                const Text(
                  'وصف الطلب',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  request.note,
                  style: TextStyle(
                    color: AppColors.foreground.withValues(alpha: 0.8),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'تفاصيل إضافية',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  request.details,
                  style: TextStyle(
                    color: AppColors.foreground.withValues(alpha: 0.8),
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

// دالة تأكيد قبول الطلب وتحديث حالته بجدول الخدمة
  Future<void> _confirmAccept({
    required _PendingRequest request,
  }) async {
    if (!_viewedRequestIds.contains(request.id)) {
      _showActionSnackBar(
        'يجب الاطلاع على تفاصيل الطلب أولًا قبل القبول أو الرفض.',
        isError: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('تأكيد قبول الطلب'),
              content: Text('هل أنت متأكد من قبول طلب ${request.client}؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('تأكيد القبول'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;
// تحديث البيانات في السيرفر الرسمي
    await _requestsService.updateRequestStatus(
      requestId: request.id,
      status: 'accepted',
      decisionAt: DateTime.now().toString(),
      price: request.budget,
      negotiationNote:
          'تم قبول طلبك من المحامي. يمكنك الآن إكمال الدفع لتأكيد الموعد.',
    );

    setState(() {
      _pendingRequests.removeWhere((item) => item.id == request.id);
      _viewedRequestIds.remove(request.id); // مسحه محلياً من قائمة الانتظار
    });

    _showActionSnackBar(
      'تم قبول الطلب رقم ${request.id} بنجاح وإشعار المستخدم بذلك.',
    );
  }

// فتح نافذة الرفض مع حقل نصي إجباري لكتابة السبب وإرساله للعميل
  Future<void> _showRejectReasonDialog({
    required _PendingRequest request,
  }) async {
    if (!_viewedRequestIds.contains(request.id)) {
      _showActionSnackBar(
        'يجب الاطلاع على تفاصيل الطلب أولًا قبل القبول أو الرفض.',
        isError: true,
      );
      return;
    }

    final TextEditingController reasonController = TextEditingController();
    String? validationError;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // استخدام StatefulBuilder لإدارة حالة الـ Validation بشكل مستقل وسريع داخل الـ Dialog
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              title: const Text('رفض الطلب'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'يرجى كتابة سبب الرفض ليتم إرساله إلى المستخدم.',
                    style: TextStyle(
                      color: AppColors.foreground.withValues(alpha: 0.75),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'اكتب سبب الرفض هنا...',
                      errorText:
                          validationError, // عرض خطأ الـ Validation باللون الأحمر إذا كان الحقل فارغاً
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) {
                      setInnerState(() {
                        validationError = 'يرجى كتابة سبب الرفض';
                      });
                      return;
                    }
                    Navigator.pop(context, reason);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('إرسال الرفض'),
                ),
              ],
            );
          },
        );
      },
    );

    reasonController.dispose();

    if (result == null || result.trim().isEmpty) return;
// رفع سبب الرفض للفايربيس وتحديث حالة المستند
    await _requestsService.updateRequestStatus(
      requestId: request.id,
      status: 'rejected',
      decisionAt: DateTime.now().toString(),
      rejectionReason: result.trim(),
      negotiationNote: null,
    );

    setState(() {
      _pendingRequests.removeWhere((item) => item.id == request.id);
      _viewedRequestIds.remove(request.id);
    });

    _showActionSnackBar(
      'تم رفض الطلب رقم ${request.id} وإرسال سبب الرفض للمستخدم.',
    );
  }

  void _showActionSnackBar(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.destructive : null,
          behavior: SnackBarBehavior.floating,
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
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(
              Icons.menu_rounded,
              color: Colors.white,
            ),
          ),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.balance, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'محاميك',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: _LawyerNotificationBellButton(
              count: _unreadNotificationsCount,
              onTap: _openNotificationsSheet,
            ),
          ),
        ],
      ),
      drawer: _LawyerDrawer(onLogout: _logout),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // لوحة الترحيب العلوية بـ التدرج اللوني الجذاب ومؤشر حالة الحساب الفعلي للمحامي
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xCC123458)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              // حذفنا const من هنا ليعمل الربط الديناميكي
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً م. ${lawyer?.name ?? 'المحامي'} 👋',
                  style: const TextStyle(
                    color: AppColors.background,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                // إضافة الوسام (Badge) الملون بناءً على حالة الحساب
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (lawyer?.id != null)
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (lawyer?.id != null)
                          ? Colors.green.withValues(alpha: 0.5)
                          : Colors.orange.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    (lawyer?.id != null) ? 'حساب نشط ✅' : 'قيد المراجعة ⏳',
                    style: TextStyle(
                      color: (lawyer?.id != null)
                          ? Colors.white
                          : Colors.orangeAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'لديك 5 استشارات اليوم', // يمكنك لاحقاً ربط هذا الرقم بعدد الطلبات الحقيقي
                  style: const TextStyle(
                    color: Color(0xD9F1EFEC),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // شبكة الإحصائيات الأربعة (GridView)
          GridView.builder(
            itemCount: stats.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.08,
            ),
            itemBuilder: (context, index) {
              final stat = stats[index];
              return SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: stat.color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(stat.icon, color: Colors.white, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      stat.value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.foreground.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          const Text(
            'المواعيد القادمة',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 14),
          ...upcomingAppointments.map(
            (appointment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SectionCard(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.client,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            appointment.type,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  AppColors.foreground.withValues(alpha: 0.62),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: appointment.urgent
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            appointment.date,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: appointment.urgent
                                  ? const Color(0xFFB91C1C)
                                  : const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              appointment.time,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'القضايا الأخيرة',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.lawyerCases),
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // --- البث اللحظي الحي المستمر من قاعدة بيانات Cloud Firestore جلب وعرض القضايا ---
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('lawyerCases')
                .orderBy('timestamp', descending: true)
                .snapshots(), // التسمع اللحظي على السيرفر
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Text('خطأ في التحميل');
              if (snapshot.connectionState == ConnectionState.waiting)
                return const CircularProgressIndicator();

              final docs = snapshot.data?.docs ?? [];

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  // تحويل بيانات الفايربيس إلى كائن LegalCase مع إضافة الحقول المطلوبة
                  final caseItem = LegalCase(
                    id: doc.id,
                    title: data['title'] ?? 'بدون عنوان',
                    client: data['client'] ?? 'عميل مجهول',
                    status: data['status'] ?? 'جديدة',
                    type: 'قضية', // هذا هو الحقل الناقص الأول (type)
                    progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
                    updatedAt: DateTime.now()
                        .toString(), // الحقل الناقص الثاني (updatedAt)
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _RecentCaseCard(caseItem: caseItem),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الطلبات الجديدة',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_pendingRequests.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_pendingRequests.isEmpty)
            const SectionCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'لا توجد طلبات جديدة حاليًا',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            )
          else
            ..._pendingRequests.map(
              (request) {
                final hasViewed = _viewedRequestIds.contains(request.id);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.client,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    request.caseType,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.foreground
                                          .withValues(alpha: 0.62),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEDD5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'قيد الانتظار',
                                    style: TextStyle(
                                      color: Color(0xFF9A3412),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (hasViewed)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDBEAFE),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'تم الاطلاع',
                                      style: TextStyle(
                                        color: Color(0xFF1D4ED8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          request.note,
                          style: TextStyle(
                            color: AppColors.foreground.withValues(alpha: 0.72),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openRequestDetails(request),
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('التفاصيل'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // نص ارشادي ذكي يتغير لونه وحالته لتنبيه المحامي بضرورة الاطلاع أولاً
                        Text(
                          hasViewed
                              ? 'يمكنك الآن اتخاذ القرار.'
                              : 'يجب فتح التفاصيل أولًا قبل القبول أو الرفض.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: hasViewed
                                ? AppColors.success
                                : AppColors.destructive,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                text: 'قبول',
                                onPressed: hasViewed
                                    ? () => _confirmAccept(request: request)
                                    : null,
                                backgroundColor: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SecondaryButton(
                                text: 'رفض',
                                onPressed: hasViewed
                                    ? () => _showRejectReasonDialog(
                                          request: request,
                                        )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// --- بقية ويدجت الواجهة المساعدة والثابتة للهيكل البصري الشاشة ---
class _LawyerNotificationBellButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _LawyerNotificationBellButton({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayCount = count > 99 ? '99+' : '$count';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Center(
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              if (count > 0)
                PositionedDirectional(
                  top: 6,
                  end: 4,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 19,
                      minHeight: 19,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.primary, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      displayCount,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LawyerNotificationsHeader extends StatelessWidget {
  final int unreadCount;
  final int totalCount;

  const _LawyerNotificationsHeader({
    required this.unreadCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withValues(alpha: 0.10),
          child: const Icon(
            Icons.notifications_active_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الإشعارات والرسائل',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                unreadCount > 0
                    ? 'لديك $unreadCount إشعار غير مقروء من أصل $totalCount'
                    : 'تمت قراءة جميع الإشعارات',
                style: TextStyle(
                  color: AppColors.foreground.withValues(alpha: 0.65),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LawyerNotificationCard extends StatelessWidget {
  final _LawyerNotificationItem item;

  const _LawyerNotificationCard({required this.item});

  Color _iconBackground() {
    switch (item.type) {
      case _LawyerNotificationType.message:
        return const Color(0xFFE8F0FE);
      case _LawyerNotificationType.request:
        return const Color(0xFFEAF8EE);
      case _LawyerNotificationType.appointment:
        return const Color(0xFFFFF4E5);
      case _LawyerNotificationType.system:
        return const Color(0xFFF3E8FF);
    }
  }

  Color _iconColor() {
    switch (item.type) {
      case _LawyerNotificationType.message:
        return AppColors.primary;
      case _LawyerNotificationType.request:
        return AppColors.success;
      case _LawyerNotificationType.appointment:
        return const Color(0xFFB45309);
      case _LawyerNotificationType.system:
        return const Color(0xFF7C3AED);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.isUnread ? const Color(0xFFF8FBFF) : Colors.white,
        border: Border.all(
          color: item.isUnread ? const Color(0xFFD6E8FF) : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _iconBackground(),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: _iconColor()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (item.isUnread)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.body,
                  style: TextStyle(
                    color: AppColors.foreground.withValues(alpha: 0.72),
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.time,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.foreground.withValues(alpha: 0.50),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LawyerDrawer extends StatelessWidget {
  final Future<void> Function() onLogout;

  const _LawyerDrawer({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.card,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.background,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'محامي',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'lawyer@test.com',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.foreground.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _DrawerItem(
                icon: Icons.home_outlined,
                title: 'الرئيسية',
                onTap: () => Navigator.popAndPushNamed(
                  context,
                  AppRoutes.lawyerDashboard,
                ),
              ),
              _DrawerItem(
                icon: Icons.person_outline,
                title: 'الملف الشخصي',
                onTap: () => Navigator.popAndPushNamed(
                  context,
                  AppRoutes.lawyerProfile,
                ),
              ),
              _DrawerItem(
                icon: Icons.description_outlined,
                title: 'القضايا',
                onTap: () => Navigator.popAndPushNamed(
                  context,
                  AppRoutes.lawyerCases,
                ),
              ),
              _DrawerItem(
                icon: Icons.smart_toy_outlined,
                title: 'المستشار القانوني الذكي',
                onTap: () => Navigator.popAndPushNamed(
                  context,
                  AppRoutes.lawyerAiChat,
                ),
              ),
              const Spacer(),
              _DrawerItem(
                icon: Icons.logout,
                title: 'تسجيل الخروج',
                destructive: true,
                onTap: () async {
                  Navigator.pop(context);
                  await onLogout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.destructive : AppColors.foreground;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RecentCaseCard extends StatelessWidget {
  final LegalCase caseItem;

  const _RecentCaseCard({required this.caseItem});

  @override
  Widget build(BuildContext context) {
    Color badgeBackground;
    Color badgeForeground;
    if (caseItem.status == 'مكتملة') {
      badgeBackground = const Color(0xFFDCFCE7);
      badgeForeground = const Color(0xFF15803D);
    } else if (caseItem.status == 'نشطة') {
      badgeBackground = const Color(0xFFDBEAFE);
      badgeForeground = const Color(0xFF1D4ED8);
    } else {
      badgeBackground = const Color(0xFFFEF3C7);
      badgeForeground = const Color(0xFFB45309);
    }

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caseItem.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caseItem.client,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.foreground.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  caseItem.status,
                  style: TextStyle(
                    color: badgeForeground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'التقدم',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.foreground.withValues(alpha: 0.62),
                ),
              ),
              Text(
                '${caseItem.progress.toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: caseItem.progress / 100,
              minHeight: 8,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.4),
              color: caseItem.progress == 100
                  ? AppColors.success
                  : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: AppColors.foreground,
            fontSize: 14,
            height: 1.6,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// كلاس بيانات مصغر (Data Model) مستقل وخاص ببطاقات الإحصائيات العلوية.
/// فائدته البرمجية هي تطبيق مبدأ تنظيم وفصل البيانات (Data Separation)،
/// حيث يحدد القالب الهيكلي الثابت الذي يجمع خصائص كل بطاقة رقمية
/// (العنوان النصي، القيمة العددية، اللون البصري المخصص، والأيقونة المرافقة) قبل توزيعها بالـ GridView.
class _LawyerStat {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _LawyerStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
}

/// كلاس بيانات مصغر (Data Model) مخصص لتعريف بنية جدول "المواعيد القادمة" للمحامي.
/// يحدد الحقول الأساسية لكل موعد مجدول (المعرف الرقمي، اسم العميل، تصنيف المقابلة، التوقيت، والتاريخ)،
/// ويحتوي على متغير منطقي [urgent] لتمييز الطلبات الحرجة والطارئة بصرياً باللون الأحمر داخل الواجهة.
class _Appointment {
  final String id;
  final String client;
  final String type;
  final String time;
  final String date;
  final bool urgent;

  const _Appointment({
    required this.id,
    required this.client,
    required this.type,
    required this.time,
    required this.date,
    required this.urgent,
  });
}

/// كلاس بيانات تفصيلي يمثل القالب الكامل لـ "طلب الاستشارة الوارد قيد الانتظار" من الطلاب.
/// يجمع الحقول الكاملة للمشكلة القانونية (بيانات الطالب، الميزانية، نوع القضية، والوصف المشروح)،
/// ليعرضها للمحامي عند النقر على "التفاصيل"، ويُبنى عليه شرط إجبارية الاطلاع قبل اتخاذ قرار القبول أو الرفض.
class _PendingRequest {
  final String id;
  final String client;
  final String caseType;
  final String note;
  final String consultationType;
  final String preferredDate;
  final String preferredTime;
  final String budget;
  final int attachmentsCount;
  final String details;
  final String lawyerName;
  final String lawyerSpecialty;
  final String description;

  const _PendingRequest({
    required this.id,
    required this.client,
    required this.caseType,
    required this.note,
    required this.consultationType,
    required this.preferredDate,
    required this.preferredTime,
    required this.budget,
    required this.attachmentsCount,
    required this.details,
    required this.lawyerName,
    required this.lawyerSpecialty,
    required this.description,
  });
}

enum _LawyerNotificationType {
  message,
  request,
  appointment,
  system,
}

/// كلاس بيانات متقدم مخصص لصياغة بنية الإشعارات والرسائل الواردة للمحامي وتصنيف أنواعها.
/// تكمن ميزته البرمجية في احتوائه على دالة [copyWith] الاحترافية، والتي تسمح بنسخ كائن الإشعار
/// وتحديث حالة واحدة فقط فيه (مثل تحويله من غير مقروء إلى مقروء) فور فتح القائمة دون تدمير بقية البيانات.
class _LawyerNotificationItem {
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final _LawyerNotificationType type;
  final bool isUnread;

  const _LawyerNotificationItem({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.type,
    required this.isUnread,
  });

  _LawyerNotificationItem copyWith({
    String? title,
    String? body,
    String? time,
    IconData? icon,
    _LawyerNotificationType? type,
    bool? isUnread,
  }) {
    return _LawyerNotificationItem(
      title: title ?? this.title,
      body: body ?? this.body,
      time: time ?? this.time,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      isUnread: isUnread ?? this.isUnread,
    );
  }
}
