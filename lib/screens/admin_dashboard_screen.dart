import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';
import '../data/mock_data.dart';
import '../models/legal_case.dart';
import '../models/lawyer.dart';
import '../services/session_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

enum _AdminTab { overview, lawyers, users, cases }

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  _AdminTab activeTab = _AdminTab.overview;
  late List<_AdminLawyer> lawyers;
  late List<_AdminUser> users;
  late List<_AdminCase> cases;

  @override
  void initState() {
    super.initState();
    lawyers = [
      const _AdminLawyer(id: '1', name: 'د. أحمد محمد', email: 'ahmed@test.com', specialty: 'القانون التجاري', status: 'نشط', cases: 15),
      const _AdminLawyer(id: '2', name: 'د. سارة العلي', email: 'sara@test.com', specialty: 'قانون الأسرة', status: 'نشط', cases: 12),
      const _AdminLawyer(id: '3', name: 'د. خالد السعيد', email: 'khaled@test.com', specialty: 'القانون الجنائي', status: 'معلق', cases: 20),
    ];
    users = [
      const _AdminUser(id: '1', name: 'محمد أحمد', email: 'user1@test.com', joinDate: '2026-01-15', cases: 3, status: 'نشط'),
      const _AdminUser(id: '2', name: 'فاطمة سعيد', email: 'user2@test.com', joinDate: '2026-02-20', cases: 5, status: 'نشط'),
      const _AdminUser(id: '3', name: 'عبدالله خالد', email: 'user3@test.com', joinDate: '2026-03-10', cases: 2, status: 'نشط'),
    ];
    cases = [
      const _AdminCase(id: '1', title: 'قضية عقارية', lawyer: 'د. أحمد محمد', client: 'محمد أحمد', status: 'نشطة', date: '2026-04-01'),
      const _AdminCase(id: '2', title: 'قضية تجارية', lawyer: 'د. سارة العلي', client: 'فاطمة سعيد', status: 'قيد المراجعة', date: '2026-03-28'),
      const _AdminCase(id: '3', title: 'استشارة قانونية', lawyer: 'د. خالد السعيد', client: 'عبدالله خالد', status: 'مكتملة', date: '2026-03-25'),
    ];
  }

  Future<void> _logout() async {
    await SessionService().clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
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
        actions: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu),
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
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
                _AdminTabButton(label: 'نظرة عامة', active: activeTab == _AdminTab.overview, onTap: () => setState(() => activeTab = _AdminTab.overview)),
                const SizedBox(width: 8),
                _AdminTabButton(label: 'المحامون', active: activeTab == _AdminTab.lawyers, onTap: () => setState(() => activeTab = _AdminTab.lawyers)),
                const SizedBox(width: 8),
                _AdminTabButton(label: 'المستخدمون', active: activeTab == _AdminTab.users, onTap: () => setState(() => activeTab = _AdminTab.users)),
                const SizedBox(width: 8),
                _AdminTabButton(label: 'القضايا', active: activeTab == _AdminTab.cases, onTap: () => setState(() => activeTab = _AdminTab.cases)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (activeTab == _AdminTab.overview) _buildOverview(),
          if (activeTab == _AdminTab.lawyers) _buildLawyersTab(),
          if (activeTab == _AdminTab.users) _buildUsersTab(),
          if (activeTab == _AdminTab.cases) _buildCasesTab(),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    final overviewStats = const [
      _OverviewStat(label: 'المحامون', value: '45', color: Color(0xFF3B82F6), icon: Icons.shield_outlined),
      _OverviewStat(label: 'المستخدمون', value: '320', color: Color(0xFF10B981), icon: Icons.groups_outlined),
      _OverviewStat(label: 'القضايا النشطة', value: '78', color: Color(0xFFF59E0B), icon: Icons.description_outlined),
      _OverviewStat(label: 'معدل النمو', value: '+12%', color: Color(0xFF8B5CF6), icon: Icons.trending_up),
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
                    decoration: BoxDecoration(color: stat.color, borderRadius: BorderRadius.circular(14)),
                    child: Icon(stat.icon, color: Colors.white),
                  ),
                  const Spacer(),
                  Text(stat.value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(stat.label, style: TextStyle(fontSize: 12, color: AppColors.foreground.withValues(alpha: 0.62))),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text('ملخص سريع', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 12),
        ...[
          'عدد المحامين النشطين أعلى من الشهر الماضي.',
          'هناك 5 طلبات تحتاج مراجعة إدارية.',
          'آخر قضية مكتملة كانت بتاريخ 2026-03-25.',
        ].map(
          (text) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SectionCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLawyersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: lawyers
          .map(
            (lawyer) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _AdminEntityCard(
                title: lawyer.name,
                subtitle: lawyer.email,
                badgeText: lawyer.status,
                badgeBackground: lawyer.status == 'نشط' ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                badgeForeground: lawyer.status == 'نشط' ? const Color(0xFF15803D) : const Color(0xFFB45309),
                details: [
                  'التخصص: ${lawyer.specialty}',
                  'عدد القضايا: ${lawyer.cases}',
                ],
                onEdit: () => _editLawyer(lawyer),
                onDelete: () => _deleteLawyer(lawyer),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: users
          .map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _AdminEntityCard(
                title: user.name,
                subtitle: user.email,
                badgeText: user.status,
                badgeBackground: const Color(0xFFDCFCE7),
                badgeForeground: const Color(0xFF15803D),
                details: [
                  'تاريخ الانضمام: ${user.joinDate}',
                  'عدد القضايا: ${user.cases}',
                ],
                onEdit: () => _editUser(user),
                onDelete: () => _deleteUser(user),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCasesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: cases
          .map(
            (caseItem) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _AdminEntityCard(
                title: caseItem.title,
                subtitle: caseItem.lawyer,
                badgeText: caseItem.status,
                badgeBackground: _caseBadge(caseItem.status).$1,
                badgeForeground: _caseBadge(caseItem.status).$2,
                details: [
                  'العميل: ${caseItem.client}',
                  'التاريخ: ${caseItem.date}',
                ],
                onEdit: () => _editCase(caseItem),
                onDelete: () => _deleteCase(caseItem),
              ),
            ),
          )
          .toList(),
    );
  }

  (Color, Color) _caseBadge(String status) {
    switch (status) {
      case 'مكتملة':
        return (const Color(0xFFDCFCE7), const Color(0xFF15803D));
      case 'نشطة':
        return (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8));
      default:
        return (const Color(0xFFFEF3C7), const Color(0xFFB45309));
    }
  }

  Future<void> _editLawyer(_AdminLawyer lawyer) async {
    final updated = await showDialog<_AdminLawyer>(
      context: context,
      builder: (_) => _LawyerEditorDialog(initial: lawyer),
    );
    if (updated != null) {
      setState(() {
        lawyers = lawyers.map((item) => item.id == updated.id ? updated : item).toList();
      });
      _showSnackBar('تم تحديث بيانات المحامي بنجاح');
    }
  }

  Future<void> _editUser(_AdminUser user) async {
    final updated = await showDialog<_AdminUser>(
      context: context,
      builder: (_) => _UserEditorDialog(initial: user),
    );
    if (updated != null) {
      setState(() {
        users = users.map((item) => item.id == updated.id ? updated : item).toList();
      });
      _showSnackBar('تم تحديث بيانات المستخدم بنجاح');
    }
  }

  Future<void> _editCase(_AdminCase caseItem) async {
    final updated = await showDialog<_AdminCase>(
      context: context,
      builder: (_) => _CaseEditorDialog(initial: caseItem),
    );
    if (updated != null) {
      setState(() {
        cases = cases.map((item) => item.id == updated.id ? updated : item).toList();
      });
      _showSnackBar('تم تحديث بيانات القضية بنجاح');
    }
  }

  Future<void> _deleteLawyer(_AdminLawyer lawyer) async {
    final approved = await _confirmDelete('هل أنت متأكد من حذف هذا المحامي؟ سيتم حذف جميع البيانات المرتبطة به.');
    if (approved) {
      setState(() => lawyers.removeWhere((item) => item.id == lawyer.id));
      _showSnackBar('تم حذف المحامي بنجاح');
    }
  }

  Future<void> _deleteUser(_AdminUser user) async {
    final approved = await _confirmDelete('هل أنت متأكد من حذف هذا المستخدم؟ سيتم حذف جميع البيانات المرتبطة به.');
    if (approved) {
      setState(() => users.removeWhere((item) => item.id == user.id));
      _showSnackBar('تم حذف المستخدم بنجاح');
    }
  }

  Future<void> _deleteCase(_AdminCase caseItem) async {
    final approved = await _confirmDelete('هل أنت متأكد من حذف هذه القضية؟');
    if (approved) {
      setState(() => cases.removeWhere((item) => item.id == caseItem.id));
      _showSnackBar('تم حذف القضية بنجاح');
    }
  }

  Future<bool> _confirmDelete(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('تأكيد الحذف'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: AppColors.destructive))),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AdminDrawer extends StatelessWidget {
  final _AdminTab activeTab;
  final ValueChanged<_AdminTab> onChangeTab;
  final Future<void> Function() onLogout;

  const _AdminDrawer({required this.activeTab, required this.onChangeTab, required this.onLogout});

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
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.shield_outlined, color: AppColors.background),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('مسؤول النظام', style: TextStyle(fontWeight: FontWeight.w800)),
                      Text('admin@test.com', style: TextStyle(fontSize: 12, color: AppColors.foreground.withValues(alpha: 0.55))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _DrawerEntry(icon: Icons.dashboard_outlined, title: 'نظرة عامة', active: activeTab == _AdminTab.overview, onTap: () => onChangeTab(_AdminTab.overview)),
              _DrawerEntry(icon: Icons.shield_outlined, title: 'إدارة المحامين', active: activeTab == _AdminTab.lawyers, onTap: () => onChangeTab(_AdminTab.lawyers)),
              _DrawerEntry(icon: Icons.groups_outlined, title: 'إدارة المستخدمين', active: activeTab == _AdminTab.users, onTap: () => onChangeTab(_AdminTab.users)),
              _DrawerEntry(icon: Icons.description_outlined, title: 'إدارة القضايا', active: activeTab == _AdminTab.cases, onTap: () => onChangeTab(_AdminTab.cases)),
              const Spacer(),
              _DrawerEntry(
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

class _DrawerEntry extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool active;
  final bool destructive;
  final VoidCallback onTap;

  const _DrawerEntry({required this.icon, required this.title, required this.onTap, this.active = false, this.destructive = false});

  @override
  Widget build(BuildContext context) {
    final foreground = destructive ? AppColors.destructive : (active ? AppColors.background : AppColors.foreground);
    final background = destructive
        ? Colors.transparent
        : active
            ? AppColors.primary
            : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: foreground, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _AdminTabButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(color: active ? AppColors.background : AppColors.foreground, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}

class _AdminEntityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeBackground;
  final Color badgeForeground;
  final List<String> details;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.person, color: AppColors.background)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.foreground.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: badgeBackground, borderRadius: BorderRadius.circular(12)),
                child: Text(badgeText, style: TextStyle(color: badgeForeground, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...details.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(detail, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('تعديل'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('حذف'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LawyerEditorDialog extends StatefulWidget {
  final _AdminLawyer initial;

  const _LawyerEditorDialog({required this.initial});

  @override
  State<_LawyerEditorDialog> createState() => _LawyerEditorDialogState();
}

class _LawyerEditorDialogState extends State<_LawyerEditorDialog> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController specialtyController;
  late TextEditingController statusController;
  late TextEditingController casesController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initial.name);
    emailController = TextEditingController(text: widget.initial.email);
    specialtyController = TextEditingController(text: widget.initial.specialty);
    statusController = TextEditingController(text: widget.initial.status);
    casesController = TextEditingController(text: '${widget.initial.cases}');
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    specialtyController.dispose();
    statusController.dispose();
    casesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditorDialogShell(
      title: 'تعديل بيانات المحامي',
      fields: [
        _DialogField(label: 'الاسم', controller: nameController),
        _DialogField(label: 'البريد الإلكتروني', controller: emailController),
        _DialogField(label: 'التخصص', controller: specialtyController),
        _DialogField(label: 'الحالة', controller: statusController),
        _DialogField(label: 'عدد القضايا', controller: casesController, keyboardType: TextInputType.number),
      ],
      onSave: () {
        Navigator.pop(
          context,
          _AdminLawyer(
            id: widget.initial.id,
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            specialty: specialtyController.text.trim(),
            status: statusController.text.trim(),
            cases: int.tryParse(casesController.text.trim()) ?? widget.initial.cases,
          ),
        );
      },
    );
  }
}

class _UserEditorDialog extends StatefulWidget {
  final _AdminUser initial;

  const _UserEditorDialog({required this.initial});

  @override
  State<_UserEditorDialog> createState() => _UserEditorDialogState();
}

class _UserEditorDialogState extends State<_UserEditorDialog> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController joinDateController;
  late TextEditingController casesController;
  late TextEditingController statusController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initial.name);
    emailController = TextEditingController(text: widget.initial.email);
    joinDateController = TextEditingController(text: widget.initial.joinDate);
    casesController = TextEditingController(text: '${widget.initial.cases}');
    statusController = TextEditingController(text: widget.initial.status);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    joinDateController.dispose();
    casesController.dispose();
    statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditorDialogShell(
      title: 'تعديل بيانات المستخدم',
      fields: [
        _DialogField(label: 'الاسم', controller: nameController),
        _DialogField(label: 'البريد الإلكتروني', controller: emailController),
        _DialogField(label: 'تاريخ الانضمام', controller: joinDateController),
        _DialogField(label: 'عدد القضايا', controller: casesController, keyboardType: TextInputType.number),
        _DialogField(label: 'الحالة', controller: statusController),
      ],
      onSave: () {
        Navigator.pop(
          context,
          _AdminUser(
            id: widget.initial.id,
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            joinDate: joinDateController.text.trim(),
            cases: int.tryParse(casesController.text.trim()) ?? widget.initial.cases,
            status: statusController.text.trim(),
          ),
        );
      },
    );
  }
}

class _CaseEditorDialog extends StatefulWidget {
  final _AdminCase initial;

  const _CaseEditorDialog({required this.initial});

  @override
  State<_CaseEditorDialog> createState() => _CaseEditorDialogState();
}

class _CaseEditorDialogState extends State<_CaseEditorDialog> {
  late TextEditingController titleController;
  late TextEditingController lawyerController;
  late TextEditingController clientController;
  late TextEditingController statusController;
  late TextEditingController dateController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.initial.title);
    lawyerController = TextEditingController(text: widget.initial.lawyer);
    clientController = TextEditingController(text: widget.initial.client);
    statusController = TextEditingController(text: widget.initial.status);
    dateController = TextEditingController(text: widget.initial.date);
  }

  @override
  void dispose() {
    titleController.dispose();
    lawyerController.dispose();
    clientController.dispose();
    statusController.dispose();
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditorDialogShell(
      title: 'تعديل بيانات القضية',
      fields: [
        _DialogField(label: 'عنوان القضية', controller: titleController),
        _DialogField(label: 'المحامي', controller: lawyerController),
        _DialogField(label: 'العميل', controller: clientController),
        _DialogField(label: 'الحالة', controller: statusController),
        _DialogField(label: 'التاريخ', controller: dateController),
      ],
      onSave: () {
        Navigator.pop(
          context,
          _AdminCase(
            id: widget.initial.id,
            title: titleController.text.trim(),
            lawyer: lawyerController.text.trim(),
            client: clientController.text.trim(),
            status: statusController.text.trim(),
            date: dateController.text.trim(),
          ),
        );
      },
    );
  }
}

class _EditorDialogShell extends StatelessWidget {
  final String title;
  final List<_DialogField> fields;
  final VoidCallback onSave;

  const _EditorDialogShell({required this.title, required this.fields, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: fields
                .map(
                  (field) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: field.controller,
                      keyboardType: field.keyboardType,
                      decoration: InputDecoration(labelText: field.label),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.background),
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

class _DialogField {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _DialogField({required this.label, required this.controller, this.keyboardType});
}

class _OverviewStat {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _OverviewStat({required this.label, required this.value, required this.color, required this.icon});
}

class _AdminLawyer {
  final String id;
  final String name;
  final String email;
  final String specialty;
  final String status;
  final int cases;

  const _AdminLawyer({required this.id, required this.name, required this.email, required this.specialty, required this.status, required this.cases});
}

class _AdminUser {
  final String id;
  final String name;
  final String email;
  final String joinDate;
  final int cases;
  final String status;

  const _AdminUser({required this.id, required this.name, required this.email, required this.joinDate, required this.cases, required this.status});
}

class _AdminCase {
  final String id;
  final String title;
  final String lawyer;
  final String client;
  final String status;
  final String date;

  const _AdminCase({required this.id, required this.title, required this.lawyer, required this.client, required this.status, required this.date});
}
