import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';
import '../services/session_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

enum _AdminTab { overview, lawyers, users, cases }

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _activeTab = 0;
  _AdminTab activeTab = _AdminTab.overview;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _logout() async {
    await SessionService().clear();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined),
            SizedBox(width: 8),
            Text('لوحة التحكم'),
          ],
        ),
        // 👈 حذفنا الـ Builder اللي كان هنا لأنه مكرر
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      drawer: _AdminDrawer(
        activeTab: activeTab,
        onChangeTab: (tab) {
          setState(() => activeTab = tab);
          Navigator.pop(context);
        },
        onLogout: _logout,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _AdminTabButton(
                    label: 'نظرة عامة',
                    active: activeTab == _AdminTab.overview,
                    onTap: () =>
                        setState(() => activeTab = _AdminTab.overview)),
                const SizedBox(width: 8),
                _AdminTabButton(
                    label: 'المحامون',
                    active: activeTab == _AdminTab.lawyers,
                    onTap: () => setState(() => activeTab = _AdminTab.lawyers)),
                const SizedBox(width: 8),
                _AdminTabButton(
                    label: 'المستخدمون',
                    active: activeTab == _AdminTab.users,
                    onTap: () => setState(() => activeTab = _AdminTab.users)),
                const SizedBox(width: 8),
                _AdminTabButton(
                    label: 'القضايا',
                    active: activeTab == _AdminTab.cases,
                    onTap: () => setState(() => activeTab = _AdminTab.cases)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // عرض المحتوى بناءً على التبويب المختار مع التحديث اللحظي
          if (activeTab == _AdminTab.overview) _buildOverview(),
          if (activeTab == _AdminTab.lawyers)
            _buildFirestoreTab(
                'Lawyers', _buildLawyerCard), // تغيير lawyers إلى Lawyers
          if (activeTab == _AdminTab.users)
            _buildFirestoreTab(
                'Users', _buildUserCard), // تغيير users إلى Users
          if (activeTab == _AdminTab.cases)
            _buildFirestoreTab(
                'Cases', _buildCaseCard), // تغيير cases إلى Cases
        ],
      ),
    );
  }

  // --- تبويب نظرة عامة (جلب الإحصائيات الحقيقية) ---
  // 1. حل مشكلة القوائم الممسوحة (إضافة التمرير الأفقي للتبويبات)
  Widget _buildTabSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _tabButton('نظرة عامة', 0),
          _tabButton('المحامون', 1),
          _tabButton('المستخدمون', 2),
          _tabButton('القضايا', 3),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data ??
            {'lawyers': 0, 'users': 0, 'cases': 0, 'pending': 0};

        final overviewStats = [
          _OverviewStat(
              label: 'المحامون',
              value: '${stats['lawyers']}',
              color: const Color(0xFF3B82F6),
              icon: Icons.shield_outlined),
          _OverviewStat(
              label: 'المستخدمون',
              value: '${stats['users']}',
              color: const Color(0xFF10B981),
              icon: Icons.groups_outlined),
          _OverviewStat(
              label: 'القضايا النشطة',
              value: '${stats['cases']}',
              color: const Color(0xFFF59E0B),
              icon: Icons.description_outlined),
          _OverviewStat(
              label: 'طلبات معلقة',
              value: '${stats['pending']}',
              color: const Color(0xFFEF4444),
              icon: Icons.hourglass_empty),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.builder(
              itemCount: overviewStats.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.04,
              ),
              itemBuilder: (context, index) {
                final stat = overviewStats[index];
                return SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: stat.color,
                            borderRadius: BorderRadius.circular(14)),
                        child: Icon(stat.icon, color: Colors.white),
                      ),
                      const Spacer(),
                      Text(stat.value,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(stat.label,
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.foreground
                                  .withValues(alpha: 0.62))),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('ملخص سريع من قاعدة البيانات',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            _summaryItem(
                'إجمالي المسجلين: ${stats['lawyers']} محامي و ${stats['users']} مستخدم.'),
            if (stats['pending'] > 0)
              _summaryItem(
                  'تنبيه: يوجد ${stats['pending']} طلبات انضمام تتطلب مراجعتك.'),
            _summaryItem('تتم الآن إدارة ${stats['cases']} قضية نشطة بنجاح.'),
          ],
        );
      },
    );
  }

  // 👈 هذه الدالة هي اللي كانت ناقصة ومسببة الإيرور
  Widget _tabButton(String title, int index) {
    final bool isSelected = _activeTab ==
        index; // تأكدي إن اسم متغير التبويب النشط عندك هو _activeTab
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: InkWell(
        onTap: () {
          setState(() {
            _activeTab = index; // تحديث التبويب عند الضغط
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E3A5F) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1E3A5F)
                  : const Color(0xFFE0E0E0),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ),
    );
  }

  // 2. تحديث الـ StreamBuilder ليدعم كل التبويبات حسب النوع
  Widget _buildFirestoreTab(
      String tabType, Widget Function(DocumentSnapshot) itemBuilder) {
    Query query;
    // تحديد الاستعلام بناءً على التبويب المختار
    if (tabType == 'Lawyers') {
      // تأكدي من مطابقة المسمى الممرر في السطر 67
      query = FirebaseFirestore.instance.collection('Users').where('role',
          isEqualTo: 'lawyer'); // تأكدي هل هي lawyer أم Lawyer في الفايربيس
    } else if (tabType == 'Users') {
      query = FirebaseFirestore.instance
          .collection('Users')
          .where('role', isEqualTo: 'user');
    } else {
      query = FirebaseFirestore.instance.collection('Cases'); // جلب القضايا
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('حدث خطأ في تحميل البيانات');
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        if (snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('لا توجد بيانات حالياً'),
          ));
        }

        return Column(
          children: snapshot.data!.docs.map((doc) => itemBuilder(doc)).toList(),
        );
      },
    );
  }

  Widget _buildLawyerCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _AdminEntityCard(
        title: data['name'] ?? 'بدون اسم', // سيجلب "نورة العتيبي"
        subtitle: data['email'] ?? '',
        badgeText: data['status'] ?? 'نشط',
        badgeBackground: const Color(0xFFDCFCE7),
        badgeForeground: const Color(0xFF15803D),
        details: [
          'التخصص: ${data['lawyerSpecialty'] ?? 'غير محدد'}',
          'الخبرة: ${data['experience'] ?? '0 سنوات'}', // استخدمنا experience كما في الفايربيس[cite: 1]
          'السعر: ${data['price'] ?? '0'}',
        ],
        onEdit: () {},
        onDelete: () => _deleteDoc('Users', doc.id),
      ),
    );
  }

  Widget _buildUserCard(DocumentSnapshot doc) {
    // جلب البيانات من الدوكومنت (المستخدم) آلياً
    final data = doc.data() as Map<String, dynamic>;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _AdminEntityCard(
        // الربط مع حقل الاسم
        title: data['name'] ?? 'مستخدم جديد',
        // الربط مع البريد الإلكتروني
        subtitle: data['email'] ?? '',
        badgeText: 'عميل',
        badgeBackground: const Color(0xFFDCFCE7),
        badgeForeground: const Color(0xFF15803D),
        details: [
          // جلب المدينة وتاريخ التسجيل من الفايربيس
          'المدينة: ${data['city'] ?? 'غير محدد'}',
          'تاريخ التسجيل: ${data['join_date'] ?? 'غير متوفر حالياً'}',
          // يمكنك إضافة رقم الجوال إذا كان موجوداً في الفايربيس
          'رقم التواصل: ${data['phone'] ?? 'غير مسجل'}',
        ],
        onEdit: () {
          // كود التعديل هنا
        },
        onDelete: () =>
            _deleteDoc('Users', doc.id), // التأكد من المسح من مجموعة Users
      ),
    );
  }

  // 4. تعديل بطاقة القضايا لتظهر البيانات فعلياً
  Widget _buildCaseCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _AdminEntityCard(
        // 1. استخدمنا caseType بدلاً من title بناءً على صورتك
        title: data['caseType'] ?? 'قضية بدون عنوان',
        // 2. استخدمنا lawyerName الموجود في صورتك
        subtitle: 'المحامي: ${data['lawyerName'] ?? 'لم يحدد'}',
        badgeText: data['status'] ?? 'نشطة',
        badgeBackground: const Color(0xFFDBEAFE),
        badgeForeground: const Color(0xFF1E40AF),
        details: [
          // 3. وصف المشكلة
          'الوصف: ${data['description'] ?? 'لا يوجد وصف'}',
          // 4. التاريخ المفضل الموجود في صورتك
          'التاريخ المفضل: ${data['preferredDate'] ?? 'غير محدد'}'
        ],
        onEdit: () {},
        onDelete: () => _deleteDoc('Cases', doc.id),
      ),
    );
  }

  Future<Map<String, dynamic>> _getStats() async {
    try {
      // 1. جلب المحامين فقط
      final lawyersSnapshot = await _firestore
          .collection('Users')
          .where('role', isEqualTo: 'lawyer')
          .get();

      // 2. جلب المستخدمين (الطلاب) فقط
      final usersSnapshot = await _firestore
          .collection('Users')
          .where('role', isEqualTo: 'user')
          .get();

      // 3. جلب القضايا
      final casesSnapshot = await _firestore.collection('Cases').get();

      // 4. جلب الطلبات المعلقة
      final pendingSnapshot = await _firestore
          .collection('Users')
          .where('role', isEqualTo: 'lawyer')
          .where('status', isEqualTo: 'معلق')
          .get();

      return {
        'lawyers': lawyersSnapshot
            .docs.length, // تأكدي من تطابق هذا الاسم مع السطر 311
        'users': usersSnapshot.docs.length,
        'cases': casesSnapshot.docs.length,
        'pending': pendingSnapshot.docs.length,
      };
    } catch (e) {
      debugPrint("خطأ في جلب البيانات: $e");
      return {'lawyers': 0, 'users': 0, 'cases': 0, 'pending': 0};
    }
  }

  Future<void> _deleteDoc(String collection, String id) async {
    final confirmed =
        await _confirmDelete('هل أنت متأكد من حذف هذا السجل نهائياً؟');
    if (confirmed) {
      await _firestore.collection(collection).doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم الحذف من قاعدة البيانات')));
      }
    }
  }

  (Color, Color) _caseBadge(String status) {
    if (status == 'مكتملة')
      return (const Color(0xFFDCFCE7), const Color(0xFF15803D));
    return (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8));
  }

  Future<bool> _confirmDelete(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _summaryItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}
// (باقي الودجات Drawer و TabButton تبقى كما هي في ملفك الأصلي)
// --- الودجات المخصصة للوحة التحكم ---

class _AdminDrawer extends StatelessWidget {
  final _AdminTab activeTab;
  final ValueChanged<_AdminTab> onChangeTab;
  final Future<void> Function() onLogout;
  const _AdminDrawer({
    required this.activeTab,
    required this.onChangeTab,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.card,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('مسؤول النظام',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 20),
              const Divider(),
              _drawerTile(
                  Icons.dashboard_outlined, 'نظرة عامة', _AdminTab.overview),
              _drawerTile(Icons.shield_outlined, 'المحامون', _AdminTab.lawyers),
              _drawerTile(Icons.groups_outlined, 'المستخدمون',
                  _AdminTab.users), // الخيار الناقص
              _drawerTile(Icons.description_outlined, 'القضايا',
                  _AdminTab.cases), // الخيار الناقص
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('تسجيل الخروج',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, _AdminTab tab) {
    return ListTile(
      leading:
          Icon(icon, color: activeTab == tab ? AppColors.primary : Colors.grey),
      title: Text(title,
          style: TextStyle(
              color:
                  activeTab == tab ? AppColors.primary : AppColors.foreground,
              fontWeight:
                  activeTab == tab ? FontWeight.bold : FontWeight.normal)),
      selected: activeTab == tab,
      onTap: () => onChangeTab(tab),
    );
  }
}

class _AdminTabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _AdminTabButton(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: active ? AppColors.primary : Colors.grey[200],
      labelStyle: TextStyle(color: active ? Colors.white : Colors.black),
    );
  }
}

class _OverviewStat {
  final String label, value;
  final Color color;
  final IconData icon;
  const _OverviewStat(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});
}

class _AdminEntityCard extends StatelessWidget {
  final String title, subtitle, badgeText;
  final Color badgeBackground, badgeForeground;
  final List<String> details;
  final VoidCallback onEdit, onDelete;

  const _AdminEntityCard({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeBackground,
    required this.badgeForeground,
    required this.details,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: badgeBackground,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(badgeText,
                      style: TextStyle(color: badgeForeground, fontSize: 12)),
                ),
              ],
            ),
            Text(subtitle, style: const TextStyle(color: Colors.grey)),
            const Divider(),
            ...details.map((d) => Text(d)),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete),
              ],
            )
          ],
        ),
      ),
    );
  }
}
