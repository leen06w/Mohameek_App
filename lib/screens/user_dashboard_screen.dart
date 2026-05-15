import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';
import '../data/mock_data.dart';
import '../models/app_user.dart';
import '../models/lawyer.dart';
import '../models/request_item.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // مكتبة الفايربيس لإدارة الأرشفة وقنوات البث الحي المستمر Streams
import 'package:firebase_auth/firebase_auth.dart'; // مكتبة التحقق من هوية وحساب العميل الحالي النشط

/// كلاس من نوع StatefulWidget يمثل اللوحة الرئيسية والمركزية للمستخدم / الطالب.
/// يتولى الكلاس مزامنة بيانات حساب الطالب، وإدارة لوحة الاختصارات الشبكية السريعة، وعرض المحامين والقضايا الحية وبث المواعيد.
class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

/// كلاس الحالة الديناميكي المسؤول عن معالجة تدفق قنوات البث الحية (Streams)، وفتح النوافذ المنبثقة الجانبية والسفلية، وإدارة المحادثات.
class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final AuthService _authService =
      AuthService(); // استدعاء خدمة الصلاحيات والمصادقة
  AppUser? user; // كائن من موديل AppUser لحفظ بيانات الطالب النشط حالياً

  late List<_UserNotificationItem>
      _notifications; // مصفوفة لتخزين قائمة الإشعارات
  int _unreadNotificationsCount =
      0; // عداد رقمي لحساب الإشعارات غير المقروءة باللون الأحمر

  @override
  void initState() {
    super.initState();
    _seedNotifications(); // تهيئة قائمة الإشعارات الافتراضية
    _loadUser(); // بدء مزامنة وجلب بيانات الطالب المحدثة من الفايربيس
  }

// حقل عينات إشعارات وهمية لمحاكاة حركة النظام الحية داخل التطبيق
  void _seedNotifications() {
    _notifications = [
      const _UserNotificationItem(
        title: 'رسالة جديدة من المحامي',
        body: 'تم الرد على استفسارك بخصوص القضية التجارية.',
        time: 'الآن',
        icon: Icons.mark_chat_unread_rounded,
        type: _NotificationType.message,
        isUnread: true,
      ),
      const _UserNotificationItem(
        title: 'تم تحديث حالة الطلب',
        body: 'تم قبول طلبك ويمكنك الآن إكمال عملية الدفع.',
        time: 'قبل 10 دقائق',
        icon: Icons.check_circle_rounded,
        type: _NotificationType.request,
        isUnread: true,
      ),
      const _UserNotificationItem(
        title: 'تذكير بموعدك القادم',
        body: 'لديك موعد استشارة غدًا الساعة 10:00 صباحًا.',
        time: 'قبل ساعة',
        icon: Icons.calendar_month_rounded,
        type: _NotificationType.appointment,
        isUnread: true,
      ),
      const _UserNotificationItem(
        title: 'تنبيه من النظام',
        body: 'تم تحديث سياسة الخصوصية داخل التطبيق.',
        time: 'أمس',
        icon: Icons.notifications_active_rounded,
        type: _NotificationType.system,
        isUnread: false,
      ),
    ];

    _unreadNotificationsCount = _notifications
        .where((item) => item.isUnread)
        .length; // حساب عدد غير المقروء ديناميكياً
  }

  /// دالة المزامنة الثنائية غير المتزامنة؛ تقرأ جلسة المستخدم ثم تسحب بياناته الحية (مثل الاسم الحقيقي المحدث) من الـ Firestore
  Future<void> _loadUser() async {
    // 1. جلب المستخدم من الجلسة الحالية
    final u =
        await _authService.getCurrentUser(); // 1. فحص الجلسة الحالية الآمنة
    if (u == null) return;

    // 2. جلب البيانات المحدثة (مثل الاسم الحقيقي) من Firestore
    try {
      // 2. سحب وثيقة العميل المحدثة من مجموعة المستخدمين بـ قاعدة البيانات
      final doc =
          await FirebaseFirestore.instance.collection('Users').doc(u.id).get();

      if (doc.exists && mounted) {
        setState(() {
          user = AppUser(
            id: u.id,
            name: doc.data()?['name'] ?? u.name, // يأخذ الاسم من الفايربيس
            email: u.email,
            phone: doc.data()?['phone'] ?? u.phone,
            city: doc.data()?['city'] ?? u.city,
            address: doc.data()?['address'] ?? u.address,
            role: doc.data()?['role'] ?? 'user',
          );
        });
      } else if (mounted) {
        setState(() => user =
            u); // كخطة بديلة نعتمد بيانات الجلسة المحلية إذا لم تتوفر شبكة
      }
    } catch (e) {
      if (mounted) setState(() => user = u);
    }
  }

// فتح ورقة الإشعارات السفلية المنبثقة وتصفير عداد غير المقروء محلياً فور الفتح لراحة العميل
  void _openNotificationsSheet() {
    final hadUnread = _notifications.any((item) => item.isUnread);

    if (hadUnread) {
      setState(() {
        _notifications = _notifications
            .map((item) => item.copyWith(
                isUnread:
                    false)) // تحويل كافة العناصر لمقروءة محلياً عبر copyWith
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
                _NotificationsHeader(
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
                        return _NotificationCard(item: item);
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

// فتح لوحة "اسأل محامي" السفلية؛ وتعمل بـ StreamBuilder تفاعلي يسحب قائمة المحامين المعتمدين والنشطين من السيرفر فوراً
  void _openAskLawyerSheet() {
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (context) {
          // بدلاً من MockData، نستخدم StreamBuilder لجلب المحامين الحقيقيين من الفايربيس
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .where('role',
                    isEqualTo:
                        'lawyer') // تصفية وضمان جلب الخبراء القانونيين فقط من جدول النظام
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // تحويل وثائق الفايربيس المسترجعة إلى قائمة كائنات محامين حقيقيين
              final lawyers = snapshot.data?.docs.map((doc) {
                    return Lawyer.fromMap(doc.data() as Map<String, dynamic>);
                  }).toList() ??
                  [];

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _SheetHeader(
                        title: 'اسأل محامي',
                        subtitle: 'اختر المحامي المناسب لبدء محادثة مباشرة معه',
                        icon: Icons.support_agent_outlined,
                      ),
                      const SizedBox(height: 14),
                      if (lawyers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('لا يوجد محامون متصلون حالياً'),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 460),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: lawyers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final lawyer = lawyers[index];
                              return _LawyerSelectionCard(
                                lawyer: lawyer,
                                onTap: () {
                                  Navigator.pop(context);
                                  _openLawyerChat(lawyer);
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        });
  }

// فتح شاشة غرفة المحادثة المباشرة الممررة وتزويدها باسم الطالب الحالي لتوثيق السجل
  void _openLawyerChat(Lawyer lawyer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _LawyerChatScreen(
          lawyer: lawyer,
          currentUserName: user?.name ?? 'مستخدم',
        ),
      ),
    );
  }

// فتح شيت "مواعيدي"؛ وبث طلبات وحالات الاستشارات والقرارات الصادرة من المحامي للطالب لحظة بلحظة عبر الـ Stream
  void _openAppointmentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // تمديد محاذاة اللوحة لتأخذ أبعاداً انسيابية ومريحة في العرض
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Cases')
                .where('userId',
                    isEqualTo: FirebaseAuth.instance.currentUser
                        ?.uid) // جلب الطلبات المطابقة للـ uid الفريد للطالب الحالي
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _SheetHeader(
                        title: 'مواعيدي',
                        subtitle: 'استعراض الطلبات والمواعيد الحالية بشكل منظم',
                        icon: Icons.event_note_outlined,
                      ),
                      const SizedBox(height: 14),

                      //  إذا كانت القائمة فارغة تظهر هذه الرسالة
                      if (docs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  color: Colors.grey[400], size: 50),
                              const SizedBox(height: 10),
                              const Text(
                                'لا توجد مواعيد أو طلبات حالية',
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.7,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: docs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final data =
                                  docs[index].data() as Map<String, dynamic>;
                              // تحويل البيانات لـ Item وعرضها
                              return _AppointmentCard(
                                request: RequestItem.fromJson(
                                    data), // تحويل مخرجات الـ Json لكائن الموديل ورسم بطاقته الملونة
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

// فتح واجهة شاشة الدعم والمساعدة المنعزلة بالأسفل
  void _openSupportScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _SupportHelpScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // معالجة صياغة اسم الترحيب وتجنب الفراغات العشوائية بالنظام
    final displayName =
        (user?.name.trim().isNotEmpty ?? false) ? user!.name.trim() : 'لين';

    return AppShell(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () =>
                Scaffold.of(context).openDrawer(), //فتح القائمه الجانبيه
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
            child: _NotificationBellButton(
              count: _unreadNotificationsCount,
              onTap: _openNotificationsSheet,
            ),
          ),
        ],
      ),
      drawer: _UserDrawer(
        user: user,
        onOpenSupport: _openSupportScreen,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً $displayName 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'كيف يمكننا مساعدتك اليوم؟',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.02,
            children: [
              _QuickAction(
                icon: Icons.search,
                title: 'البحث عن محامي',
                onTap: () => Navigator.pushNamed(context, AppRoutes.userSearch),
              ),
              _QuickAction(
                icon: Icons.send_outlined,
                title: 'طلباتي',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.userRequests),
              ),
              _QuickAction(
                icon: Icons.description_outlined,
                title: 'قضاياي',
                onTap: () => Navigator.pushNamed(context, AppRoutes.userCases),
              ),
              _QuickAction(
                title: 'استشارة AI',
                onTap: () => Navigator.pushNamed(context, AppRoutes.userAiChat),
                iconWidget: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/images/ai_avatar.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              _QuickAction(
                icon: Icons.calendar_month_outlined,
                title: 'مواعيدي',
                onTap: _openAppointmentsSheet,
              ),
              _QuickAction(
                icon: Icons.headset_mic_outlined,
                title: 'اسأل محامي',
                onTap: _openAskLawyerSheet,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'محامون مميزون',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.userSearch),
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // قراءة وعرض أول 3 عناصر من مصفوفة المحامين المتميزين
          ...MockData.lawyers.take(3).map(
                (lawyer) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _FeaturedLawyerCard(lawyer: lawyer),
                ),
              ),
          const SizedBox(height: 8),
          const Text(
            'القضايا الأخيرة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          // الـ StreamBuilder الحصري والموجه لمراقبة وتحديث قضايا الطالب الحالي المسجلة فقط بالفايربيس
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Cases')
                .where('studentId',
                    isEqualTo:
                        user?.id) // التصفية لضمان الخصوصية وسرية وثائق الطلاب
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('لا توجد قضايا حالية في حسابك'),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'انتظار';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['title'] ?? 'قضية بدون عنوان',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                              // هنا بنستخدم دالة الألوان اللي بنضيفها بعد شوي
                              _buildStatusBadge(status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                              'المحامي: ${data['lawyerName'] ?? 'لم يحدد بعد'}'),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value:
                                0.5, // تقدم فرضي لمؤشر شريط التقدم محاكاة للعميل
                            borderRadius: BorderRadius.circular(999),
                            backgroundColor: AppColors.secondary,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// دالة معالجة وتوليد ألوان كبسولات الحالات (Badges) بشكل منسق مع التفسير البصري (مكتملة، قيد المراجعة، انتظار)
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'مكتملة':
        bgColor = const Color(0xFFEAF8EE);
        textColor = const Color(0xFF2D6A4F);
        break;
      case 'قيد المراجعة':
      case 'انتظار':
        bgColor = const Color(0xFFEFF6FF);
        textColor = const Color(0xFF1E40AF);
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF374151);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

/// ويدجت من نوع StatelessWidget تمثل زر جرس الإشعارات العلوي المخصص لشريط التطبيق (AppBar).
/// تستخدم الـ [Stack] لتركيب طبقتين: أيقونة الجرس الأساسية بالخلفية، وفوقها دائرة التنبيه الحمراء الرقمية.
/// يتم التحكم بظهور الدائرة شرطياً (`if (count > 0)`) لتظهر فقط عند ورود إشعارات جديدة غير مقروءة للعميل.
class _NotificationBellButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _NotificationBellButton({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayCount = count > 99
        ? '99+'
        : '$count'; // تحويل الأعداد الكبيرة لصيغة 99+ لمنع تشويه التصميم

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
              if (count > 0) // عرض شارة التنبيه الرقمية الحمراء شرطياً
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

/// مكون مرئي ثابت يُمثّل ترويسة لوحة الإشعارات المنبثقة من الأسفل (BottomSheet).
/// يعرض أيقونة دائرية للتنبيهات النشطة بجانبها عنوان اللوحة وعدداً ديناميكياً محدثاً محلياً
/// يوضح للمستخدم عدد الإشعارات غير المقروءة المتبقية من إجمالي الإشعارات (`unreadCount` من أصل `totalCount`).
class _NotificationsHeader extends StatelessWidget {
  final int unreadCount;
  final int totalCount;

  const _NotificationsHeader({
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

/// بطاقة ذكية ومتحركة لتنسيق ورسم كل إشعار فردي داخل قائمة التنبيهات.
/// تستخدم الـ [AnimatedContainer] لعمل تأثير انتقال ناعم في لون الخلفية والحدود
/// عندما تتغير حالة الإشعار من غير مقروء (خلفية زرقاء خفيفة جداً) إلى مقروء (خلفية بيضاء نقية).
/// كما تحتوي على دوال مخصصة لتوزيع الألوان والخلفيات آلياً بناءً على نوع التصنيف.
class _NotificationCard extends StatelessWidget {
  final _UserNotificationItem item;

  const _NotificationCard({required this.item});
// تحديد خلفية أيقونة الإشعار حسب نوعه (رسالة، طلب، موعد، نظام)
  Color _iconBackground() {
    switch (item.type) {
      case _NotificationType.message:
        return const Color(0xFFE8F0FE);
      case _NotificationType.request:
        return const Color(0xFFEAF8EE);
      case _NotificationType.appointment:
        return const Color(0xFFFFF4E5);
      case _NotificationType.system:
        return const Color(0xFFF3E8FF);
    }
  }

// تحديد لون الأيقونة الصريح لضمان التباين البصري والـ Accessibility
  Color _iconColor() {
    switch (item.type) {
      case _NotificationType.message:
        return AppColors.primary;
      case _NotificationType.request:
        return AppColors.success;
      case _NotificationType.appointment:
        return const Color(0xFFB45309);
      case _NotificationType.system:
        return const Color(0xFF7C3AED);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(
          milliseconds: 180), // سرعة الأنيميشن اللطيف عند القراءة
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.isUnread
            ? const Color(0xFFF8FBFF)
            : Colors.white, // تمييز الإشعار غير المقروء بخلفية مخصصة
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

/// ويدجت برمجية تمثل "القائمة الجانبية الفخمة" المخصصة لحساب الطلاب والمستخدمين.
/// تعرض واجهة علوية دائرية لملف الحساب الشخصي وتستعرض بريده واسمه الحقيقي القادم من السيرفر.
/// كما تنظم روابط ومسارات التنقل الداخلية للبرنامج وتأمين دالة تسجيل الخروج وتطهير الجلسات تماماً.
class _UserDrawer extends StatelessWidget {
  final AppUser? user;
  final VoidCallback onOpenSupport;

  const _UserDrawer({
    required this.user,
    required this.onOpenSupport,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'مستخدم',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        user?.name ?? 'مستخدم',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DrawerItem(
                icon: Icons.home,
                title: 'الرئيسية',
                onTap: () => Navigator.popAndPushNamed(
                  context,
                  AppRoutes.userDashboard,
                ),
              ),
              _DrawerItem(
                icon: Icons.search,
                title: 'البحث',
                onTap: () => Navigator.popAndPushNamed(
                  context,
                  AppRoutes.userSearch,
                ),
              ),
              _DrawerItem(
                icon: Icons.settings,
                title: 'الإعدادات',
                onTap: () => Navigator.popAndPushNamed(
                  context,
                  AppRoutes.userSettings,
                ),
              ),
              _DrawerItem(
                icon: Icons.help_outline,
                title: 'الدعم والمساعدة',
                onTap: () {
                  Navigator.pop(context); // إغلاق الدروير أولاً لراحة الـ UX
                  onOpenSupport(); // فتح نافذة الدعم
                },
              ),
              const Spacer(),
              // كرت زر تسجيل الخروج التقني الذي يتلف الـ Route History تماماً أمنياً
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  await AuthService()
                      .logout(); // استدعاء خدمة تدمير الجلسة بـ الفايربيس
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (_) =>
                          false, // حذف وحجب شاشات الحساب السابقة نهائياً من ذاكرة الجوال
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// عنصر قائمة موحد وقابل لإعادة الاستخدام (Reusable Widget) لبناء أسطر خيارات القائمة الجانبية.
/// يضمن ثبات الأبعاد، الأيقونات، والخطوط بجميع أسطر الـ Drawer مجتمعة لتفادي تكرار الأكواد البصرية.
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}

/// كرت برمي من نوع StatelessWidget لبناء مربعات "الاختصارات الشبكية السريعة" في لوحة التحكم.
/// مغلف بـ [InkWell] لدعم تأثير النقر الدائري (Ripple Effect)، ويستقبل نص العنوان [title]
/// ويدعم ميزة ذكية لاستقبال أيقونة ثابتة [icon] أو عنصر مخصص بالكامل [iconWidget] (مثل أيقونة الـ AI المتحركة).
class _QuickAction extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String title;
  final VoidCallback onTap;

  const _QuickAction({
    this.icon,
    this.iconWidget,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // التحقق الشرطي لحقن الودجت المخصصة أو الأيقونة الافتراضية الممررة
    final Widget finalIconWidget = iconWidget ??
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.primary),
        );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: SectionCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            finalIconWidget,
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة عرض مخصصة لقائمة "المحامون المميزون" في لوحة تحكم الطالب.
/// تقوم بقراءة خصائص كائن المحامي [lawyer] وعرض نسب تقييمه الذهبية، تخصصاته، أسعار الجلسات، ومدينته.
/// وتحتوي بأسفلها على زر الحجز الفوري المباشر لنقله لرحلة جدولة المواعيد آلياً.
class _FeaturedLawyerCard extends StatelessWidget {
  final Lawyer lawyer;

  const _FeaturedLawyerCard({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lawyer.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lawyer.specialty,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.foreground.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
              // تصميم بطاقة التقييم النجمية الذهبية الصغيرة
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: Color(0xFFA16207),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${lawyer.rating}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFA16207),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${lawyer.cases} قضية',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.foreground.withValues(alpha: 0.6),
                ),
              ),
              Text(
                lawyer.city,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.foreground.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '${lawyer.price} ر.س',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            text: 'حجز استشارة',
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.userBooking,
              arguments:
                  lawyer, // تمرير كائن المحامي المختار كـ حجة Arguments لشاشة الحجز
            ),
          ),
        ],
      ),
    );
  }
}

/// ترويسة مرئية مشتركة وموحدة تم تصميمها لتنسيق الواجهات العلوية لكافة الـ BottomSheets السفلية باللوحة.
/// تستقبل الـ [title]، الـ [subtitle]، والأيقونة المخصصة لتوحيد شكل ومظهر أوراق المواعيد والمحادثات.
class _SheetHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SheetHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withValues(alpha: 0.10),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
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

/// بطاقة اختيار منسقة معروضة داخل قائمة "اسأل محامي".
/// تُظهر تفاصيل سريعة لكل محامي مسجل بالسيرفر لمساعدة الطالب في اتخاذ قراره السريع ببدء شات مباشر وآمن معه.
class _LawyerSelectionCard extends StatelessWidget {
  final Lawyer lawyer;
  final VoidCallback onTap;

  const _LawyerSelectionCard({
    required this.lawyer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lawyer.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lawyer.specialty,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.foreground.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lawyer.city} • ${lawyer.price} ر.س',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.foreground.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded),
          ],
        ),
      ),
    );
  }
}

/// بطاقة ذكية معروضة داخل لائحة المواعيد؛ تتلقى كائن بيانات طلب الاستشارة [request].
/// ميزتها الكبرى هي معالجة وتلوين كبسولات الحالات (Badges) محلياً وتلقائياً لتعكس قرارات الـ API القادمة
/// (مقبول ونشط باللون الأخضر، مرفوض بالأحمر، قيد التفاوض بالأصفر، بانتظار الإدارة بالأزرق).
class _AppointmentCard extends StatelessWidget {
  final RequestItem request;

  const _AppointmentCard({required this.request});
// تلوين نصوص الحالات لضمان جودة الرؤية الـ UI Contrast
  Color _statusBackground() {
    switch (request.status) {
      case 'accepted':
        return const Color(0xFFEAF8EE);
      case 'rejected':
        return const Color(0xFFFEE2E2);
      case 'negotiating':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFEFF6FF);
    }
  }

// دالة لتحديد لون النص الصريح داخل الكبسولة لضمان جودة التباين البصري (UI Contrast)
  Color _statusForeground() {
    switch (request.status) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.destructive;
      case 'negotiating':
        return const Color(0xFFB45309);
      default:
        return AppColors.primary;
    }
  }

// ترجمة وتوطين الحقول البرمجية لنصوص عربية واضحة ومفهومة للمستخدم
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.lawyerName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusBackground(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel(),
                  style: TextStyle(
                    color: _statusForeground(),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            request.caseType,
            style: TextStyle(
              color: AppColors.foreground.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 8),
          _DialogInfoRow(
            label: 'نوع الاستشارة',
            value: request.consultationType,
          ),
          _DialogInfoRow(label: 'التاريخ', value: request.preferredDate),
          _DialogInfoRow(label: 'الوقت', value: request.preferredTime),
          if ((request.price ?? '').isNotEmpty)
            _DialogInfoRow(label: 'الرسوم', value: '${request.price} ر.س'),
          if ((request.negotiationNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              request.negotiationNote!,
              style: TextStyle(
                color: AppColors.foreground.withValues(alpha: 0.75),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// مكون مخصص ومصغر يعتمد على الـ [RichText] و [TextSpan] لتنسيق وعرض أسطر البيانات.
/// يقوم بفصل عنوان الحقل (مثل نوع الاستشارة:) بـ وزن عريض جداً [FontWeight.w800]،
/// ويحقن بجانبه القيمة الحقيقية بوزن متوسط، لتظهر اللائحة بشكل هندسي منظم ومريح للعين.
class _DialogInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DialogInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: AppColors.foreground,
            fontSize: 14,
            height: 1.5,
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

/// كلاس من نوع StatefulWidget يمثل شاشة "غرفة المحادثة الحية والمباشرة مع المحامي".
/// يتولى إدارة رسائل الشات محلياً، ومحاكاة استقبال ردود الأفعال التلقائية والذكية من المحامي
/// عبر المؤقتات الزمنية [Future.delayed]، بالإضافة إلى التحكم بالانزلاق الآلي لقاع الشاشة عند المراسلة.
class _LawyerChatScreen extends StatefulWidget {
  final Lawyer lawyer;
  final String currentUserName;

  const _LawyerChatScreen({
    required this.lawyer,
    required this.currentUserName,
  });

  @override
  State<_LawyerChatScreen> createState() => _LawyerChatScreenState();
}

class _LawyerChatScreenState extends State<_LawyerChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final List<_ChatMessage>
      _messages; // مصفوفة حية لتخزين سجل رسائل الشات الحالية المعروضة

  @override
  void initState() {
    super.initState();
    // حقن رسالة ترحيبية آلية مشروحة من المحامي المختار فور فتح غرفة الشات لكسر الجمود مع العميل
    _messages = [
      _ChatMessage(
        text:
            'مرحبًا، أنا ${widget.lawyer.name}. يسعدني مساعدتك في ${widget.lawyer.specialty}. اكتب سؤالك وسأراجع تفاصيله معك.',
        isUser:
            false, // تعيين القيمة كـ false لأن مصدرها ليس المستخدم بل المحامي
        time: 'الآن',
      ),
    ];
  }

  @override
  void dispose() {
    // إغلاق الكنترولرز ومستمعي التمرير فور الخروج من المحادثة لحماية ذاكرة جهاز العميل
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// دالة إرسال الرسالة: تضيف نص الطالب للمصفوفة فوراً وتولد رداً آلياً محاكياً ومؤقتاً من طرف المحامي
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isUser: true,
          time: 'الآن',
        ),
      );
      _messageController.clear(); // تنظيف صندوق الكتابة فور الإرسال
    });

    _scrollToBottom();
// محاكاة تأخير زمني لمدة 500 ملي ثانية لظهور رد المحامي الافتراضي الذكي بالخلفية
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      setState(() {
        _messages.add(
          _ChatMessage(
            text:
                'تم استلام رسالتك. سأراجع استفسارك بخصوص "${widget.lawyer.specialty}" وأزوّدك برد أولي مناسب. يمكنك أيضًا إرفاق المستندات أو طلب موعد لاحقًا عند الحاجة.',
            isUser: false, // ترسم على اليسار باللون الأبيض لأنها من المحامي
            time: 'الآن',
          ),
        );
      });

      _scrollToBottom(); // إنزال الشاشة مجدداً لرؤية رد المحامي الوارد
    });
  }

  /// خوارزمية التمرير التلقائي: حركة ذكية تضمن انزلاق قائمة الرسائل لآخر سطر تلقائياً فور الورود (Auto-Scroll)
  void _scrollToBottom() {
    // استدعاء PostFrameCallback لضمان أن التمرير يحدث *بعد* رسم الرسالة الجديدة تماماً بالواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lawyer.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              widget.lawyer.specialty,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'المحادثة المباشرة مع ${widget.lawyer.name}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.isUser;

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 6),
                        bottomRight: Radius.circular(isUser ? 6 : 18),
                      ),
                      border:
                          isUser ? null : Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(
                            color: isUser ? Colors.white : AppColors.foreground,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          message.time,
                          style: TextStyle(
                            fontSize: 11,
                            color: isUser
                                ? Colors.white.withValues(alpha: 0.75)
                                : AppColors.foreground.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // شريط إدخال وإرسال الرسائل السفلي المحمي بالـ SafeArea
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 12,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالتك إلى المحامي...',
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// كلاس بيانات مصغر (Data Model) يمثل هيكل وبنية "الرسالة المفردة" المتبادلة داخل الشات.
/// يحدد الخصائص الصارمة لكل رسالة: نص الرسالة [text]، التوقيت [time]، وهيكلية الهوية [isUser] للفرز البصري.
class _ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class _SupportHelpScreen extends StatelessWidget {
  const _SupportHelpScreen();

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'الدعم والمساعدة',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xCC123458)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الدعم والمساعدة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'نحن هنا لمساعدتك',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'كيف يمكننا مساعدتك؟',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showMessage(context, 'سيتم فتح دليل المستخدم لاحقًا'),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('دليل المستخدم'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _showMessage(
                    context,
                    'سيتم فتح الفيديوهات التعليمية لاحقًا',
                  ),
                  icon: const Icon(Icons.ondemand_video_outlined),
                  label: const Text('فيديوهات تعليمية'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'الاتصال بالدعم',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 14),
                _SupportContactTile(
                  icon: Icons.chat_bubble_outline,
                  title: 'الدردشة المباشرة',
                  subtitle: 'تواصل معنا مباشرة',
                  onTap: () => _showMessage(
                    context,
                    'سيتم ربط الدردشة المباشرة مع فريق الدعم لاحقًا',
                  ),
                ),
                _SupportContactTile(
                  icon: Icons.email_outlined,
                  title: 'دعم البريد الإلكتروني',
                  subtitle: 'support@mahamik.app',
                  onTap: () => _showMessage(
                    context,
                    'البريد الحالي: support@mahamik.app',
                  ),
                ),
                _SupportContactTile(
                  icon: Icons.phone_outlined,
                  title: 'الدعم الهاتفي',
                  subtitle: '+966 11 123 4567',
                  onTap: () => _showMessage(
                    context,
                    'رقم الدعم: +966 11 123 4567',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Text(
                  'المحاماة للاستشارات القانونية',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text(
                  'نظام دعم ومساعدة مخصص للمستخدم داخل تطبيق محاميك.',
                  style: TextStyle(
                    color: AppColors.foreground,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'الإصدار 1.0.0  •  2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.foreground,
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

class _SupportContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.10),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_left_rounded),
      onTap: onTap,
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String title;
  final String answer;

  const _FaqTile({
    required this.title,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            answer,
            style: TextStyle(
              color: AppColors.foreground.withValues(alpha: 0.75),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

enum _NotificationType {
  message,
  request,
  appointment,
  system,
}

class _UserNotificationItem {
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final _NotificationType type;
  final bool isUnread;

  const _UserNotificationItem({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.type,
    required this.isUnread,
  });

  _UserNotificationItem copyWith({
    String? title,
    String? body,
    String? time,
    IconData? icon,
    _NotificationType? type,
    bool? isUnread,
  }) {
    return _UserNotificationItem(
      title: title ?? this.title,
      body: body ?? this.body,
      time: time ?? this.time,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      isUnread: isUnread ?? this.isUnread,
    );
  }
}
