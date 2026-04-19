import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final AuthService _authService = AuthService();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late final TextEditingController _nationalIdController;

  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool notifications = true;
  bool smsAlerts = true;
  bool emailAlerts = true;

  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isSavingPassword = false;
  bool _isLoggingOut = false;

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String _selectedLanguage = 'العربية';

  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();

    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _cityController = TextEditingController();
    _addressController = TextEditingController();
    _nationalIdController = TextEditingController();

    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _loadCurrentUser();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _nationalIdController.dispose();

    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();

    if (!mounted) return;

    if (user != null) {
      _currentUser = user;
      _fullNameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _cityController.text = user.city;
      _addressController.text = user.address;
      _nationalIdController.text = '';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (_currentUser == null) {
      _showError('تعذر تحميل بيانات المستخدم الحالية');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);

    final updatedUser = AppUser(
      id: _currentUser!.id,
      name: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      city: _cityController.text.trim(),
      address: _addressController.text.trim(),
      role: _currentUser!.role,
    );

    await _authService.updateUser(updatedUser);

    if (!mounted) return;

    _currentUser = updatedUser;

    setState(() => _isSavingProfile = false);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('تم تحديث بيانات الحساب بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _savePassword() async {
    FocusScope.of(context).unfocus();

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty) {
      _showError('يرجى إدخال كلمة المرور الحالية');
      return;
    }

    if (newPassword.isEmpty) {
      _showError('يرجى إدخال كلمة المرور الجديدة');
      return;
    }

    if (newPassword.length < 6) {
      _showError('كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل');
      return;
    }

    if (confirmPassword.isEmpty) {
      _showError('يرجى تأكيد كلمة المرور الجديدة');
      return;
    }

    if (newPassword != confirmPassword) {
      _showError('تأكيد كلمة المرور غير مطابق');
      return;
    }

    setState(() => _isSavingPassword = true);

    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    setState(() => _isSavingPassword = false);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'تم تحديث كلمة المرور محليًا. يمكن لاحقًا ربطها مع Backend فعلي.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);

    await _authService.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (_) => false,
    );
  }

  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.userDashboard);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
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
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(
            'البيانات الشخصية',
            'هذه البيانات مرتبطة مباشرة بحساب المستخدم الحالي',
            Icons.person_outline,
          ),
          const SizedBox(height: 18),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _fullNameController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: 'الاسم الكامل',
                    icon: Icons.badge_outlined,
                    hint: 'أدخل الاسم الكامل',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'يرجى إدخال الاسم الكامل';
                    if (text.length < 3) return 'الاسم قصير جدًا';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: 'البريد الإلكتروني',
                    icon: Icons.email_outlined,
                    hint: 'example@email.com',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                    if (!text.contains('@') || !text.contains('.')) {
                      return 'البريد الإلكتروني غير صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: 'رقم الجوال',
                    icon: Icons.phone_iphone_outlined,
                    hint: '05xxxxxxxx',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'يرجى إدخال رقم الجوال';
                    if (text.length < 9) return 'رقم الجوال غير مكتمل';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nationalIdController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: 'رقم الهوية / الإقامة',
                    icon: Icons.credit_card_outlined,
                    hint: 'اختياري حاليًا',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _cityController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: 'المدينة',
                    icon: Icons.location_city_outlined,
                    hint: 'أدخل المدينة',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'يرجى إدخال المدينة';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration(
                    label: 'العنوان',
                    icon: Icons.location_on_outlined,
                    hint: 'أدخل العنوان بالتفصيل',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'يرجى إدخال العنوان';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSavingProfile ? null : _saveProfile,
                    icon: _isSavingProfile
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _isSavingProfile ? 'جارٍ حفظ التعديلات...' : 'حفظ التعديلات',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(
            'الأمان وكلمة المرور',
            'تحديث محلي حاليًا، ويمكن لاحقًا ربطه مع الخادم',
            Icons.lock_outline,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _currentPasswordController,
            obscureText: _obscureCurrentPassword,
            decoration: _inputDecoration(
              label: 'كلمة المرور الحالية',
              icon: Icons.lock_clock_outlined,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureCurrentPassword = !_obscureCurrentPassword;
                  });
                },
                icon: Icon(
                  _obscureCurrentPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            decoration: _inputDecoration(
              label: 'كلمة المرور الجديدة',
              icon: Icons.lock_open_outlined,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
                icon: Icon(
                  _obscureNewPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: _inputDecoration(
              label: 'تأكيد كلمة المرور الجديدة',
              icon: Icons.verified_user_outlined,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSavingPassword ? null : _savePassword,
              icon: _isSavingPassword
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.password_outlined),
              label: Text(
                _isSavingPassword ? 'جارٍ تحديث كلمة المرور...' : 'تحديث كلمة المرور',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(
            'الإشعارات والتنبيهات',
            'إعدادات واجهة محلية ويمكن ربطها لاحقًا بالخادم',
            Icons.notifications_active_outlined,
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: notifications,
            onChanged: (value) => setState(() => notifications = value),
            title: const Text('إشعارات التطبيق'),
            subtitle: const Text('استقبال إشعارات داخل التطبيق'),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: smsAlerts,
            onChanged: (value) => setState(() => smsAlerts = value),
            title: const Text('إشعارات الرسائل النصية'),
            subtitle: const Text('استقبال التنبيهات عبر الجوال'),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: emailAlerts,
            onChanged: (value) => setState(() => emailAlerts = value),
            title: const Text('إشعارات البريد الإلكتروني'),
            subtitle: const Text('استقبال الإشعارات عبر البريد الإلكتروني'),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(
            'التفضيلات',
            'إعدادات الواجهة واللغة',
            Icons.tune_outlined,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedLanguage,
            decoration: _inputDecoration(
              label: 'اللغة',
              icon: Icons.language_outlined,
            ),
            items: const [
              DropdownMenuItem(
                value: 'العربية',
                child: Text('العربية'),
              ),
              DropdownMenuItem(
                value: 'English',
                child: Text('English'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedLanguage = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActionsSection() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(
            'إجراءات الحساب',
            'إدارة الجلسة والحساب الحالي',
            Icons.manage_accounts_outlined,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              final user = _currentUser;
              if (user == null) return;

              final info = '''
الاسم: ${user.name}
البريد: ${user.email}
الجوال: ${user.phone}
المدينة: ${user.city}
العنوان: ${user.address}
الدور: ${user.role}
''';

              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('بيانات الحساب الحالية'),
                  content: Text(info.trim()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إغلاق'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.badge_outlined),
            label: const Text('عرض بيانات الحساب'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isLoggingOut ? null : _logout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'تسجيل الخروج',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(color: Colors.red.shade300),
            ),
          ),
        ],
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
          'الإعدادات',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileSection(),
                  const SizedBox(height: 14),
                  _buildPasswordSection(),
                  const SizedBox(height: 14),
                  _buildNotificationsSection(),
                  const SizedBox(height: 14),
                  _buildPreferencesSection(),
                  const SizedBox(height: 14),
                  _buildAccountActionsSection(),
                ],
              ),
            ),
    );
  }
}