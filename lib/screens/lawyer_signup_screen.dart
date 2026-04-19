import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/location_links.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';

class LawyerSignUpScreen extends StatefulWidget {
  const LawyerSignUpScreen({super.key});

  @override
  State<LawyerSignUpScreen> createState() => _LawyerSignUpScreenState();
}

class _LawyerSignUpScreenState extends State<LawyerSignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController(text: '30');

  final _degreeController = TextEditingController(text: 'بكالوريوس حقوق');
  final _specializationController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _licenseDateController = TextEditingController();
  final _experienceYearsController = TextEditingController(text: '5');
  final _barAssociationController =
      TextEditingController(text: 'نقابة المحامين السعوديين');
  final _practiceAreasController = TextEditingController();
  final _bioController = TextEditingController();

  final _officeNameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController(text: 'الرياض');
  final _regionController = TextEditingController(text: 'منطقة الرياض');
  final _postalCodeController = TextEditingController(text: '12345');
  final _countryController =
      TextEditingController(text: 'المملكة العربية السعودية');

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(24.7136, 46.6753);

  String? _selectedGender;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _degreeController.dispose();
    _specializationController.dispose();
    _licenseNumberController.dispose();
    _licenseDateController.dispose();
    _experienceYearsController.dispose();
    _barAssociationController.dispose();
    _practiceAreasController.dispose();
    _bioController.dispose();
    _officeNameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _regionController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.foreground,
        ),
      ),
    );
  }

  Widget _fieldLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.foreground,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    bool obscureText = false,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          obscureText: obscureText,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Future<void> _pickLicenseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(1970),
      lastDate: DateTime(now.year + 5),
      helpText: 'اختر تاريخ الترخيص',
    );

    if (picked != null) {
      final formatted =
          '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
      _licenseDateController.text = formatted;
    }
  }

  void _onMapTap(TapPosition _, LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });
    _mapController.move(latLng, 15);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('يرجى اختيار الجنس'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    setState(() => _submitting = true);

    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    setState(() => _submitting = false);

    await _showSuccessDialog(
      title: 'تم تسجيلك بنجاح',
      message:
          'تم استلام طلب تسجيلك كمحامٍ بنجاح، وسيتم مراجعة بياناتك المهنية واعتماد الحساب وفق إجراءات المنصة.',
      buttonText: 'متابعة',
    );

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  Future<void> _showSuccessDialog({
    required String title,
    required String message,
    required String buttonText,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8EE),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFB7E4C7)),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    size: 48,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.7,
                    fontSize: 14,
                    color: AppColors.foreground.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(
                      buttonText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appBar: const AppHeader(
        title: 'تسجيل محامي',
        leadingIcon: Icons.arrow_back,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'انضم إلى منصة محاميك كمحترف قانوني',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            SectionCard(
              child: Column(
                children: [
                  _sectionTitle('المعلومات الشخصية'),
                  _buildTextField(
                    label: 'الاسم الكامل',
                    controller: _fullNameController,
                    hint: 'أدخل الاسم الكامل',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'الحقل مطلوب' : null,
                  ),
                  _buildTextField(
                    label: 'البريد الإلكتروني',
                    controller: _emailController,
                    hint: 'example@email.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'الحقل مطلوب';
                      if (!v.contains('@')) return 'بريد إلكتروني غير صحيح';
                      return null;
                    },
                  ),
                  _buildTextField(
                    label: 'رقم الجوال',
                    controller: _phoneController,
                    hint: '+966 5X XXX XXXX',
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'الحقل مطلوب' : null,
                  ),
                  _buildTextField(
                    label: 'العمر',
                    controller: _ageController,
                    hint: '30',
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'الحقل مطلوب' : null,
                  ),
                  _fieldLabel('الجنس'),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(hintText: 'اختر الجنس'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('ذكر')),
                      DropdownMenuItem(value: 'female', child: Text('أنثى')),
                    ],
                    onChanged: (value) => setState(() => _selectedGender = value),
                    validator: (v) => v == null ? 'الحقل مطلوب' : null,
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('المعلومات المهنية'),
                  _buildTextField(
                    label: 'اسم الشهادة',
                    controller: _degreeController,
                    hint: 'بكالوريوس حقوق',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'الحقل مطلوب' : null,
                  ),
                  _buildTextField(
                    label: 'التخصص',
                    controller: _specializationController,
                    hint: 'قانون جنائي، تجاري، أحوال شخصية...',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'الحقل مطلوب' : null,
                  ),
                  _buildTextField(
                    label: 'رقم الترخيص',
                    controller: _licenseNumberController,
                    hint: '123456789',
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'الحقل مطلوب' : null,
                  ),
                  _buildTextField(
                    label: 'تاريخ الترخيص',
                    controller: _licenseDateController,
                    hint: 'يوم/شهر/سنة',
                    readOnly: true,
                    onTap: _pickLicenseDate,
                    suffixIcon: const Icon(Icons.calendar_month_outlined),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'الحقل مطلوب' : null,
                  ),
                  _buildTextField(
                    label: 'سنوات الخبرة',
                    controller: _experienceYearsController,
                    hint: '5',
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'الحقل مطلوب' : null,
                  ),
                  _buildTextField(
                    label: 'نقابة المحامين',
                    controller: _barAssociationController,
                    hint: 'نقابة المحامين السعوديين',
                  ),
                  _buildTextField(
                    label: 'مجالات الممارسة',
                    controller: _practiceAreasController,
                    hint: 'القضايا الجنائية، التجارية، العقارية...',
                    maxLines: 2,
                  ),
                  _buildTextField(
                    label: 'نبذة عنك',
                    controller: _bioController,
                    hint: 'اكتب نبذة مختصرة عن خبراتك وإنجازاتك المهنية...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 8),
                  _sectionTitle('عنوان المكتب'),
                  _buildTextField(
                    label: 'اسم المكتب',
                    controller: _officeNameController,
                    hint: 'مكتب المحامي أحمد للاستشارات القانونية',
                  ),
                  _buildTextField(
                    label: 'الشارع والحي',
                    controller: _streetController,
                    hint: 'شارع الملك فهد، حي العليا',
                  ),
                  _buildTextField(
                    label: 'المدينة',
                    controller: _cityController,
                    hint: 'الرياض',
                  ),
                  _buildTextField(
                    label: 'المنطقة',
                    controller: _regionController,
                    hint: 'منطقة الرياض',
                  ),
                  _buildTextField(
                    label: 'الرمز البريدي',
                    controller: _postalCodeController,
                    hint: '12345',
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    label: 'الدولة',
                    controller: _countryController,
                    hint: 'المملكة العربية السعودية',
                  ),
                  const SizedBox(height: 6),
                  _sectionTitle('موقع المكتب على الخريطة'),
                  Container(
                    height: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedLocation,
                        initialZoom: 13,
                        onTap: _onMapTap,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.mahamik.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation,
                              width: 44,
                              height: 44,
                              child: const Icon(
                                Icons.location_on,
                                size: 40,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'اضغط على الخريطة لتحديد موقع المكتب',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}  |  Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            color: AppColors.foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                text: 'نسخ الرابط',
                                outlined: true,
                                onPressed: () {
                                  LocationLinks.copyMapsLink(
                                    context,
                                    lat: _selectedLocation.latitude,
                                    lng: _selectedLocation.longitude,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SecondaryButton(
                                text: 'Google Earth',
                                onPressed: () {
                                  LocationLinks.openEarth(
                                    context,
                                    lat: _selectedLocation.latitude,
                                    lng: _selectedLocation.longitude,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        PrimaryButton(
                          text: 'فتح Google Maps',
                          icon: const Icon(Icons.location_on_outlined),
                          onPressed: () {
                            LocationLinks.openMaps(
                              context,
                              lat: _selectedLocation.latitude,
                              lng: _selectedLocation.longitude,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('الأمان'),
                  _buildTextField(
                    label: 'كلمة المرور',
                    controller: _passwordController,
                    hint: 'أدخل كلمة المرور',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'الحقل مطلوب';
                      if (v.length < 6) return 'يجب أن تكون 6 أحرف على الأقل';
                      return null;
                    },
                  ),
                  _buildTextField(
                    label: 'تأكيد كلمة المرور',
                    controller: _confirmPasswordController,
                    hint: 'أعد إدخال كلمة المرور',
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(
                        () => _obscureConfirmPassword =
                            !_obscureConfirmPassword,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'الحقل مطلوب';
                      if (v != _passwordController.text) {
                        return 'كلمتا المرور غير متطابقتين';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    text: _submitting ? 'جاري التسجيل...' : 'التسجيل كمحامي',
                    onPressed: _submitting ? null : _submit,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'بالتسجيل، أنت توافق على الشروط والأحكام وسياسة الخصوصية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const Text(
                        'لديك حساب بالفعل؟ ',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}